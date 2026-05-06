"""
jlpt_advanced_crawler.py — Thu thập N3/N2 từ NHK + Lọc chuẩn JLPT
=====================================================================
Chiến lược:
  N3: NHK Web Easy (bài đơn giản hóa, câu 15-25 từ)
  N2: NHK News đầy đủ (câu phức 25-40 từ) + pattern ngữ pháp N2
  
  Gemini AI:
    - Phân tích ngữ pháp mục tiêu JLPT theo từng level
    - Tạo chú thích, furigana, romaji, dịch Việt
    - Trích từ vựng trọng tâm kỳ thi JLPT

Cách chạy:
  cd api
  python scripts/jlpt_advanced_crawler.py --level N3 --limit 10 --source easy
  python scripts/jlpt_advanced_crawler.py --level N2 --limit 10 --source full
  python scripts/jlpt_advanced_crawler.py --level N2 --limit 5  --source both
"""

import os, sys, re, time, json, argparse
import httpx
from bs4 import BeautifulSoup
import xml.etree.ElementTree as ET
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from database import SessionLocal
from models.shadowing_topic import ShadowingTopic
from models.shadowing_segment import ShadowingSegment
from models.vocabulary import Vocabulary
from models.lesson import Lesson, LevelEnum

GEMINI_MODEL  = "gemini-2.0-flash"
AI_SLEEP      = 5
MAX_SENTENCES = {"N3": 4, "N2": 5}  # N2 nhiều câu hơn vì phức tạp hơn

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "ja-JP,ja;q=0.9,en;q=0.5",
}

# RSS feeds NHK
RSS_EASY = [
    "https://www3.nhk.or.jp/rss/news/cat0.xml",
    "https://www3.nhk.or.jp/rss/news/cat1.xml",
    "https://www3.nhk.or.jp/rss/news/cat2.xml",
]
RSS_FULL = [
    "https://www3.nhk.or.jp/rss/news/cat0.xml",
    "https://www3.nhk.or.jp/rss/news/cat6.xml",  # kinh tế
    "https://www3.nhk.or.jp/rss/news/cat5.xml",  # chính trị
]

# ── Ngữ pháp JLPT trọng tâm ─────────────────────────────────────────────────
JLPT_GRAMMAR = {
    "N3": {
        "patterns": [
            "～ている", "～てある", "～ておく", "～てしまう",
            "～ようだ", "～らしい", "～そうだ (appearance)",
            "～ながら", "～てから", "～前に",
            "～のに", "～ために", "～ように",
            "～てもいい", "～なければならない", "～はずだ",
        ],
        "vocab_level": "N3頻出語彙（1000語）",
        "sentence_len": "15-25 từ, cấu trúc vừa phải",
        "prompt_instruction": (
            "Câu văn N3: dùng ít nhất 1-2 pattern ngữ pháp N3 mỗi câu. "
            "Từ vựng trong phạm vi N3 (ví dụ: 増える、減る、変わる、続く、起きる). "
            "Câu không quá phức tạp, có thể hiểu được sau 2-3 lần đọc."
        ),
    },
    "N2": {
        "patterns": [
            "～にもかかわらず", "～にしては", "～に対して", "～において",
            "～によって", "～をはじめ", "～をめぐって", "～に伴い",
            "～に加えて", "～一方で", "～とともに", "～ばかりでなく",
            "～ことから", "～ことになっている", "～わけだ", "～からこそ",
        ],
        "vocab_level": "N2頻出語彙（2000語）+ 時事用語",
        "sentence_len": "25-40 từ, cấu trúc phức hợp",
        "prompt_instruction": (
            "Câu văn N2: phải xuất hiện ít nhất 1 pattern ngữ pháp N2. "
            "Từ vựng chính trị/kinh tế/xã hội thường xuất hiện trong JLPT N2. "
            "Câu dài, có mệnh đề phụ, cấu trúc phức tạp nhưng logic rõ ràng. "
            "Ưu tiên: 〜によると、〜に対して、〜において、〜一方で。"
        ),
    },
}

# Bộ lọc chất lượng N2 — từ khóa ngữ pháp phải xuất hiện
N2_GRAMMAR_KEYWORDS = [
    "にもかかわらず", "において", "に対して", "によって", "をはじめ",
    "一方", "に伴", "ことから", "ことになって", "からこそ",
    "にしては", "ばかりでなく", "とともに", "をめぐ",
]


# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Lấy danh sách bài từ RSS
# ─────────────────────────────────────────────────────────────────────────────
def fetch_rss_articles(limit: int, source: str) -> list[dict]:
    print(f"\n[1/4] Lấy danh sách bài NHK ({source})...")
    feeds = RSS_EASY if source == "easy" else RSS_FULL
    if source == "both":
        feeds = RSS_EASY + RSS_FULL

    articles, seen_ids = [], set()
    for rss_url in feeds:
        if len(articles) >= limit * 5:
            break
        try:
            r = httpx.get(rss_url, headers=HEADERS, follow_redirects=True, timeout=12)
            root  = ET.fromstring(r.text)
            items = root.findall(".//item")
            print(f"  {rss_url.split('/')[-1]} → {len(items)} bài")

            for item in items:
                link  = item.findtext("link", "")
                title = item.findtext("title", "NHK")
                m = re.search(r"/(k\d{14})(?:000)?\.html", link)
                if not m:
                    continue
                news_id = m.group(1)
                if news_id in seen_ids:
                    continue
                seen_ids.add(news_id)

                easy_url = f"https://www3.nhk.or.jp/news/easy/{news_id}/{news_id}.html"
                articles.append({
                    "news_id":  news_id,
                    "title":    title.strip(),
                    "rss_url":  link,
                    "easy_url": easy_url,
                })
        except Exception as e:
            print(f"  [WARN] RSS lỗi: {e}")

    print(f"  → Tổng {len(articles)} bài")
    return articles


# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Cào nội dung bài báo NHK
# ─────────────────────────────────────────────────────────────────────────────
def scrape_article(easy_url: str, rss_url: str, level: str) -> dict:
    max_sent = MAX_SENTENCES[level]
    min_len  = 10 if level == "N3" else 18  # N2 cần câu dài hơn

    for url in [easy_url, rss_url]:
        if not url:
            continue
        try:
            r = httpx.get(url, headers=HEADERS, follow_redirects=True, timeout=15)
            if r.status_code != 200:
                continue

            soup = BeautifulSoup(r.text, "html.parser")

            # OG image
            image_url = ""
            og = soup.find("meta", property="og:image")
            if og:
                image_url = og.get("content", "")

            # Xóa ruby rt/rp để giữ kanji gốc
            for tag in soup.find_all(["rt", "rp"]):
                tag.decompose()

            # Tìm body bài viết
            body = None
            for sel in [
                {"class": re.compile(r"article-main__body|article__body|p-article-body")},
                {"id":    re.compile(r"article-body|js-article-body|news_textbody")},
                "article", "main",
            ]:
                body = soup.find(True, attrs=sel) if isinstance(sel, dict) else soup.find(sel)
                if body:
                    break

            raw_text = body.get_text("", strip=True) if body else ""
            if not raw_text:
                paras = [
                    p.get_text(strip=True) for p in soup.find_all("p")
                    if re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", p.get_text())
                    and len(p.get_text(strip=True)) > 10
                ]
                raw_text = "。".join(paras)

            # Tách câu
            parts     = re.split(r"(?<=[。！？])", raw_text)
            sentences = [
                p.strip() for p in parts
                if len(p.strip()) > min_len
                and re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", p)
            ]

            if level == "N2":
                # Ưu tiên câu có ngữ pháp N2
                priority = [s for s in sentences
                            if any(kw in s for kw in N2_GRAMMAR_KEYWORDS)]
                rest     = [s for s in sentences if s not in priority]
                sentences = (priority + rest)[:max_sent]
            else:
                sentences = sentences[:max_sent]

            if sentences:
                return {"sentences": sentences, "image_url": image_url}

        except Exception as e:
            print(f"  [WARN] Lỗi cào {url}: {e}")

    return {"sentences": [], "image_url": ""}


# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Gemini phân tích — chuẩn JLPT
# ─────────────────────────────────────────────────────────────────────────────
def analyze_with_gemini(sentences: list[str], level: str) -> dict | None:
    g        = JLPT_GRAMMAR[level]
    patterns = "\n".join(f"  - {p}" for p in g["patterns"][:8])
    joined   = "\n".join(f"{i+1}. {s}" for i, s in enumerate(sentences))

    prompt = f"""Bạn là giáo viên luyện thi JLPT {level} chuyên nghiệp.

Phân tích đoạn tin tức NHK sau đây cho học viên luyện thi JLPT {level}:

{joined}

**YÊU CẦU PHÂN TÍCH:**
{g['prompt_instruction']}

**Ngữ pháp JLPT {level} cần nhận diện và chú thích:**
{patterns}

**Với mỗi câu, trả về:**
- "kanji": câu nguyên văn
- "furigana": HTML ruby furigana đầy đủ cho tất cả kanji
- "romaji": phiên âm Hepburn
- "vi": dịch tiếng Việt chính xác, tự nhiên
- "grammar_point": điểm ngữ pháp JLPT {level} xuất hiện trong câu (nếu có, ví dụ: "～において")

**Từ vựng:** Trích 6-8 từ vựng trọng tâm JLPT {level}, ưu tiên:
  - Từ tần suất cao trong đề thi JLPT
  - Từ có nhiều nghĩa, dễ nhầm lẫn  
  - Từ Hán tự phức hợp

Trả về JSON THUẦN (không markdown, không ```json):
{{"segments":[{{"kanji":"","furigana":"","romaji":"","vi":"","grammar_point":""}}],"vocabularies":[{{"word":"","reading":"","meaning":"","example":""}}]}}"""

    for attempt in range(3):
        try:
            time.sleep(AI_SLEEP)
            model = genai.GenerativeModel(GEMINI_MODEL)
            resp  = model.generate_content(prompt)
            raw   = resp.text.strip()

            raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.MULTILINE)
            raw = re.sub(r"\s*```$",           "", raw, flags=re.MULTILINE)
            raw = raw.strip()

            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                result = json.loads(match.group())
                if "segments" in result and len(result["segments"]) > 0:
                    # Log grammar points found
                    gp_list = [
                        s.get("grammar_point", "")
                        for s in result["segments"]
                        if s.get("grammar_point")
                    ]
                    if gp_list:
                        print(f"  ✓ Ngữ pháp nhận diện: {', '.join(gp_list)}")
                    return result

        except json.JSONDecodeError as e:
            print(f"  [WARN] JSON lỗi lần {attempt+1}: {e}")
        except Exception as e:
            print(f"  [WARN] Gemini lỗi lần {attempt+1}: {e}")
            time.sleep(10)

    return None


# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: Bộ lọc chất lượng JLPT
# ─────────────────────────────────────────────────────────────────────────────
def quality_check(sentences: list[str], level: str) -> tuple[bool, str]:
    """Trả về (pass, reason)"""
    if len(sentences) < 2:
        return False, "Quá ít câu"

    full_text = " ".join(sentences)

    if level == "N2":
        # Phải có ít nhất 1 pattern ngữ pháp N2
        found = [kw for kw in N2_GRAMMAR_KEYWORDS if kw in full_text]
        if not found:
            return False, "Không có ngữ pháp N2 đặc trưng"

        # Câu phải đủ dài (N2 cần câu phức tạp)
        avg_len = sum(len(s) for s in sentences) / len(sentences)
        if avg_len < 20:
            return False, f"Câu quá ngắn cho N2 (avg {avg_len:.0f} chữ)"

    if level == "N3":
        # N3: câu không quá ngắn, không quá phức tạp
        avg_len = sum(len(s) for s in sentences) / len(sentences)
        if avg_len < 12:
            return False, f"Câu quá ngắn cho N3 (avg {avg_len:.0f} chữ)"

    return True, "OK"


# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: Lưu DB
# ─────────────────────────────────────────────────────────────────────────────
def save_to_db(db, art: dict, level_enum: LevelEnum,
               sentences: list[str], ai_result: dict | None,
               order_index: int, level: str) -> tuple:
    title = f"[{level}] {art['title']} [{art['news_id']}]"

    # Lesson
    lesson = Lesson(
        level=level_enum,
        chapter_name=title[:120],
        order_index=order_index,
    )
    db.add(lesson)
    db.commit()
    db.refresh(lesson)

    # ShadowingTopic
    full_script = "。".join(sentences)
    topic = ShadowingTopic(
        title=title[:200],
        level=level_enum.value,
        lesson_id=lesson.id,
        image_url=art.get("image_url") or None,
        full_audio_url=None,
        full_script_ja=full_script,
        total_duration=float(len(sentences) * 14),
    )
    db.add(topic)
    db.commit()
    db.refresh(topic)

    # Segments
    segments_data = (ai_result or {}).get("segments", [])
    for idx, sent in enumerate(sentences, 1):
        seg = segments_data[idx - 1] if idx - 1 < len(segments_data) else {}
        # Thêm grammar_point vào furigana nếu có
        gp_note = ""
        if seg.get("grammar_point"):
            gp_note = f"\n📌 {seg['grammar_point']}"

        db.add(ShadowingSegment(
            topic_id      =topic.id,
            order_index   =idx,
            start_time    =float((idx - 1) * 14),
            end_time      =float(idx * 14),
            kanji_content =seg.get("kanji") or sent,
            furigana      =(seg.get("furigana") or sent) + gp_note,
            romaji        =seg.get("romaji", ""),
            sino_vietnamese=None,
            translation_vi =seg.get("vi", ""),
        ))

    # Vocabulary
    vocabs_data = (ai_result or {}).get("vocabularies", [])
    for v in vocabs_data:
        word    = v.get("word", "").strip()
        meaning = v.get("meaning", "").strip()
        if not word or not meaning:
            continue
        db.add(Vocabulary(
            lesson_id=lesson.id,
            topic_id =topic.id,
            word     =word,
            reading  =v.get("reading", ""),
            meaning  =meaning,
            example  =v.get("example", ""),
        ))

    db.commit()
    print(f"  [DB] Lesson #{lesson.id} | Topic #{topic.id} | "
          f"{len(sentences)} câu | {len(vocabs_data)} từ vựng")
    return lesson, topic


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
def run(level: str, limit: int, source: str):
    level_enum = LevelEnum[level]
    db         = SessionLocal()

    existing_count = db.query(Lesson).count()

    try:
        articles = fetch_rss_articles(limit=limit, source=source)
        saved, skipped, failed_qc = 0, 0, 0
        order = existing_count + 1

        print(f"\n{'='*65}")
        print(f"  JLPT {level} Crawler | Nguồn: {source} | Mục tiêu: {limit} bài")
        print(f"{'='*65}\n")

        for art in articles:
            if saved >= limit:
                break

            print(f"\n  [{saved+1}/{limit}] {art['title'][:65]}")

            # Kiểm tra trùng
            dup = db.query(ShadowingTopic).filter(
                ShadowingTopic.title.like(f"%{art['news_id']}%")
            ).first()
            if dup:
                print("  [SKIP] Đã có trong DB")
                skipped += 1
                continue

            # Cào bài
            result    = scrape_article(art["easy_url"], art["rss_url"], level)
            sentences = result["sentences"]
            art["image_url"] = result["image_url"]

            # Kiểm tra chất lượng
            ok, reason = quality_check(sentences, level)
            if not ok:
                print(f"  [QC-FAIL] {reason} → bỏ qua")
                failed_qc += 1
                continue

            print(f"  → {len(sentences)} câu đạt chất lượng | Gọi Gemini...")

            # Phân tích AI
            ai_result = analyze_with_gemini(sentences, level)
            if not ai_result:
                print("  [WARN] Gemini thất bại, lưu câu thô")

            # Lưu DB
            save_to_db(db, art, level_enum, sentences, ai_result, order, level)
            saved += 1
            order += 1
            existing_count += 1

            print(f"  → Tiến độ: {saved}/{limit} | Skip: {skipped} | QC-Fail: {failed_qc}")

        print(f"\n[DONE] {level}: {saved} lưu | {skipped} skip | {failed_qc} không đạt QC")

    except Exception as e:
        import traceback
        print(f"\n[ERROR] {e}")
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="JLPT Advanced Crawler N3/N2")
    parser.add_argument("--level",  required=True, choices=["N3", "N2"],
                        help="Cấp độ JLPT")
    parser.add_argument("--limit",  type=int, default=10,
                        help="Số bài cần lưu")
    parser.add_argument("--source", choices=["easy", "full", "both"],
                        default="easy",
                        help="easy=NHK Web Easy | full=NHK News đầy đủ | both=cả hai")
    args = parser.parse_args()

    # N2 nên dùng full hoặc both để có câu phức tạp hơn
    if args.level == "N2" and args.source == "easy":
        print("[HINT] N2 nên dùng --source full hoặc --source both để có ngữ pháp N2 phức tạp hơn.")

    print(f"[START] JLPT Advanced Crawler")
    print(f"  Level:  {args.level}")
    print(f"  Limit:  {args.limit}")
    print(f"  Source: {args.source}")
    run(level=args.level, limit=args.limit, source=args.source)
