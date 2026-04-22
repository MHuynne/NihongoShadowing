"""
tts.py — Text-to-Speech endpoint cho chức năng Shadowing Sample.

Shadowing flow:
  1. Client gọi POST /tts/sample  { text, speed }
  2. Server trả về audio/mpeg (MP3 bytes) để client phát
  3. Người dùng nghe xong → bắt đầu nhại theo → gửi lên /evaluate/shadowing

Fallback chain (ưu tiên chất lượng giọng):
  Priority 1 — Azure Neural TTS  (cần AZURE_SPEECH_KEY)  → giọng Nanami, rất tự nhiên
  Priority 2 — Google Cloud TTS  (cần GOOGLE_API_KEY)    → Wavenet ja-JP-Wavenet-B
  Priority 3 — gTTS              (free, không cần key)   → Google Translate TTS
"""

import os
import io
import base64
import hashlib
import tempfile
import httpx
from pathlib import Path
from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel, Field

router = APIRouter(prefix="/tts", tags=["Text-to-Speech (Shadowing Sample)"])

# ── API Keys ─────────────────────────────────────────────────────────────────
AZURE_SPEECH_KEY    = os.getenv("AZURE_SPEECH_KEY", "")
AZURE_SPEECH_REGION = os.getenv("AZURE_SPEECH_REGION", "eastasia")
GOOGLE_API_KEY      = os.getenv("GOOGLE_API_KEY", "")

# ── Cache thư mục (tránh gọi API lại với cùng text+speed) ────────────────────
_CACHE_DIR = Path(tempfile.gettempdir()) / "koe_tts_cache"
_CACHE_DIR.mkdir(parents=True, exist_ok=True)


# ─────────────────────────────────────────────────────────────────────────────
# Request / Response Models
# ─────────────────────────────────────────────────────────────────────────────

class TTSRequest(BaseModel):
    text: str = Field(..., description="Văn bản tiếng Nhật cần đọc (tối đa 500 ký tự)")
    speed: float = Field(
        default=0.85,
        ge=0.5,
        le=1.5,
        description=(
            "Tốc độ đọc. 0.85 = chậm nhẹ (khuyến nghị cho Shadowing cơ bản), "
            "1.0 = tốc độ tự nhiên, 1.2 = tốc độ nhanh (Shadowing nâng cao)."
        ),
    )
    voice_gender: str = Field(
        default="female",
        description="Giới tính giọng đọc: 'female' hoặc 'male'",
    )


# ─────────────────────────────────────────────────────────────────────────────
# Cache helper
# ─────────────────────────────────────────────────────────────────────────────

def _cache_key(text: str, speed: float, gender: str) -> Path:
    digest = hashlib.md5(f"{text}|{speed}|{gender}".encode()).hexdigest()
    return _CACHE_DIR / f"{digest}.mp3"


# ─────────────────────────────────────────────────────────────────────────────
# Priority 1: Azure Neural TTS
# ─────────────────────────────────────────────────────────────────────────────

async def _azure_tts(text: str, speed: float, gender: str) -> bytes:
    """
    Azure Cognitive Services TTS — chất lượng Neural, giọng Nhật rất tự nhiên.
    Voices: ja-JP-NanamiNeural (female) | ja-JP-KeitaNeural (male)
    """
    voice = "ja-JP-NanamiNeural" if gender == "female" else "ja-JP-KeitaNeural"
    # Azure dùng rate theo percentage: 0.85 → "-15%"
    rate_pct = int((speed - 1.0) * 100)
    rate_str = f"{rate_pct:+d}%"

    ssml = f"""<speak version='1.0' xml:lang='ja-JP'>
  <voice name='{voice}'>
    <prosody rate='{rate_str}'>{text}</prosody>
  </voice>
</speak>"""

    url = f"https://{AZURE_SPEECH_REGION}.tts.speech.microsoft.com/cognitiveservices/v1"
    headers = {
        "Ocp-Apim-Subscription-Key": AZURE_SPEECH_KEY,
        "Content-Type": "application/ssml+xml",
        "X-Microsoft-OutputFormat": "audio-16khz-128kbitrate-mono-mp3",
    }

    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.post(url, content=ssml.encode("utf-8"), headers=headers)

    if resp.status_code == 200:
        print(f"[TTS] Azure OK — voice={voice}, rate={rate_str}, len={len(resp.content)}")
        return resp.content
    else:
        raise RuntimeError(f"Azure TTS HTTP {resp.status_code}: {resp.text[:200]}")



async def _google_tts(text: str, speed: float, gender: str) -> bytes:
    """
    Google Cloud TTS — Wavenet voices, chất lượng cao.
    Female: ja-JP-Wavenet-A | Male: ja-JP-Wavenet-C
    (Wavenet-B/D cũng female/male nhưng âm sắc khác)
    """
    voice_name = "ja-JP-Wavenet-A" if gender == "female" else "ja-JP-Wavenet-C"
    ssml_gender = "FEMALE" if gender == "female" else "MALE"

    payload = {
        "input": {"text": text},
        "voice": {
            "languageCode": "ja-JP",
            "name": voice_name,
            "ssmlGender": ssml_gender,
        },
        "audioConfig": {
            "audioEncoding": "MP3",
            "speakingRate": speed,          # 0.25–4.0, 1.0 = tự nhiên
            "pitch": 0.0,                   # không thay đổi pitch
            "sampleRateHertz": 24000,
        },
    }

    url = "https://texttospeech.googleapis.com/v1/text:synthesize"
    params = {"key": GOOGLE_API_KEY}

    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.post(url, json=payload, params=params)

    if resp.status_code == 200:
        data = resp.json()
        audio_bytes = base64.b64decode(data["audioContent"])
        print(f"[TTS] Google Wavenet OK — voice={voice_name}, speed={speed}, len={len(audio_bytes)}")
        return audio_bytes
    else:
        raise RuntimeError(f"Google TTS HTTP {resp.status_code}: {resp.text[:200]}")



def _gtts_tts(text: str, speed: float) -> bytes:
    """
    gTTS — dùng Google Translate TTS endpoint (miễn phí, không cần key).
    Chỉ hỗ trợ slow=True/False, không điều chỉnh được speed chi tiết.
    """
    try:
        from gtts import gTTS
    except ImportError:
        raise RuntimeError("gTTS chưa được cài. Chạy: pip install gtts")

    slow = speed < 0.9  # gTTS chỉ có slow mode
    tts = gTTS(text=text, lang="ja", slow=slow)
    buf = io.BytesIO()
    tts.write_to_fp(buf)
    buf.seek(0)
    audio_bytes = buf.read()
    print(f"[TTS] gTTS OK — slow={slow}, len={len(audio_bytes)}")
    return audio_bytes



@router.post(
    "/sample",
    response_class=Response,
    responses={
        200: {
            "content": {"audio/mpeg": {}},
            "description": "MP3 audio bytes của câu mẫu tiếng Nhật",
        }
    },
    summary="Tạo audio mẫu để Shadowing",
    description=(
        "Nhận văn bản tiếng Nhật → trả về file MP3 để người dùng nghe và nhại theo.\n\n"
        "**Shadowing speed guide:**\n"
        "- `0.75` — Chậm (người mới bắt đầu)\n"
        "- `0.85` — Chậm nhẹ (khuyến nghị)\n"
        "- `1.0`  — Tốc độ tự nhiên\n"
        "- `1.2`  — Nhanh (luyện nâng cao)\n\n"
        "Kết quả được cache theo `(text, speed, gender)` để tránh gọi API lặp lại."
    ),
)
async def get_shadowing_sample(req: TTSRequest):
    if len(req.text.strip()) == 0:
        raise HTTPException(status_code=400, detail="text không được để trống.")
    if len(req.text) > 500:
        raise HTTPException(status_code=400, detail="text tối đa 500 ký tự.")

    cache_path = _cache_key(req.text, req.speed, req.voice_gender)
    if cache_path.exists():
        print(f"[TTS] Cache HIT → {cache_path.name}")
        return Response(
            content=cache_path.read_bytes(),
            media_type="audio/mpeg",
            headers={"X-TTS-Source": "cache"},
        )

    audio_bytes: bytes | None = None
    source = "unknown"
    errors = []

    # Priority 1: Azure
    if AZURE_SPEECH_KEY:
        try:
            audio_bytes = await _azure_tts(req.text, req.speed, req.voice_gender)
            source = "azure"
        except Exception as e:
            errors.append(f"Azure: {e}")
            print(f"[TTS] Azure failed: {e}")

    # Priority 2: Google Wavenet
    if audio_bytes is None and GOOGLE_API_KEY:
        try:
            audio_bytes = await _google_tts(req.text, req.speed, req.voice_gender)
            source = "google"
        except Exception as e:
            errors.append(f"Google: {e}")
            print(f"[TTS] Google failed: {e}")

    # Priority 3: gTTS (free)
    if audio_bytes is None:
        try:
            audio_bytes = _gtts_tts(req.text, req.speed)
            source = "gtts"
        except Exception as e:
            errors.append(f"gTTS: {e}")
            print(f"[TTS] gTTS failed: {e}")

    if audio_bytes is None:
        raise HTTPException(
            status_code=503,
            detail=f"Không thể tạo audio mẫu. Lỗi: {'; '.join(errors)}",
        )

    try:
        cache_path.write_bytes(audio_bytes)
        print(f"[TTS] Cached → {cache_path.name} ({source})")
    except Exception:
        pass  # Cache lỗi không crash app

    return Response(
        content=audio_bytes,
        media_type="audio/mpeg",
        headers={"X-TTS-Source": source},
    )



@router.get("/voices", summary="Danh sách giọng đọc tiếng Nhật")
def list_voices():
    """
    Trả về danh sách giọng đọc tiếng Nhật được hỗ trợ theo từng provider.
    Dùng để hiển thị UI cho người dùng chọn giọng.
    """
    return {
        "voices": [
            # ── Azure Neural (chất lượng cao nhất) ──
            {
                "id": "azure_nanami",
                "name": "Nanami (Nữ - Azure Neural)",
                "gender": "female",
                "provider": "azure",
                "quality": "neural",
                "available": bool(AZURE_SPEECH_KEY),
                "description": "Giọng nữ tự nhiên chuẩn Tokyo. Phù hợp nhất cho Shadowing.",
                "sample_text": "おはようございます。今日もがんばりましょう！",
            },
            {
                "id": "azure_keita",
                "name": "Keita (Nam - Azure Neural)",
                "gender": "male",
                "provider": "azure",
                "quality": "neural",
                "available": bool(AZURE_SPEECH_KEY),
                "description": "Giọng nam trầm ấm, tốc độ phát âm chuẩn Nhật hiện đại.",
                "sample_text": "日本語の発音を練習しましょう。",
            },
            # ── Google Wavenet ──
            {
                "id": "google_wavenet_a",
                "name": "Wavenet-A (Nữ - Google)",
                "gender": "female",
                "provider": "google",
                "quality": "wavenet",
                "available": bool(GOOGLE_API_KEY),
                "description": "Giọng nữ Google Wavenet, tự nhiên, phát âm rõ ràng.",
                "sample_text": "おはようございます。今日もがんばりましょう！",
            },
            {
                "id": "google_wavenet_c",
                "name": "Wavenet-C (Nam - Google)",
                "gender": "male",
                "provider": "google",
                "quality": "wavenet",
                "available": bool(GOOGLE_API_KEY),
                "description": "Giọng nam Google Wavenet, tông trung, phù hợp luyện nghe.",
                "sample_text": "日本語の発音を練習しましょう。",
            },
            # ── gTTS (free fallback) ──
            {
                "id": "gtts_female",
                "name": "Google Translate (Nữ - Miễn phí)",
                "gender": "female",
                "provider": "gtts",
                "quality": "standard",
                "available": True,  # Luôn có sẵn nếu cài gtts
                "description": "Giọng Google Translate. Miễn phí, không cần API key.",
                "sample_text": "おはようございます。",
            },
        ],
        "recommended_speeds": [
            {"value": 0.75, "label": "0.75× — Chậm (người mới)"},
            {"value": 0.85, "label": "0.85× — Chậm nhẹ (khuyến nghị)"},
            {"value": 1.0,  "label": "1.0× — Tự nhiên"},
            {"value": 1.2,  "label": "1.2× — Nâng cao"},
        ],
    }
