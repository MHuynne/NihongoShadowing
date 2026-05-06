"""
Dictionary Router — Từ điển Nhật - Việt.

Fix: Dùng 1 httpx.AsyncClient duy nhất cho toàn bộ request.
     Dịch tuần tự (không song song) để tránh quá tải Google Translate.
     Giới hạn 5 entry + 3 sense đầu để tăng tốc độ phản hồi.

Endpoints:
  GET /dictionary/search?q=<keyword>
  GET /dictionary/kanji/{char}
"""

import httpx
from fastapi import APIRouter, HTTPException, Query

router = APIRouter(prefix="/dictionary", tags=["Dictionary"])

JISHO_BASE  = "https://jisho.org/api/v1/search/words"
KANJI_BASE  = "https://kanjiapi.dev/v1/kanji"
GTRANS_URL  = "https://translate.googleapis.com/translate_a/single"

# Client-level limits để tránh quá tải
MAX_ENTRIES      = 8   # số entry trả về tối đa
MAX_SENSES       = 4   # số nghĩa mỗi entry
TRANSLATE_TIMEOUT = 6.0
JISHO_TIMEOUT    = 12.0
KANJI_TIMEOUT    = 10.0


# ─────────────────────────────────────────────────────────────────────────────
# Map từ loại → tiếng Việt
# ─────────────────────────────────────────────────────────────────────────────
_POS_MAP: dict[str, str] = {
    "Noun":                                "Danh từ",
    "Suru verb":                           "Động từ する",
    "Godan verb":                          "Động từ nhóm 1",
    "Godan verb with ru ending":           "Động từ nhóm 1 (ru)",
    "Ichidan verb":                        "Động từ nhóm 2",
    "Transitive verb":                     "Ngoại động từ",
    "Intransitive verb":                   "Nội động từ",
    "i-adjective":                         "Tính từ い",
    "na-adjective":                        "Tính từ な",
    "Adverb":                              "Phó từ",
    "Adverb taking the 'to' particle":     "Phó từ (と)",
    "Conjunction":                         "Liên từ",
    "Particle":                            "Trợ từ",
    "Prefix":                              "Tiền tố",
    "Suffix":                              "Hậu tố",
    "Expression":                          "Thành ngữ",
    "Interjection":                        "Thán từ",
    "Pronoun":                             "Đại từ",
    "Numeric":                             "Số từ",
    "Counter":                             "Từ đếm",
    "Wikipedia definition":                "Wikipedia",
    "Place":                               "Địa danh",
    "Usually written using kana alone":    "Thường viết bằng kana",
}


def _pos_vi(pos_en: str) -> str:
    return _POS_MAP.get(pos_en, pos_en)


# ─────────────────────────────────────────────────────────────────────────────
# Google Translate — dùng client được truyền vào, KHÔNG tạo mới
# ─────────────────────────────────────────────────────────────────────────────
async def _translate_batch(client: httpx.AsyncClient, texts: list[str]) -> list[str]:
    """
    Dịch một list string sang tiếng Việt bằng cách gộp thành 1 request duy nhất.
    Dùng separator '||' để tách kết quả.
    Nếu thất bại → trả về texts gốc.
    """
    if not texts:
        return []

    separator = " || "
    joined    = separator.join(t.strip() for t in texts if t.strip())
    if not joined:
        return texts

    try:
        resp = await client.get(
            GTRANS_URL,
            params={
                "client": "gtx",
                "sl":     "en",
                "tl":     "vi",
                "dt":     "t",
                "q":      joined,
            },
            headers={"User-Agent": "Mozilla/5.0"},
            timeout=TRANSLATE_TIMEOUT,
        )
        if resp.status_code == 200:
            data        = resp.json()
            raw_vi      = "".join(part[0] for part in data[0] if part[0])
            parts       = raw_vi.split("||")
            result      = [p.strip() for p in parts]
            # Đảm bảo số phần tử khớp
            while len(result) < len(texts):
                result.append(texts[len(result)])
            return result[: len(texts)]
    except Exception:
        pass

    return texts  # fallback: giữ nguyên tiếng Anh


# ─────────────────────────────────────────────────────────────────────────────
# Parse Jisho + dịch — TUẦN TỰ, 1 client duy nhất
# ─────────────────────────────────────────────────────────────────────────────
async def _parse_and_translate(raw: dict, client: httpx.AsyncClient) -> list[dict]:
    """
    Xử lý từng entry Jisho tuần tự với 1 client chung.
    Gộp tất cả chuỗi cần dịch thành ít request nhất có thể.
    """
    items   = raw.get("data", [])[:MAX_ENTRIES]
    results = []

    for item in items:
        japanese  = item.get("japanese", [])
        word      = japanese[0].get("word",    "") if japanese else ""
        reading   = japanese[0].get("reading", "") if japanese else ""
        jlpt      = item.get("jlpt",       [])
        is_common = item.get("is_common",   False)

        senses_raw = item.get("senses", [])[:MAX_SENSES]

        # ── Gộp TẤT CẢ definitions của entry thành 1 batch dịch ──────────
        all_en_defs: list[str] = []
        sense_en_ranges: list[tuple[int, int]] = []  # (start_idx, end_idx)

        for sense in senses_raw:
            en_defs = sense.get("english_definitions", [])
            start   = len(all_en_defs)
            all_en_defs.extend(en_defs)
            sense_en_ranges.append((start, len(all_en_defs)))

        # Dịch toàn bộ 1 lần
        all_vi_defs = await _translate_batch(client, all_en_defs)

        # ── Build senses output ───────────────────────────────────────────
        senses_out = []
        for i, sense in enumerate(senses_raw):
            pos_en  = sense.get("parts_of_speech", [])
            en_defs = sense.get("english_definitions", [])

            start, end = sense_en_ranges[i]
            vi_defs    = all_vi_defs[start:end]

            senses_out.append({
                "parts_of_speech_vi":  [_pos_vi(p) for p in pos_en],
                "parts_of_speech_en":  pos_en,
                "vi_definitions":       vi_defs,
                "english_definitions":  en_defs,
                "tags":                 sense.get("tags",         []),
                "info":                 sense.get("info",         []),
                "see_also":             sense.get("see_also",     []),
                "restrictions":         sense.get("restrictions", []),
            })

        results.append({
            "word":      word,
            "reading":   reading,
            "is_common": is_common,
            "jlpt":      jlpt,
            "senses":    senses_out,
            "japanese":  japanese,
        })

    return results


# ─────────────────────────────────────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/search")
async def search_word(
    q:    str = Query(..., min_length=1, description="Từ khóa tìm kiếm"),
    page: int = Query(1, ge=1),
):
    """
    Tìm kiếm từ điển Nhật - Việt.
    Hỗ trợ: Kanji, Hiragana, Katakana, Romaji, tiếng Anh.
    Nghĩa tự động dịch sang tiếng Việt.
    """
    # Dùng 1 client chung cho cả Jisho lẫn Google Translate
    async with httpx.AsyncClient(timeout=JISHO_TIMEOUT) as client:
        try:
            resp = await client.get(
                JISHO_BASE,
                params={"keyword": q, "page": page},
                headers={"User-Agent": "TokyoNihongoApp/1.0"},
            )
        except httpx.RequestError as exc:
            raise HTTPException(status_code=503,
                                detail=f"Không kết nối được Jisho: {exc}")

        if resp.status_code != 200:
            raise HTTPException(status_code=502,
                                detail=f"Jisho API lỗi {resp.status_code}")

        raw     = resp.json()
        entries = await _parse_and_translate(raw, client)

    return {
        "keyword": q,
        "page":    page,
        "total":   len(raw.get("data", [])),
        "entries": entries,
    }


@router.get("/kanji/{character}")
async def get_kanji_detail(character: str):
    """
    Chi tiết 1 chữ Kanji: âm on/kun, nghĩa Việt, số nét, JLPT.
    """
    if len(character) != 1:
        raise HTTPException(status_code=400, detail="Chỉ tra được 1 ký tự Kanji.")

    async with httpx.AsyncClient(timeout=KANJI_TIMEOUT) as client:
        try:
            resp = await client.get(f"{KANJI_BASE}/{character}")
        except httpx.RequestError as exc:
            raise HTTPException(status_code=503,
                                detail=f"Lỗi kết nối KanjiAPI: {exc}")

        if resp.status_code == 404:
            raise HTTPException(status_code=404,
                                detail=f"Không tìm thấy kanji '{character}'")
        if resp.status_code != 200:
            raise HTTPException(status_code=502, detail="KanjiAPI lỗi")

        data        = resp.json()
        meanings_en = data.get("meanings", [])
        meanings_vi = await _translate_batch(client, meanings_en)

    return {
        "kanji":        data.get("kanji"),
        "grade":        data.get("grade"),
        "stroke_count": data.get("stroke_count"),
        "meanings_en":  meanings_en,
        "meanings_vi":  meanings_vi,
        "kun_readings": data.get("kun_readings", []),
        "on_readings":  data.get("on_readings",  []),
        "jlpt":         data.get("jlpt"),
        "unicode":      data.get("unicode"),
    }
