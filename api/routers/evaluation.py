import os
import re
import struct
import base64
import tempfile
import unicodedata
import httpx
from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from difflib import SequenceMatcher

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
# SECTION 1: Audio Pre-processing
# ==============================================================================

def _trim_silence(audio_bytes: bytes, threshold: int = 500, frame_size: int = 512) -> bytes:
    """
    Cắt bỏ khoảng lặng ở đầu và cuối audio (raw PCM 16-bit little-endian).
    Hoạt động trực tiếp trên bytes — không cần ffmpeg hay pydub.
    Với file có container header (WebM/OGG), sẽ thử cắt nhưng fallback an toàn.
    """
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
    return unicodedata.normalize("NFKC", text).strip().lower()


def _jp_mora_split(text: str) -> list[str]:
    """
    Chia văn bản tiếng Nhật thành danh sách mora (đơn vị âm tiết).
    Xử lý: ký tự thường nhỏ (っ, ぁ, ぃ...) gắn với mora trước; bỏ dấu câu.
    """
    SMALL = set("ぁぃぅぇぉっゃゅょァィゥェォッャュョ")
    PUNCT = set("。、！？!?.,・ー…「」『』【】〔〕（）()")
    text = unicodedata.normalize("NFKC", text)
    moras = []
    for ch in text:
        if ch in PUNCT or ch.isspace():
            continue
        if ch in SMALL and moras:
            moras[-1] += ch  # gắn vào mora trước
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
    rec_lower = _normalize(recognized)
    rec_clean = re.sub(r'[。、！？!?.,・ー…「」『』【】〔〕（）()]', '', rec_lower)
    for word in _normalize(expected).split():
        word_clean = re.sub(r'[。、！？!?.,・ー…「」『』【】〔〕（）()]', '', word)
        if word_clean and word_clean not in rec_clean and len(word_clean) > 1:
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

async def _ai_full_evaluation(expected_text: str, recognized_text: str) -> dict:
    """
    Dùng Gemini để đánh giá toàn diện: Điểm (accuracy, fluency, prosody, rhythm)
    và mảng words_analysis.
    """
    if not GEMINI_API_KEY:
        return {}
    
    prompt = (
        "Bạn là giám khảo chấm thi nói tiếng Nhật chuyên nghiệp. Học viên vừa đọc một đoạn văn Shadowing:\n"
        f"Câu gốc (chuẩn): {expected_text}\n"
        f"STT nghe được: {recognized_text}\n\n"
        "Đây là một đoạn văn dài. Hãy phân tích thật tỉ mỉ từng chi tiết (sai chữ, thiếu chữ, nhầm Hiragana). So sánh khớp thời gian và ngắt nghỉ tự nhiên.\n"
        "Yêu cầu trả về kết quả định dạng JSON chuẩn (Không bọc Markdown) với cấu trúc:\n"
        "{\n"
        "  \"accuracy\": 80,\n"
        "  \"fluency\": 75,\n"
        "  \"prosody\": 70,\n"
        "  \"rhythm\": 90,\n"
        "  \"words_analysis\": [\n"
        "    {\"text\": \"京都府\", \"is_correct\": true},\n"
        "    {\"text\": \"南丹市で\", \"is_correct\": false},\n"
        "    {\"text\": \"11歳の\", \"is_correct\": true}\n"
        "  ]\n"
        "}\n"
        "Quy tắc tuyệt đối (NẾU VI PHẠM THÌ HỆ THỐNG SẼ CRASH):\n"
        "1. words_analysis phải chia nhỏ đoạn văn thành các cụm từ rất ngắn (2-4 chữ) để bôi đỏ thật chuẩn xác.\n"
        "2. KHI GHÉP TOÀN BỘ CÁC TRƯỜNG 'text' TRONG MẢNG LẠI, NÓ PHẢI GIỐNG HỆT 100% CÂU GỐC ban đầu kể cả dấu chấm phẩy, không được sót bất kỳ kí tự nào.\n"
        "3. Nếu STT bị mất chữ hoặc có dấu hiệu học viên bỏ cách, đánh dấu is_correct là false cho CỤM ĐÓ."
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
            import json, re
            match = re.search(r"\{.*\}", text, re.DOTALL)
            if match:
                return json.loads(match.group())
    except Exception as e:
        print(f"[Gemini full eval error]: {e}")
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
        # ỨNG DỤNG BỘ ĐÁNH GIÁ AI TOÀN DIỆN NẾU ĐÃ CÓ TEXT (AZURE/GOOGLE)
        # ----------------------------------------------------------------
        words_analysis = []
        if recognized_text and recognized_text != "(Không nhận được audio)":
            ai_eval = await _ai_full_evaluation(expected_text, recognized_text)
            if ai_eval:
                accuracy_score = ai_eval.get("accuracy", accuracy_score)
                fluency_score  = ai_eval.get("fluency", fluency_score)
                prosody_score  = ai_eval.get("prosody", prosody_score)
                rhythm_score   = ai_eval.get("rhythm", rhythm_score)
                words_analysis = ai_eval.get("words_analysis", [])

        if not words_analysis:
            words_analysis = _fallback_word_analysis(expected_text, recognized_text)

        return {
            "success":        True,
            "mode":           "shadowing",
            "accuracy":       accuracy_score,
            "fluency":        fluency_score,
            "prosody":        prosody_score,
            "rhythm":         rhythm_score,
            "recognized_text": recognized_text,
            "error_word":     error_word,
            "words_analysis": words_analysis,
            "tip":            tip,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
