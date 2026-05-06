import os
import re
import struct
import base64
import tempfile
import unicodedata
import httpx
import json as _json
from enum import Enum
from dataclasses import dataclass, field
from typing import List, Optional
from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from difflib import SequenceMatcher

# pykakasi: chuyển Kanji → Hiragana để so sánh với Google STT output
try:
    import pykakasi as _pykakasi
    _kks = _pykakasi.kakasi()
    def _kanji_to_hira(text: str) -> str:
        """Chuyển toàn bộ chuỗi Kanji/Katakana → Hiragana thuần."""
        result = _kks.convert(text)
        return "".join(item["hira"] or item["orig"] for item in result)
except Exception:
    def _kanji_to_hira(text: str) -> str:  # type: ignore
        return text

router = APIRouter(prefix="/evaluate", tags=["AI Speech Evaluation"])

# =====================================================================
# Ưu tiên 1: Azure (thêm key để dùng đánh giá Pronunciation chính xác nhất)
# =====================================================================
AZURE_SPEECH_KEY    = os.getenv("AZURE_SPEECH_KEY", "")
AZURE_SPEECH_REGION = os.getenv("AZURE_SPEECH_REGION", "eastasia")

# =====================================================================
# Ưu tiên 2: Google Cloud Speech key (tùy chọn)
# =====================================================================
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "")

# =====================================================================
# Gemini AI key — dùng để sinh gợi ý cải thiện phát âm thông minh
# Dùng cùng key Google AI Studio hoặc set GEMINI_API_KEY riêng
# =====================================================================
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "") or GOOGLE_API_KEY

# Trợ từ & từ pitch-accent quan trọng trong tiếng Nhật
_JP_PITCH_PARTICLES = {"は", "が", "を", "に", "で", "と", "も", "の", "へ", "から", "まで", "より", "ね", "よ", "か"}

# ==============================================================================
# SECTION 0: RecommendationEngine — Hệ thống gợi ý học tập AI
# ==============================================================================

class ErrorType(str, Enum):
    PRONUNCIATION = "pronunciation"   # Sai âm cụ thể — nghe nhầm mora
    PROSODY       = "prosody"         # Ngữ điệu/pitch-accent sai
    RHYTHM        = "rhythm"          # Nhịp ngắt sai chỗ
    PITCH_ACCENT  = "pitch_accent"    # Trường âm tiếng Nhật (っ, ん, ー, ざ行)

class ActionType(str, Enum):
    SHOW_HAN_VIET_MODE  = "show_han_viet_mode"   # Hiện Hán-Việt để làm điểm tựa
    OPEN_VOCABULARY     = "open_vocabulary"       # Mở kho từ vựng ôn từ đó
    ACTIVATE_SLOW_MODE  = "activate_slow_mode"    # Kích hoạt chế độ Slow-mo 0.75x
    SHOW_PITCH_GUIDE    = "show_pitch_guide"      # Hiện hướng dẫn Pitch-accent
    CELEBRATE           = "celebrate"             # Không lỗi — động viên
    RETRY               = "retry"                 # Điểm quá thấp — cần thử lại

@dataclass
class ActionPlan:
    message: str
    action: ActionType
    target_word: Optional[str] = None
    severity: int = 1  # 1=nhẹ, 2=trung bình, 3=nghiêm trọng

    def to_dict(self) -> dict:
        return {
            "message": self.message,
            "action": self.action.value,
            "target_word": self.target_word,
            "severity": self.severity,
        }


class RecommendationEngine:
    """
    Phân tích kết quả shadowing và đưa ra Action Plan cá nhân hóa.
    Input : accuracy, fluency, prosody, rhythm, mispronounced_words, error_types
    Output: ActionPlan với message tiếng Việt + action type cho Flutter xử lý
    """

    # Danh sách âm Hán-Việt phổ biến người Việt hay nhầm trong tiếng Nhật
    # (danh sách mở rộng dần theo thực tế lỗi)
    _SINO_JAPANESE_PATTERNS = [
        "学", "語", "音", "字", "校", "会", "社", "国", "人", "文",
        "生", "先", "大", "小", "中", "高", "新", "本", "日", "年",
        "力", "気", "電", "水", "火", "金", "木", "土", "花", "山",
        "農", "業", "市", "府", "県", "区", "町", "村", "道", "京",
    ]

    # Pattern âm ngắt (っ), âm mũi (ん), âm dài (ー) — đặc trưng tiếng Nhật
    _PITCH_ACCENT_CHARS = ["っ", "ッ", "ん", "ン", "ー", "〜"]

    def _has_sino_japanese_error(self, words: List[str]) -> bool:
        """Kiểm tra từ sai có chứa Kanji Hán-Việt phổ biến không."""
        for w in words:
            for kanji in self._SINO_JAPANESE_PATTERNS:
                if kanji in w:
                    return True
        return False

    def _has_pitch_accent_error(self, words: List[str], error_types: dict) -> bool:
        """Kiểm tra có lỗi trường âm/xúc âm đặc trưng không."""
        if error_types.get("pitch_accent"):
            return True
        for w in words:
            for ch in self._PITCH_ACCENT_CHARS:
                if ch in w:
                    return True
        return False

    def analyze(
        self,
        accuracy: int,
        fluency: int,
        prosody: int,
        rhythm: int,
        mispronounced_words: List[str],
        error_types: dict,
        sentence_length: int = 0,
    ) -> ActionPlan:
        """
        Trả về ActionPlan phù hợp nhất dựa trên kết quả phân tích.
        Thứ tự ưu tiên: điểm quá thấp → lỗi Hán-Việt → câu dài khó → pitch-accent → prosody → celebrate
        """
        # ── Case 1: Điểm quá thấp → ép thử lại với hỗ trợ ──────────────────
        if accuracy < 50:
            return ActionPlan(
                message=(
                    "Đừng nản lòng! Điểm phát âm của bạn chưa đạt ngưỡng Pass. "
                    "Hãy thử dùng chế độ 'Hiện Hán-Việt' để làm điểm tựa nhớ âm nhé! 🌸"
                ),
                action=ActionType.SHOW_HAN_VIET_MODE,
                severity=3,
            )

        # ── Case 2: Sai Kanji Hán-Việt → mở kho từ vựng ──────────────────
        if mispronounced_words and self._has_sino_japanese_error(mispronounced_words):
            word = mispronounced_words[0]
            return ActionPlan(
                message=(
                    f"Bạn có vẻ chưa chắc âm Hán-Việt của từ 「{word}」. "
                    "Nhấn vào đây để vào kho từ vựng ôn lại nhé!"
                ),
                action=ActionType.OPEN_VOCABULARY,
                target_word=word,
                severity=2,
            )

        # ── Case 3: Câu dài + fluency thấp → kích hoạt Slow-mo ─────────
        if fluency < 65 and sentence_length > 20:
            return ActionPlan(
                message=(
                    "Phản xạ câu dài của bạn chưa tốt. "
                    "Hãy thử lại với tốc độ 0.75x để luyện nhịp nhé! ⏱️"
                ),
                action=ActionType.ACTIVATE_SLOW_MODE,
                severity=2,
            )

        # ── Case 4: Lỗi trường âm/pitch-accent (っ ん ー) ─────────────────
        if self._has_pitch_accent_error(mispronounced_words, error_types):
            bad_word = (error_types.get("pitch_accent") or mispronounced_words or [""])[0]
            return ActionPlan(
                message=(
                    f"Âm đặc biệt 「{bad_word}」 (っ/ん/ー) bạn phát âm chưa chuẩn. "
                    "Đây là điểm khó nhất với người Việt! Xem hướng dẫn pitch-accent nhé 🎵"
                ),
                action=ActionType.SHOW_PITCH_GUIDE,
                target_word=bad_word or None,
                severity=2,
            )

        # ── Case 5: Prosody thấp → gợi ý nghe lại và bắt chước ngữ điệu ─
        if prosody < 60:
            return ActionPlan(
                message=(
                    "Ngữ điệu (Pitch-accent) của bạn chưa khớp mẫu. "
                    "Hãy nghe lại bản gốc 0.75x và chú ý âm lên/xuống của người Nhật bản ngữ! 🎧"
                ),
                action=ActionType.ACTIVATE_SLOW_MODE,
                severity=2,
            )

        # ── Case 6: Tốt! Động viên ────────────────────────────────────────
        if accuracy >= 85 and fluency >= 75:
            return ActionPlan(
                message=(
                    "Tuyệt vời! 🌟 Phát âm và nhịp điệu của bạn rất gần chuẩn bản ngữ. "
                    "Tiếp tục luyện tập để đạt đến mức tự nhiên nhé!"
                ),
                action=ActionType.CELEBRATE,
                severity=0,
            )

        # ── Default: Khuyến khích tiếp tục ───────────────────────────────
        return ActionPlan(
            message="Khá tốt! Hãy luyện thêm để đồng bộ nhịp điệu và ngữ điệu với mẫu. 💪",
            action=ActionType.CELEBRATE,
            severity=1,
        )


# Singleton engine
_recommendation_engine = RecommendationEngine()

# ==============================================================================
# SECTION 1: Audio Pre-processing
# ==============================================================================

def _trim_silence(audio_bytes: bytes, threshold: int = 500, frame_size: int = 512) -> bytes:
 
    if len(audio_bytes) < frame_size * 2:
        return audio_bytes

    def _rms(chunk: bytes) -> float:
        samples = struct.unpack_from(f"<{len(chunk) // 2}h", chunk)
        return (sum(s * s for s in samples) / max(len(samples), 1)) ** 0.5

    # Tìm điểm bắt đầu (trim đầu)
    start = 0
    while start + frame_size <= len(audio_bytes):
        if _rms(audio_bytes[start: start + frame_size]) >= threshold:
            break
        start += frame_size

    # Tìm điểm kết thúc (trim cuối)
    end = len(audio_bytes)
    while end - frame_size >= start:
        if _rms(audio_bytes[end - frame_size: end]) >= threshold:
            break
        end -= frame_size

    trimmed = audio_bytes[start:end]
    if not trimmed:
        return audio_bytes  # Toàn bộ là lặng → giữ nguyên để tránh lỗi

    removed = len(audio_bytes) - len(trimmed)
    print(f"[TrimSilence] {len(audio_bytes)} → {len(trimmed)} bytes (removed {removed} bytes)")
    return trimmed


# ==============================================================================
# SECTION 2: Text Helpers
# ==============================================================================

def _normalize(text: str) -> str:
    """NFKC normalize + lowercase. Dùng để so sánh text thô."""
    return unicodedata.normalize("NFKC", text).strip().lower()


def _normalize_jp(text: str) -> str:
    """
    Normalize text tiếng Nhật để so sánh:
    1. NFKC normalize
    2. Chuyển Kanji/Katakana → Hiragana (để khớp với Google STT output)
    3. Bỏ dấu câu, khoảng trắng
    """
    text = unicodedata.normalize("NFKC", text).strip()
    text = _kanji_to_hira(text)  # Kanji → Hiragana
    text = re.sub(r"[。、！？!?.,・ー…「」『』【】〔〕（）()\s]", "", text)
    return text.lower()


def _jp_mora_split(text: str) -> list[str]:
    """
    Chia văn bản tiếng Nhật thành danh sách mora.
    Tự động convert Kanji → Hiragana trước khi tách.
    """
    SMALL = set("ぁぃぅぇぉっゃゅょァィゥェォッャュョ")
    PUNCT = set("。、！？!?.,・ー…「」『』【】〔〕（）()")
    # Convert Kanji → Hiragana để đồng nhất với Google STT
    text = unicodedata.normalize("NFKC", _kanji_to_hira(text))
    moras = []
    for ch in text:
        if ch in PUNCT or ch.isspace():
            continue
        if ch in SMALL and moras:
            moras[-1] += ch
        else:
            moras.append(ch)
    return moras


def _mora_accuracy(expected: str, recognized: str) -> int:
    """
    Tính độ chính xác theo mora-level (phù hợp tiếng Nhật hơn character-level).
    """
    exp_moras = _jp_mora_split(expected)
    rec_moras = _jp_mora_split(recognized)
    if not exp_moras:
        return 0
    ratio = SequenceMatcher(None, exp_moras, rec_moras).ratio()
    return int(ratio * 100)


def _count_pauses(text: str) -> int:
    """Đếm số lần ngắt câu (、。) — dùng để đánh giá nhịp ngắt."""
    return len(re.findall(r"[、。,.]", text))


def _pitch_particle_coverage(expected: str, recognized: str) -> float:
    """
    Kiểm tra xem các trợ từ pitch-accent (は, が, を, ...) trong câu gốc
    có xuất hiện trong câu được nhận dạng không.
    Trả về tỉ lệ 0.0–1.0.
    """
    exp_particles = [ch for ch in expected if ch in _JP_PITCH_PARTICLES]
    if not exp_particles:
        return 1.0  # Không có trợ từ → không bị phạt
    matched = sum(1 for ch in exp_particles if ch in recognized)
    return matched / len(exp_particles)


# ==============================================================================
# SECTION 3: Scoring Logic
# ==============================================================================

def _compute_scores(expected: str, recognized: str) -> tuple[int, int, int]:
    """
    Tính (accuracy, fluency, prosody) từ text expected vs recognized.

    - accuracy : dựa trên mora-level similarity (chính xác nhất cho tiếng Nhật)
    - fluency  : tỉ lệ mora khớp + guard cho câu ngắn (tránh điểm nhiễu)
    - prosody  : kết hợp độ dài tương đối + độ phủ trợ từ pitch-accent
    """
    # --- Accuracy (mora-level) ---
    accuracy = _mora_accuracy(expected, recognized)

    # --- Fluency ---
    exp_moras = _jp_mora_split(expected)
    rec_moras = _jp_mora_split(recognized)
    matched_moras = sum(1 for m in rec_moras if m in exp_moras)
    fluency = min(int((matched_moras / max(len(exp_moras), 1)) * 100), 100)

    # --- Prosody: độ phủ trợ từ + tỉ lệ độ dài ---
    pitch_cov   = _pitch_particle_coverage(expected, recognized)
    mora_ratio  = min(len(rec_moras), len(exp_moras)) / max(len(exp_moras), 1)
    prosody     = min(int((mora_ratio * 0.5 + pitch_cov * 0.5) * accuracy * 0.95), 100)

    # ----------------------------------------------------------------
    # GUARD — Câu ngắn (< 15 ký tự): giảm ảnh hưởng của Fluency nhiễu
    # ----------------------------------------------------------------
    is_short = len(expected.strip()) < 15
    if is_short:
        if accuracy >= 90:
            fluency  = max(fluency, 75)   # Đọc đúng → Fluency tối thiểu 75
        elif accuracy >= 75:
            fluency  = max(fluency, 50)   # Khá đúng → Fluency tối thiểu 50
        # Với câu ngắn, prosody nặng về accuracy hơn fluency
        prosody = min(int(accuracy * 0.85 + fluency * 0.10), 100)

    return accuracy, fluency, prosody


def _compute_shadowing_scores(expected: str, recognized: str) -> tuple[int, int, int, int]:
    """
    Chấm điểm riêng cho chế độ Shadowing.
    Trả về (accuracy, fluency, prosody, rhythm_score).

    - rhythm_score: điểm đánh giá nhịp ngắt (ngắt đúng chỗ 、。)
    """
    accuracy, fluency, prosody = _compute_scores(expected, recognized)

    # Rhythm: so sánh số lần ngắt câu trong expected vs recognized
    exp_pauses = _count_pauses(expected)
    rec_pauses = _count_pauses(recognized)
    if exp_pauses == 0:
        rhythm_score = 100  # Câu không có ngắt → không bị phạt
    else:
        pause_ratio  = 1.0 - abs(exp_pauses - rec_pauses) / max(exp_pauses, 1)
        rhythm_score = max(int(pause_ratio * 100), 0)

    # Prosody cho shadowing: kết hợp thêm rhythm
    prosody = min(int(prosody * 0.7 + rhythm_score * 0.3), 100)

    return accuracy, fluency, prosody, rhythm_score


def _find_error_word(expected: str, recognized: str) -> str:
    """Tìm từ/cụm bị sai — normalize cả 2 về Hiragana trước khi so sánh."""
    exp_hira = _normalize_jp(expected)
    rec_hira = _normalize_jp(recognized)
    # Tìm từ kanji trong expected mà Hiragana tương ứng không có trong recognized
    # Dùng pykakasi để tách từ
    try:
        from janome.tokenizer import Tokenizer
        t = Tokenizer()
        tokens = [tok.surface for tok in t.tokenize(expected)]
        for tok in tokens:
            tok_hira = _normalize_jp(tok)
            if tok_hira and len(tok_hira) > 1 and tok_hira not in rec_hira:
                return tok
    except Exception:
        pass
    # Fallback: tìm từ space-separated
    rec_lower = _normalize(recognized)
    for word in _normalize(expected).split():
        word_clean = re.sub(r'[。、！？!?.,・ー…「」『』【】〔〕（）()]', '', word)
        if word_clean and word_clean not in rec_lower and len(word_clean) > 1:
            idx = _normalize(expected).find(word)
            if idx != -1:
                return expected[idx: idx + len(word)]
    return ""


# ==============================================================================
# SECTION 4: Tip / Feedback Builder
# ==============================================================================

def _build_tip(accuracy: int, fluency: int, prosody: int, error_word: str,
               rhythm_score: int = None, mode: str = "normal") -> str:
    if accuracy < 40:
        return "Điểm phát âm quá thấp. Lắng nghe lại mẫu, chú ý khẩu hình và vị trí lưỡi khi phát âm tiếng Nhật."

    if mode == "shadowing":
        if rhythm_score is not None and rhythm_score < 60:
            return (
                "🎵 Nhịp ngắt không khớp với mẫu. Trong Shadowing, bạn cần ngắt đúng ở dấu 「、」 và 「。」. "
                "Thử luyện chậm 0.75x, chú ý chỗ người đọc mẫu dừng hơi."
            )
        if prosody < 65:
            return (
                "🔤 Ngữ điệu (Prosody) Shadowing chưa khớp. Tiếng Nhật dùng Pitch-accent — "
                "trợ từ は・が・を thường được nâng/hạ giọng. Nghe cẩn thận và bắt chước chính xác âm lên/xuống."
            )
        if fluency < 65:
            return "⏱️ Fluency còn thấp. Trong Shadowing, hãy đảm bảo nói đều đặn, không ngắt giữa từ ghép."
        if accuracy >= 85 and fluency >= 80 and prosody >= 75:
            return "🌟 Shadowing xuất sắc! Nhịp ngắt, ngữ điệu và phát âm rất gần với mẫu bản ngữ!"
        return "👍 Khá tốt! Tiếp tục luyện Shadowing để đồng bộ nhịp điệu và ngữ điệu với mẫu."

    # Normal mode
    if prosody < 60:
        return "Ngữ điệu (Prosody) chưa đạt. Tiếng Nhật là ngôn ngữ Pitch-accent — lên/xuống giọng đúng ở trợ từ は・が・を."
    if fluency < 60:
        return "Độ trôi chảy (Fluency) thấp. Ngắt sau trợ từ, không ngắt giữa từ ghép."
    if accuracy < 80 and error_word:
        return f"Phần bị bôi đỏ «{error_word}» chưa chuẩn. Thử nghe chậm 0.5x và bắt chước từng âm tiết."
    if accuracy >= 90 and fluency >= 80:
        return "Xuất sắc! Ngữ điệu, nhịp ngắt và phát âm rất chuẩn. Tiếp tục luyện để đạt chuẩn bản ngữ!"
    return "Khá tốt! Luyện thêm nhấn âm và ngắt nghỉ để tăng Fluency!"


# ==============================================================================
# SECTION 4b: Gemini AI — sinh gợi ý cải thiện thông minh
# ==============================================================================

async def _ai_generate_tip(
    accuracy: int,
    fluency: int,
    prosody: int,
    error_word: str,
    expected_text: str,
    recognized_text: str,
    fallback_tip: str,
) -> str:
    """
    Gọi Gemini 2.0 Flash để sinh gợi ý cải thiện phát âm cá nhân hóa.
    Fallback về tip tĩnh nếu không có key hoặc lỗi mạng.
    """
    if not GEMINI_API_KEY:
        return fallback_tip

    prompt = (
        "Bạn là giáo viên tiếng Nhật chuyên luyện phát âm và shadowing. "
        "Học viên vừa đọc một câu tiếng Nhật và nhận được kết quả sau:\n\n"
        f"- Câu gốc (mẫu):  {expected_text}\n"
        f"- Câu nhận diện:  {recognized_text or '(không nhận diện được)'}\n"
        f"- Độ chính xác phát âm: {accuracy}/100\n"
        f"- Fluency (ngắt nghỉ):  {fluency}/100\n"
        f"- Prosody (ngữ điệu):   {prosody}/100\n"
        + (f"- Từ phát âm sai:        {error_word}\n" if error_word else "")
        + "\nHãy đưa ra **1 đến 3 gợi ý ngắn gọn, cụ thể và thực hành được ngay** "
        "để học viên cải thiện điểm yếu nhất. "
        "Nếu điểm tốt thì động viên ngắn và khuyến khích tiếp tục. "
        "Trả lời bằng tiếng Việt, không dùng markdown, không quá 80 từ."
    )

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"gemini-2.0-flash:generateContent?key={GEMINI_API_KEY}"
    )
    payload = {"contents": [{"parts": [{"text": prompt}]}]}

    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.post(url, json=payload)
        if resp.status_code == 200:
            data = resp.json()
            text = (
                data.get("candidates", [{}])[0]
                .get("content", {})
                .get("parts", [{}])[0]
                .get("text", "")
                .strip()
            )
            if text:
                return text
    except Exception as e:
        print(f"[Gemini tip] Error: {e}")

    return fallback_tip

# Danh sách model fallback theo thứ tự ưu tiên
_GEMINI_MODELS = [
    "gemini-2.0-flash",
    "gemini-2.0-flash-lite",
    "gemini-1.5-flash-8b",
]


async def _gemini_post(prompt: str, timeout: int = 20) -> dict:
    """
    Gọi Gemini API với fallback model nếu bị 429 quota.
    Trả về parsed JSON hoặc {} nếu thất bại.
    """
    if not GEMINI_API_KEY:
        return {}

    payload = {"contents": [{"parts": [{"text": prompt}]}]}

    for model in _GEMINI_MODELS:
        url = (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{model}:generateContent?key={GEMINI_API_KEY}"
        )
        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                resp = await client.post(url, json=payload)

            if resp.status_code == 429:
                print(f"[Gemini] {model} quota exceeded, trying next model...")
                continue  # thử model kế tiếp

            if resp.status_code == 200:
                data = resp.json()
                text = (
                    data.get("candidates", [{}])[0]
                    .get("content", {})
                    .get("parts", [{}])[0]
                    .get("text", "")
                    .strip()
                )
                # Clean markdown
                text = re.sub(r"^```(?:json)?\s*", "", text, flags=re.MULTILINE)
                text = re.sub(r"\s*```$", "", text, flags=re.MULTILINE)
                text = text.strip()
                match = re.search(r"\{.*\}", text, re.DOTALL)
                if match:
                    return _json.loads(match.group())
                return {"_text": text}  # text bình thường

            print(f"[Gemini] {model} HTTP {resp.status_code}")
        except Exception as e:
            print(f"[Gemini] {model} error: {e}")

    return {}


async def _ai_full_evaluation(expected_text: str, recognized_text: str) -> dict:
    """
    Dùng Gemini để chấm điểm shadowing toàn diện.

    Lưu ý quan trọng:
    - expected_text có thể là Kanji (ví dụ: 明日は早く起きなければなりません)
    - recognized_text là output của Google STT — thường ở dạng Hiragana
    - Gemini cần hiểu rằng Kanji và Hiragana đọc giống nhau là ĐÚNG
    """
    if not recognized_text or recognized_text == "(Được đọc)":
        return {}

    # Convert expected sang Hiragana để Gemini so sánh dễ hơn
    expected_hira = _kanji_to_hira(expected_text)

    prompt = (
        "Bạn là giám khảo chấm thi nói tiếng Nhật chuyên nghiệp.\n\n"
        f"★ Câu gốc (Kanji):   {expected_text}\n"
        f"★ Câu gốc (Hiragana): {expected_hira}\n"
        f"★ STT nhận dạng:     {recognized_text}\n\n"
        "QUY TẮc CHẤM QUAN TRỌNG:\n"
        "- STT Google trả về Hiragana, câu gốc có thể là Kanji. "
        "Hãy so sánh theo ÂM ĐỌC, không phải ký tự.\n"
        "- Nếu STT khớp hoàn toàn với Hiragana của câu gốc → accuracy ≥ 90, fluency ≥ 85.\n"
        "- Nếu thiếu 1-2 từ → accuracy 70-85.\n"
        "- Nếu sai nhiều → accuracy < 70.\n"
        "- Không phạt điểm vì khác Kanji/Hiragana.\n\n"
        "Trả về JSON THUẦN (không markdown, không text ngoài JSON):\n"
        "{\n"
        '  "accuracy": 85,\n'
        '  "fluency": 80,\n'
        '  "prosody": 75,\n'
        '  "rhythm": 90,\n'
        '  "mispronounced_words": [],\n'
        '  "error_types": {\n'
        '    "pronunciation": [],\n'
        '    "prosody": [],\n'
        '    "pitch_accent": [],\n'
        '    "rhythm": []\n'
        '  },\n'
        '  "words_analysis": [\n'
        '    {"text": "明日は", "is_correct": true},\n'
        '    {"text": "早く起き", "is_correct": true}\n'
        '  ]\n'
        "}\n\n"
        "Quy tắc words_analysis:\n"
        "1. Chia nhỏ câu gốc thành cụm 2-4 ký tự Kanji/Kana.\n"
        "2. is_correct=true nếu cụm đó được nói đúng (dựa theo Hiragana).\n"
        "3. Gép lại phải khôi phục được 100% câu gốc."
    )

    result = await _gemini_post(prompt, timeout=20)
    if result and "accuracy" in result:
        # Validate và clamp điểm
        for k in ["accuracy", "fluency", "prosody", "rhythm"]:
            if k in result:
                result[k] = max(0, min(100, int(result[k])))
        return result
    return {}

def _fallback_word_analysis(expected_text: str, recognized_text: str) -> list:
    """Fallback tự cắt từ bằng Janome nếu Gemini hết quota."""
    try:
        from janome.tokenizer import Tokenizer
        import pykakasi
        
        t = Tokenizer()
        kks = pykakasi.kakasi()
        words_analysis = []
        rec_clean = recognized_text.replace(' ', '').replace('、', '').replace('。', '')
        
        tokens = [token.surface for token in t.tokenize(expected_text)]
        for token in tokens:
            if token in '。、！？!?.,・ー…「」『』【】〔〕（）()':
                words_analysis.append({'text': token, 'is_correct': True})
                continue
                
            if token in rec_clean:
                words_analysis.append({'text': token, 'is_correct': True})
            else:
                token_hira = ''.join([i['hira'] for i in kks.convert(token)])
                if token_hira in rec_clean:
                    words_analysis.append({'text': token, 'is_correct': True})
                else:
                    words_analysis.append({'text': token, 'is_correct': False})
                    
        merged = []
        for item in words_analysis:
            if merged and merged[-1]['is_correct'] == item['is_correct']:
                merged[-1]['text'] += item['text']
            else:
                merged.append(item)
        return merged
    except Exception as e:
        print("[Fallback Word Analysis Error]", e)
        return [{"text": expected_text, "is_correct": False}]






# ==============================================================================
# SECTION 5: Google STT
# ==============================================================================

async def _google_stt(audio_bytes: bytes, audio_filename: str) -> tuple[str, int]:
    """
    Gửi audio bytes lên Google Speech-to-Text REST API.
    Trả về (transcript, measured_pauses).
    """
    channel_count = 1
    opus_head_magic = b"OpusHead"
    idx = audio_bytes.find(opus_head_magic)
    if idx != -1 and idx + 9 < len(audio_bytes):
        channel_count = audio_bytes[idx + 9]

    audio_b64 = base64.b64encode(audio_bytes).decode("utf-8")

    payload = {
        "config": {
            "languageCode": "ja-JP",
            "audioChannelCount": channel_count,
            "alternativeLanguageCodes": [],
            "enableAutomaticPunctuation": True,
            "enableWordTimeOffsets": True,  # Bat tinh nang Time Offsets
            "model": "latest_long",
        },
        "audio": {"content": audio_b64},
    }

    url = "https://speech.googleapis.com/v1/speech:recognize"
    params = {"key": GOOGLE_API_KEY} if GOOGLE_API_KEY else {}

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(url, json=payload, params=params)

    if resp.status_code == 200:
        data = resp.json()
        results = data.get("results", [])
        if results:
            alt = results[0]["alternatives"][0]
            transcript = alt.get("transcript", "").strip()
            words = alt.get("words", [])
            
            # Tính toán số lần ngắt nghỉ > 400ms trên audio thực tế
            measured_pauses = 0
            for i in range(len(words) - 1):
                try:
                    end_str = words[i].get("endTime", "0s").replace("s", "")
                    next_start_str = words[i+1].get("startTime", "0s").replace("s", "")
                    if float(next_start_str) - float(end_str) >= 0.4:
                        measured_pauses += 1
                except:
                    pass
            return transcript, measured_pauses
        return "", 0
    else:
        print(f"[Google STT] HTTP {resp.status_code}: {resp.text[:300]}")
        return "", 0


# ==============================================================================
# SECTION 6: Endpoints
# ==============================================================================

@router.post("/")
async def evaluate_voice(
    audio: UploadFile = File(None),
    expected_text: str = Form(...),
    romaji: str = Form(None),
):
    """Chấm điểm phát âm chế độ thường (Normal mode)."""
    recognized_text = ""
    error_word      = ""
    accuracy_score  = 0
    fluency_score   = 0
    prosody_score   = 0

    print("AZURE_SPEECH_KEY", AZURE_SPEECH_KEY)
    print("GOOGLE_API_KEY", GOOGLE_API_KEY)

    try:
        # ----------------------------------------------------------------
        # LUỒNG 1: Azure Pronunciation Assessment
        # ----------------------------------------------------------------
        if audio and AZURE_SPEECH_KEY:
            audio_bytes = _trim_silence(await audio.read())
            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
                tmp.write(audio_bytes)
                tmp_path = tmp.name

            import azure.cognitiveservices.speech as speechsdk

            speech_config = speechsdk.SpeechConfig(subscription=AZURE_SPEECH_KEY, region=AZURE_SPEECH_REGION)
            speech_config.speech_recognition_language = "ja-JP"
            audio_cfg = speechsdk.audio.AudioConfig(filename=tmp_path)
            pron_cfg  = speechsdk.PronunciationAssessmentConfig(
                reference_text=expected_text,
                grading_system=speechsdk.PronunciationAssessmentGradingSystem.HundredMark,
                granularity=speechsdk.PronunciationAssessmentGranularity.Phoneme,
                enable_miscue=True,
            )
            rec = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_cfg)
            pron_cfg.apply_to(rec)
            result = rec.recognize_once_async().get()
            os.remove(tmp_path)

            if result.reason == speechsdk.ResultReason.RecognizedSpeech:
                pr = speechsdk.PronunciationAssessmentResult(result)
                accuracy_score  = int(pr.accuracy_score)
                fluency_score   = int(pr.fluency_score)
                prosody_score   = int(pr.prosody_score)
                recognized_text = result.text
                error_word      = _find_error_word(expected_text, recognized_text)

                # Áp dụng guard câu ngắn cho Azure cũng
                is_short = len(expected_text.strip()) < 15
                if is_short:
                    if accuracy_score >= 90:
                        fluency_score = max(fluency_score, 75)
                    elif accuracy_score >= 75:
                        fluency_score = max(fluency_score, 50)
            else:
                raise ValueError("Azure không nhận diện được giọng nói.")

        # ----------------------------------------------------------------
        # LUỒNG 2: Google Speech REST API
        # ----------------------------------------------------------------
        elif audio and GOOGLE_API_KEY:
            audio_bytes = _trim_silence(await audio.read())
            recognized_text, measured_pauses = await _google_stt(audio_bytes, audio.filename or "record.webm")
            accuracy_score, fluency_score, prosody_score = _compute_scores(expected_text, recognized_text)
            error_word = _find_error_word(expected_text, recognized_text)

        # ----------------------------------------------------------------
        # LUỒNG 3: MOCK DEMO
        # ----------------------------------------------------------------
        elif audio:
            import random
            words = expected_text.split("、") if "、" in expected_text else expected_text.split()
            recognized_words = words.copy()
            has_error = random.random() < 0.3 and len(words) > 1
            error_word = ""
            if has_error:
                idx = random.randint(0, len(words) - 1)
                error_word = words[idx]
                recognized_words[idx] = "..."
            recognized_text = " ".join(recognized_words)
            accuracy_score  = random.randint(75, 89) if has_error else random.randint(90, 100)
            fluency_score   = accuracy_score - random.randint(0, 15) if accuracy_score > 80 else random.randint(40, 70)
            prosody_score   = accuracy_score - random.randint(5, 20) if accuracy_score > 80 else random.randint(30, 60)
            fluency_score   = max(0, fluency_score)
            prosody_score   = max(0, prosody_score)

        # ----------------------------------------------------------------
        # LUỒNG 4: Không có audio
        # ----------------------------------------------------------------
        else:
            recognized_text = "(Không nhận được audio)"

        if accuracy_score >= 90:
            error_word = ""

        tip = _build_tip(accuracy_score, fluency_score, prosody_score, error_word, mode="normal")

        return {
            "success": True,
            "accuracy": accuracy_score,
            "fluency":  fluency_score,
            "prosody":  prosody_score,
            "recognized_text": recognized_text,
            "error_word": error_word,
            "tip": tip,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==============================================================================
# Endpoint Shadowing
# ==============================================================================

@router.post("/shadowing")
async def evaluate_shadowing(
    audio: UploadFile = File(None),
    expected_text: str = Form(...),
    romaji: str = Form(None),
):
    """
    Chấm điểm chế độ Shadowing.
    Ngoài accuracy/fluency/prosody còn trả về rhythm_score (điểm nhịp ngắt).
    Prosody được tính lại có trọng số nhịp ngắt (rhythm) — phù hợp để
    luyện ngữ điệu và âm điệu theo mẫu bản ngữ.
    """
    recognized_text = ""
    error_word      = ""
    accuracy_score  = 0
    fluency_score   = 0
    prosody_score   = 0
    rhythm_score    = 0

    try:
        # ----------------------------------------------------------------
        # LUỒNG 1: Azure
        # ----------------------------------------------------------------
        if audio and AZURE_SPEECH_KEY:
            audio_bytes = _trim_silence(await audio.read())
            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
                tmp.write(audio_bytes)
                tmp_path = tmp.name

            import azure.cognitiveservices.speech as speechsdk

            speech_config = speechsdk.SpeechConfig(subscription=AZURE_SPEECH_KEY, region=AZURE_SPEECH_REGION)
            speech_config.speech_recognition_language = "ja-JP"
            audio_cfg = speechsdk.audio.AudioConfig(filename=tmp_path)
            pron_cfg  = speechsdk.PronunciationAssessmentConfig(
                reference_text=expected_text,
                grading_system=speechsdk.PronunciationAssessmentGradingSystem.HundredMark,
                granularity=speechsdk.PronunciationAssessmentGranularity.Phoneme,
                enable_miscue=True,
            )
            rec = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_cfg)
            pron_cfg.apply_to(rec)
            result = rec.recognize_once_async().get()
            os.remove(tmp_path)

            if result.reason == speechsdk.ResultReason.RecognizedSpeech:
                pr = speechsdk.PronunciationAssessmentResult(result)
                accuracy_score  = int(pr.accuracy_score)
                fluency_score   = int(pr.fluency_score)
                recognized_text = result.text
                error_word      = _find_error_word(expected_text, recognized_text)

                # Tính rhythm và prosody shadowing
                exp_pauses = _count_pauses(expected_text)
                rec_pauses = _count_pauses(recognized_text)
                if exp_pauses == 0:
                    rhythm_score = 100
                else:
                    pause_ratio  = 1.0 - abs(exp_pauses - rec_pauses) / max(exp_pauses, 1)
                    rhythm_score = max(int(pause_ratio * 100), 0)

                azure_prosody = int(pr.prosody_score)
                prosody_score = min(int(azure_prosody * 0.7 + rhythm_score * 0.3), 100)

                # Guard câu ngắn
                is_short = len(expected_text.strip()) < 15
                if is_short:
                    if accuracy_score >= 90:
                        fluency_score = max(fluency_score, 75)
                    elif accuracy_score >= 75:
                        fluency_score = max(fluency_score, 50)
            else:
                raise ValueError("Azure không nhận diện được giọng nói.")

        # ----------------------------------------------------------------
        # LUỒNG 2: Google STT
        # ----------------------------------------------------------------
        elif audio and GOOGLE_API_KEY:
            audio_bytes = _trim_silence(await audio.read())
            recognized_text, measured_pauses = await _google_stt(audio_bytes, audio.filename or "record.webm")
            accuracy_score, fluency_score, prosody_score, rhythm_score = _compute_shadowing_scores(
                expected_text, recognized_text
            )
            
            # Ghi đè rhythm bằng measured_pauses từ Google Timestamps nếu có
            exp_pauses = _count_pauses(expected_text)
            if exp_pauses > 0:
                pause_ratio = 1.0 - abs(exp_pauses - measured_pauses) / max(exp_pauses, 1)
                rhythm_score = max(int(pause_ratio * 100), 0)
            
            error_word = _find_error_word(expected_text, recognized_text)

        # ----------------------------------------------------------------
        # LUỒNG 3: MOCK DEMO Shadowing
        # ----------------------------------------------------------------
        elif audio:
            import random
            accuracy_score  = random.randint(78, 100)
            fluency_score   = accuracy_score - random.randint(0, 12)
            rhythm_score    = random.randint(60, 100)
            prosody_score   = min(int(accuracy_score * 0.7 + rhythm_score * 0.3), 100)
            fluency_score   = max(0, fluency_score)
            recognized_text = expected_text

        else:
            recognized_text = "(Không nhận được audio)"

        if accuracy_score >= 90:
            error_word = ""

        fallback_tip = _build_tip(
            accuracy_score, fluency_score, prosody_score, error_word,
            rhythm_score=rhythm_score, mode="shadowing"
        )
        tip = await _ai_generate_tip(
            accuracy=accuracy_score,
            fluency=fluency_score,
            prosody=prosody_score,
            error_word=error_word,
            expected_text=expected_text,
            recognized_text=recognized_text,
            fallback_tip=fallback_tip,
        )

        # ----------------------------------------------------------------
        # BƯỚC 1: Đánh giá AI toàn diện (Gemini) → lấy structured errors
        # ----------------------------------------------------------------
        words_analysis       = []
        mispronounced_words  = []
        error_types          = {"pronunciation": [], "prosody": [], "pitch_accent": [], "rhythm": []}

        if recognized_text and recognized_text != "(Không nhận được audio)":
            ai_eval = await _ai_full_evaluation(expected_text, recognized_text)
            if ai_eval:
                accuracy_score      = ai_eval.get("accuracy", accuracy_score)
                fluency_score       = ai_eval.get("fluency", fluency_score)
                prosody_score       = ai_eval.get("prosody", prosody_score)
                rhythm_score        = ai_eval.get("rhythm", rhythm_score)
                words_analysis      = ai_eval.get("words_analysis", [])
                mispronounced_words = ai_eval.get("mispronounced_words", [])
                error_types         = ai_eval.get("error_types", error_types)

        if not words_analysis:
            words_analysis = _fallback_word_analysis(expected_text, recognized_text)

        # ----------------------------------------------------------------
        # BƯỚC 2: RecommendationEngine → sinh ActionPlan cá nhân hóa
        # ----------------------------------------------------------------
        action_plan = _recommendation_engine.analyze(
            accuracy=accuracy_score,
            fluency=fluency_score,
            prosody=prosody_score,
            rhythm=rhythm_score,
            mispronounced_words=mispronounced_words,
            error_types=error_types,
            sentence_length=len(expected_text),
        )

        return {
            "success":             True,
            "mode":               "shadowing",
            "accuracy":           accuracy_score,
            "fluency":            fluency_score,
            "prosody":            prosody_score,
            "rhythm":             rhythm_score,
            "recognized_text":    recognized_text,
            "error_word":         error_word,
            "mispronounced_words": mispronounced_words,
            "error_types":        error_types,
            "words_analysis":     words_analysis,
            "tip":                tip,
            "action_plan":        action_plan.to_dict(),
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
