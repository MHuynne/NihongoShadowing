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


try:
    import pykakasi as _pykakasi
    _kks = _pykakasi.kakasi()
    def _kanji_to_hira(text: str) -> str:
        """Chuyển toàn bộ chuỗi Kanji/Katakana → Hiragana thuần."""
        result = _kks.convert(text)
        return "".join(item["hira"] or item["orig"] for item in result)
except Exception:
    def _kanji_to_hira(text: str) -> str:
        return text

router = APIRouter(prefix="/evaluate", tags=["AI Speech Evaluation"])




AZURE_SPEECH_KEY    = os.getenv("AZURE_SPEECH_KEY", "")
AZURE_SPEECH_REGION = os.getenv("AZURE_SPEECH_REGION", "eastasia")




GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "")






GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "") or GOOGLE_API_KEY


_raw_keys = os.getenv("GEMINI_API_KEYS", "")
_GEMINI_KEY_POOL: list[str] = [k.strip() for k in _raw_keys.split(",") if k.strip()]
if GEMINI_API_KEY and GEMINI_API_KEY not in _GEMINI_KEY_POOL:
    _GEMINI_KEY_POOL.insert(0, GEMINI_API_KEY)

_key_index = 0

def _next_gemini_key() -> str:
    """Trả về key tiếp theo theo vòng tròn. Thread-safe cho single-process."""
    global _key_index
    if not _GEMINI_KEY_POOL:
        return GEMINI_API_KEY
    key = _GEMINI_KEY_POOL[_key_index % len(_GEMINI_KEY_POOL)]
    _key_index += 1
    return key



_JP_PITCH_PARTICLES = {"は", "が", "を", "に", "で", "と", "も", "の", "へ", "から", "まで", "より", "ね", "よ", "か"}





class ErrorType(str, Enum):
    PRONUNCIATION = "pronunciation"
    PROSODY       = "prosody"
    RHYTHM        = "rhythm"
    PITCH_ACCENT  = "pitch_accent"

class ActionType(str, Enum):
    SHOW_HAN_VIET_MODE  = "show_han_viet_mode"
    OPEN_VOCABULARY     = "open_vocabulary"
    ACTIVATE_SLOW_MODE  = "activate_slow_mode"
    SHOW_PITCH_GUIDE    = "show_pitch_guide"
    CELEBRATE           = "celebrate"
    RETRY               = "retry"

@dataclass
class ActionPlan:
    message: str
    action: ActionType
    target_word: Optional[str] = None
    severity: int = 1

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



    _SINO_JAPANESE_PATTERNS = [
        "学", "語", "音", "字", "校", "会", "社", "国", "人", "文",
        "生", "先", "大", "小", "中", "高", "新", "本", "日", "年",
        "力", "気", "電", "水", "火", "金", "木", "土", "花", "山",
        "農", "業", "市", "府", "県", "区", "町", "村", "道", "京",
    ]


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

        if accuracy < 50:
            return ActionPlan(
                message=(
                    "Đừng nản lòng! Điểm phát âm của bạn chưa đạt ngưỡng Pass. "
                    "Hãy thử dùng chế độ 'Hiện Hán-Việt' để làm điểm tựa nhớ âm nhé! 🌸"
                ),
                action=ActionType.SHOW_HAN_VIET_MODE,
                severity=3,
            )


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


        if fluency < 65 and sentence_length > 20:
            return ActionPlan(
                message=(
                    "Phản xạ câu dài của bạn chưa tốt. "
                    "Hãy thử lại với tốc độ 0.75x để luyện nhịp nhé! ⏱️"
                ),
                action=ActionType.ACTIVATE_SLOW_MODE,
                severity=2,
            )


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


        if prosody < 60:
            return ActionPlan(
                message=(
                    "Ngữ điệu (Pitch-accent) của bạn chưa khớp mẫu. "
                    "Hãy nghe lại bản gốc 0.75x và chú ý âm lên/xuống của người Nhật bản ngữ! 🎧"
                ),
                action=ActionType.ACTIVATE_SLOW_MODE,
                severity=2,
            )


        if accuracy >= 85 and fluency >= 75:
            return ActionPlan(
                message=(
                    "Tuyệt vời! 🌟 Phát âm và nhịp điệu của bạn rất gần chuẩn bản ngữ. "
                    "Tiếp tục luyện tập để đạt đến mức tự nhiên nhé!"
                ),
                action=ActionType.CELEBRATE,
                severity=0,
            )


        return ActionPlan(
            message="Khá tốt! Hãy luyện thêm để đồng bộ nhịp điệu và ngữ điệu với mẫu. 💪",
            action=ActionType.CELEBRATE,
            severity=1,
        )



_recommendation_engine = RecommendationEngine()





def _trim_silence(audio_bytes: bytes) -> bytes:
    """Chuyen doi moi dinh dang nen (OGG/WEBM/M4A) sang WAV LINEAR16 16kHz Mono bang ffmpeg.
    Khong dung pydub vi audioop bi xoa tu Python 3.13+."""
    import subprocess
    import tempfile
    import os
    try:
        with tempfile.NamedTemporaryFile(suffix='.webm', delete=False) as tmp_in:
            tmp_in.write(audio_bytes)
            tmp_in_path = tmp_in.name
        tmp_out_path = tmp_in_path + '.wav'
        try:
            result = subprocess.run(
                ['ffmpeg', '-y', '-i', tmp_in_path,
                 '-ac', '1', '-ar', '16000', '-acodec', 'pcm_s16le',
                 tmp_out_path],
                capture_output=True, timeout=30,
            )
            if result.returncode == 0 and os.path.exists(tmp_out_path):
                with open(tmp_out_path, 'rb') as f:
                    wav_bytes = f.read()
                in_sz = len(audio_bytes)
                out_sz = len(wav_bytes)
                print(f"[AudioConvert] ffmpeg OK: {in_sz} bytes -> WAV {out_sz} bytes.")
                return wav_bytes
            else:
                err = result.stderr.decode(errors='replace')
                rc = result.returncode
                print(f"[AudioConvert] ffmpeg failed (rc={rc}): {err}")
                return audio_bytes
        finally:
            for p in [tmp_in_path, tmp_out_path]:
                try:
                    os.unlink(p)
                except OSError:
                    pass
    except FileNotFoundError:
        print("[AudioConvert] ffmpeg not found in PATH -- tra ve audio goc.")
        return audio_bytes
    except Exception as e:
        print(f"[AudioConvert] Failed: {e}")
        return audio_bytes






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
    text = _kanji_to_hira(text)
    text = re.sub(r"[。、！？!?.,・ー…「」『』【】〔〕（）()\s]", "", text)
    return text.lower()


def _jp_mora_split(text: str) -> list[str]:
    """
    Chia văn bản tiếng Nhật thành danh sách mora.
    Tự động convert Kanji → Hiragana trước khi tách.
    """
    SMALL = set("ぁぃぅぇぉっゃゅょァィゥェォッャュョ")
    PUNCT = set("。、！？!?.,・ー…「」『』【】〔〕（）()")

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
        return 1.0
    matched = sum(1 for ch in exp_particles if ch in recognized)
    return matched / len(exp_particles)






def _compute_scores(expected: str, recognized: str) -> tuple[int, int, int]:
    """
    Tính (accuracy, fluency, prosody) từ text expected vs recognized.

    - accuracy : dựa trên mora-level similarity (chính xác nhất cho tiếng Nhật)
    - fluency  : tỉ lệ mora khớp + guard cho câu ngắn (tránh điểm nhiễu)
    - prosody  : kết hợp độ dài tương đối + độ phủ trợ từ pitch-accent
    """

    accuracy = _mora_accuracy(expected, recognized)


    exp_moras = _jp_mora_split(expected)
    rec_moras = _jp_mora_split(recognized)
    fluency_ratio = SequenceMatcher(None, exp_moras, rec_moras).ratio()
    fluency = min(int(fluency_ratio * 100), 100)


    pitch_cov   = _pitch_particle_coverage(expected, recognized)
    mora_ratio  = min(len(rec_moras), len(exp_moras)) / max(len(exp_moras), 1)
    prosody     = min(int((mora_ratio * 0.5 + pitch_cov * 0.5) * accuracy * 0.95), 100)




    is_short = len(expected.strip()) < 15
    if is_short:
        if accuracy >= 90:
            fluency  = max(fluency, 75)
        elif accuracy >= 75:
            fluency  = max(fluency, 50)

        prosody = min(int(accuracy * 0.85 + fluency * 0.10), 100)

    return accuracy, fluency, prosody


def _compute_shadowing_scores(expected: str, recognized: str) -> tuple[int, int, int, int]:
    """
    Chấm điểm riêng cho chế độ Shadowing.
    Trả về (accuracy, fluency, prosody, rhythm_score).

    - rhythm_score: điểm đánh giá nhịp ngắt (ngắt đúng chỗ 、。)
    """
    accuracy, fluency, prosody = _compute_scores(expected, recognized)


    exp_pauses = _count_pauses(expected)
    rec_pauses = _count_pauses(recognized)
    if exp_pauses == 0:
        rhythm_score = 100
    else:
        pause_ratio  = 1.0 - abs(exp_pauses - rec_pauses) / max(exp_pauses, 1)
        rhythm_score = max(int(pause_ratio * 100), 0)


    prosody = min(int(prosody * 0.7 + rhythm_score * 0.3), 100)

    return accuracy, fluency, prosody, rhythm_score


def _find_error_word(expected: str, recognized: str) -> str:
    """Tìm từ/cụm bị sai — normalize cả 2 về Hiragana trước khi so sánh."""
    exp_hira = _normalize_jp(expected)
    rec_hira = _normalize_jp(recognized)


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

    rec_lower = _normalize(recognized)
    for word in _normalize(expected).split():
        word_clean = re.sub(r'[。、！？!?.,・ー…「」『』【】〔〕（）()]', '', word)
        if word_clean and word_clean not in rec_lower and len(word_clean) > 1:
            idx = _normalize(expected).find(word)
            if idx != -1:
                return expected[idx: idx + len(word)]
    return ""






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


    if prosody < 60:
        return "Ngữ điệu (Prosody) chưa đạt. Tiếng Nhật là ngôn ngữ Pitch-accent — lên/xuống giọng đúng ở trợ từ は・が・を."
    if fluency < 60:
        return "Độ trôi chảy (Fluency) thấp. Ngắt sau trợ từ, không ngắt giữa từ ghép."
    if accuracy < 80 and error_word:
        return f"Phần bị bôi đỏ «{error_word}» chưa chuẩn. Thử nghe chậm 0.5x và bắt chước từng âm tiết."
    if accuracy >= 90 and fluency >= 80:
        return "Xuất sắc! Ngữ điệu, nhịp ngắt và phát âm rất chuẩn. Tiếp tục luyện để đạt chuẩn bản ngữ!"
    return "Khá tốt! Luyện thêm nhấn âm và ngắt nghỉ để tăng Fluency!"






async def _ai_generate_tip(
    accuracy: int,
    fluency: int,
    prosody: int,
    error_word: str,
    expected_text: str,
    recognized_text: str,
    fallback_tip: str,
    mispronounced_words: list = None,
) -> str:
    """
    Sinh gợi ý cải thiện phát âm cá nhân hóa bằng Gemini (có fallback model).
    Sử dụng _gemini_post để tự động thử lần lượt các model khi bị quota.
    """
    if not GEMINI_API_KEY:
        return fallback_tip

    mispronounced_info = ", ".join(mispronounced_words) if mispronounced_words else error_word
    prompt = (
        "Bạn là giáo viên tiếng Nhật chuyên luyện phát âm và shadowing.\n"
        "Học viên vừa đọc một câu tiếng Nhật và nhận được kết quả:\n\n"
        f"- Câu gốc (mẫu):       {expected_text}\n"
        f"- Câu nhận diện được:  {recognized_text or '(không nhận diện được)'}\n"
        f"- Độ chính xác phát âm: {accuracy}/100\n"
        f"- Fluency (ngắt nghỉ):  {fluency}/100\n"
        f"- Prosody (ngữ điệu):   {prosody}/100\n"
        + (f"- Từ/cụm phát âm sai:   {mispronounced_info}\n" if mispronounced_info else "")
        + "\nYêu cầu:\n"
        "- Nếu có từ sai: nêu rõ từ đó, giải thích tại sao khó, và hướng dẫn cách sửa cụ thể (vị trí miệng/lưỡi, so sánh với âm tiếng Việt).\n"
        "- Nếu fluency thấp: hướng dẫn cách luyện nhịp ngắt.\n"
        "- Nếu prosody thấp: hướng dẫn cách bắt chước pitch-accent.\n"
        "- Nếu điểm tốt (≥90): động viên ngắn, gợi ý nâng cao.\n"
        "Trả lời bằng tiếng Việt, không dùng markdown, tối đa 100 từ."
    )


    result = await _gemini_post(prompt, timeout=30)
    text = result.get("_text", "").strip()
    if text:
        return text

    return fallback_tip



_GEMINI_MODELS = [
    "gemini-2.0-flash-lite",
    "gemini-2.0-flash",
    "gemini-2.5-flash",
]


_MODEL_TIMEOUT = {
    "gemini-2.0-flash-lite": 20,
    "gemini-2.0-flash": 35,
    "gemini-2.5-flash": 55,
}


async def _gemini_post(prompt: str, timeout: int = 20) -> dict:
    """
    Gọi Gemini API với fallback model + key rotation nếu bị 429 quota.
    Trả về parsed JSON hoặc {} nếu thất bại.
    """
    if not _GEMINI_KEY_POOL and not GEMINI_API_KEY:
        return {}

    payload = {"contents": [{"parts": [{"text": prompt}]}]}

    for model in _GEMINI_MODELS:

        tried_keys: set = set()
        for _ in range(max(len(_GEMINI_KEY_POOL), 1)):
            api_key = _next_gemini_key()
            if api_key in tried_keys:
                continue
            tried_keys.add(api_key)

            url = (
                "https://generativelanguage.googleapis.com/v1beta/models/"
                f"{model}:generateContent?key={api_key}"
            )
            try:
                model_timeout = _MODEL_TIMEOUT.get(model, timeout)
                async with httpx.AsyncClient(timeout=model_timeout) as client:
                    resp = await client.post(url, json=payload)

                if resp.status_code == 429:
                    print(f"[Gemini] {model} key=...{api_key[-6:]} quota exceeded, trying next...")
                    continue

                if resp.status_code == 200:
                    data = resp.json()
                    text = (
                        data.get("candidates", [{}])[0]
                        .get("content", {})
                        .get("parts", [{}])[0]
                        .get("text", "")
                        .strip()
                    )

                    text = re.sub(r"^```(?:json)?\s*", "", text, flags=re.MULTILINE)
                    text = re.sub(r"\s*```$", "", text, flags=re.MULTILINE)
                    text = text.strip()
                    match = re.search(r"\{.*\}", text, re.DOTALL)
                    if match:
                        return _json.loads(match.group())
                    return {"_text": text}

                print(f"[Gemini] {model} HTTP {resp.status_code}")
            except httpx.ReadTimeout:
                print(f"[Gemini] {model} ReadTimeout after {_MODEL_TIMEOUT.get(model, timeout)}s, trying next model...")
            except Exception as e:
                print(f"[Gemini] {model} error: {repr(e)}")

    return {}



async def _ai_full_evaluation(expected_text: str, recognized_text: str) -> dict:
    """
    Dùng Gemini để chấm điểm shadowing toàn diện.

    Early-exit: nếu Hiragana của recognized khớp ≥ 95% với expected
    thì không cần gọi Gemini — trả về điểm cao tức thì.
    """
    if not recognized_text or recognized_text == "(Được đọc)":
        return {}


    exp_hira_norm = _normalize_jp(expected_text)
    rec_hira_norm = _normalize_jp(recognized_text)
    quick_ratio   = SequenceMatcher(None, list(exp_hira_norm), list(rec_hira_norm)).ratio()


    if quick_ratio >= 0.95:
        acc = min(int(quick_ratio * 100), 100)
        return {
            "accuracy": acc,
            "fluency":  max(acc - 5, 85),
            "prosody":  max(acc - 10, 80),
            "rhythm":   90,
            "mispronounced_words": [],
            "error_types": {"pronunciation": [], "prosody": [], "pitch_accent": [], "rhythm": []},
            "words_analysis": [{"text": expected_text, "is_correct": True}],
        }


    expected_hira = _kanji_to_hira(expected_text)

    prompt = (
        "Bạn là giám khảo chấm thi nói tiếng Nhật. So sánh DỰA TRÊN ÂM ĐỌC Hiragana, KHÔNG phải ký tự bề mặt.\n\n"
        f"★ Câu gốc (Kanji):    {expected_text}\n"
        f"★ Câu gốc (Hiragana): {expected_hira}\n"
        f"★ STT nhận dạng:      {recognized_text}\n\n"
        "QUY TẮC QUAN TRỌNG:\n"
        "- Kanji và Hiragana đọc giống nhau là ĐÚNG HOÀN TOÀN (is_correct=true).\n"
        "  VD: 明日=あした, 早く=はやく, 起き=おき → là ĐÚNG nếu STT ra Hiragana tương ứng.\n"
        "- Chỉ đánh sai (is_correct=false) khi ÂM ĐỌC thực sự khác nhau.\n"
        "- Nếu STT Hiragana khớp ≥90% Hiragana câu gốc → accuracy 85-100.\n"
        "- Nếu thiếu/thêm 1 mora → accuracy giảm 8 điểm.\n"
        "- Nếu sai 1 từ → accuracy giảm 15 điểm. Sai nhiều → accuracy < 65.\n"
        "- KHÔNG phạt khi Kanji và Hiragana tương đương nhau.\n\n"
        "Trả về JSON THUẦN (không markdown, không text ngoài JSON):\n"
        "{\n"
        '  "accuracy": 85,\n'
        '  "fluency": 80,\n'
        '  "prosody": 75,\n'
        '  "rhythm": 90,\n'
        '  "mispronounced_words": ["từ sai 1"],\n'
        '  "error_types": {"pronunciation": [], "prosody": [], "pitch_accent": [], "rhythm": []},\n'
        '  "words_analysis": [\n'
        '    {"text": "明日は", "is_correct": true},\n'
        '    {"text": "早く起き", "is_correct": false}\n'
        '  ]\n'
        "}\n\n"
        "Quy tắc words_analysis:\n"
        "1. Chia câu gốc thành cụm 2-4 ký tự Kanji/Kana NGUYÊN GỐC.\n"
        "2. is_correct=false CHỈ KHI âm đọc cụm đó KHÔNG có trong STT output.\n"
        "3. Ghép lại phải khôi phục 100% câu gốc.\n"
        "4. Nếu STT trống hoặc quá ngắn, đánh false cho hầu hết."
    )

    result = await _gemini_post(prompt, timeout=45)
    if result and "accuracy" in result:

        for k in ["accuracy", "fluency", "prosody", "rhythm"]:
            if k in result:
                result[k] = max(0, min(100, int(result[k])))

        if quick_ratio >= 0.80 and result.get("accuracy", 0) < 60:
            boost = int(quick_ratio * 85)
            result["accuracy"] = max(result["accuracy"], boost)
            result["fluency"]  = max(result.get("fluency", 0), boost - 10)
            print(f"[SanityBoost] quick_ratio={quick_ratio:.2f} → accuracy boosted to {result['accuracy']}")
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










async def _google_stt(audio_bytes: bytes, audio_filename: str) -> tuple[str, int]:
    """
    Gửi audio bytes lên Google Speech-to-Text REST API.
    Trả về (transcript, measured_pauses).
    """
    audio_b64 = base64.b64encode(audio_bytes).decode("utf-8")

    config = {
        "languageCode": "ja-JP",
        "alternativeLanguageCodes": [],
        "enableAutomaticPunctuation": True,
        "enableWordTimeOffsets": True,
        "model": "latest_long",
    }

    filename = (audio_filename or "").lower()
    if audio_bytes.startswith(b"RIFF") and audio_bytes[8:12] == b"WAVE":
        config["encoding"] = "LINEAR16"
        config["sampleRateHertz"] = 16000
        config["audioChannelCount"] = 1
    elif audio_bytes.startswith(b"\x1a\x45\xdf\xa3") or filename.endswith(".webm"):
        config["encoding"] = "WEBM_OPUS"



        config["audioChannelCount"] = 2
    elif audio_bytes.startswith(b"OggS") or filename.endswith(".ogg") or filename.endswith(".opus"):
        config["encoding"] = "OGG_OPUS"
    else:
        config["encoding"] = "ENCODING_UNSPECIFIED"


    print(f"[Google STT] config={config}")

    payload = {
        "config": config,
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

        raw_audio_bytes = b""
        if audio:
            raw_audio_bytes = await audio.read()
            with open("debug_raw_voice.raw", "wb") as f:
                f.write(raw_audio_bytes)




        if audio and AZURE_SPEECH_KEY and raw_audio_bytes:
            audio_bytes = _trim_silence(raw_audio_bytes)
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




                text_match = _mora_accuracy(expected_text, recognized_text) / 100.0
                if text_match < 0.85:
                    scale = 0.25 + 0.75 * text_match
                    accuracy_score = int(accuracy_score * scale)
                    fluency_score  = int(fluency_score  * scale)
                    prosody_score  = int(prosody_score  * scale)


                is_short = len(expected_text.strip()) < 15
                if is_short:
                    if accuracy_score >= 90:
                        fluency_score = max(fluency_score, 75)
                    elif accuracy_score >= 75:
                        fluency_score = max(fluency_score, 50)
            else:
                raise ValueError("Azure không nhận diện được giọng nói.")




        elif audio and GOOGLE_API_KEY and raw_audio_bytes:
            audio_bytes = raw_audio_bytes
            recognized_text, measured_pauses = await _google_stt(audio_bytes, audio.filename or "record.webm")
            accuracy_score, fluency_score, prosody_score = _compute_scores(expected_text, recognized_text)
            error_word = _find_error_word(expected_text, recognized_text)




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
    used_azure      = False

    try:

        raw_audio_bytes = b""
        if audio:
            raw_audio_bytes = await audio.read()
            with open("debug_raw_shadowing.raw", "wb") as f:
                f.write(raw_audio_bytes)




        if audio and AZURE_SPEECH_KEY and raw_audio_bytes:
            audio_bytes = _trim_silence(raw_audio_bytes)
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
                used_azure      = True



                text_match = _mora_accuracy(expected_text, recognized_text) / 100.0
                if text_match < 0.85:
                    scale = 0.25 + 0.75 * text_match
                    accuracy_score    = int(accuracy_score * scale)
                    fluency_score     = int(fluency_score  * scale)

                    _azure_prosody_raw = int(pr.prosody_score * scale)
                else:
                    _azure_prosody_raw = int(pr.prosody_score)


                exp_pauses = _count_pauses(expected_text)
                rec_pauses = _count_pauses(recognized_text)
                if exp_pauses == 0:
                    rhythm_score = 100
                else:
                    pause_ratio  = 1.0 - abs(exp_pauses - rec_pauses) / max(exp_pauses, 1)
                    rhythm_score = max(int(pause_ratio * 100), 0)

                prosody_score = min(int(_azure_prosody_raw * 0.7 + rhythm_score * 0.3), 100)


                is_short = len(expected_text.strip()) < 15
                if is_short:
                    if accuracy_score >= 90:
                        fluency_score = max(fluency_score, 75)
                    elif accuracy_score >= 75:
                        fluency_score = max(fluency_score, 50)
            else:
                raise ValueError("Azure không nhận diện được giọng nói.")




        elif audio and GOOGLE_API_KEY and raw_audio_bytes:
            audio_bytes = raw_audio_bytes
            recognized_text, measured_pauses = await _google_stt(audio_bytes, audio.filename or "record.webm")
            accuracy_score, fluency_score, prosody_score, rhythm_score = _compute_shadowing_scores(
                expected_text, recognized_text
            )


            exp_pauses = _count_pauses(expected_text)
            if exp_pauses > 0:
                pause_ratio = 1.0 - abs(exp_pauses - measured_pauses) / max(exp_pauses, 1)
                rhythm_score = max(int(pause_ratio * 100), 0)

            error_word = _find_error_word(expected_text, recognized_text)




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




        words_analysis       = []
        mispronounced_words  = []
        error_types          = {"pronunciation": [], "prosody": [], "pitch_accent": [], "rhythm": []}

        if recognized_text and recognized_text != "(Không nhận được audio)":
            ai_eval = await _ai_full_evaluation(expected_text, recognized_text)
            if ai_eval:




                if not used_azure:
                    accuracy_score = ai_eval.get("accuracy", accuracy_score)
                    fluency_score  = ai_eval.get("fluency", fluency_score)
                    prosody_score  = ai_eval.get("prosody", prosody_score)
                    rhythm_score   = ai_eval.get("rhythm", rhythm_score)
                words_analysis      = ai_eval.get("words_analysis", [])
                mispronounced_words = ai_eval.get("mispronounced_words", [])
                error_types         = ai_eval.get("error_types", error_types)

        if not words_analysis:
            words_analysis = _fallback_word_analysis(expected_text, recognized_text)


        if mispronounced_words and not error_word:
            error_word = mispronounced_words[0]




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
            mispronounced_words=mispronounced_words,
        )




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