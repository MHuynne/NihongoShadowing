"""
NHK Shadowing Crawler v2 - Dành cho N3 và N2
=============================================
Cải tiến so với v1:
  - Mỗi bài báo NHK → 1 Lesson riêng (không gom chung)
  - Lưu vocabularies vào cả lesson_id và topic_id
  - Model Gemini đúng: gemini-1.5-flash
  - Thêm `example` cho vocabulary từ câu trong bài
  - Hỗ trợ chạy N3 + N2 cùng lúc

Chạy:
  cd api
  python scripts/nhk_crawler_v2.py --limit 5 --levels N3,N2
  python scripts/nhk_crawler_v2.py --limit 10 --levels N3
  python scripts/nhk_crawler_v2.py --limit 10 --levels N2
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

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────
RSS_FEEDS = [
    "https://www3.nhk.or.jp/rss/news/cat0.xml",  # tổng hợp (nhiều nhất)
    "https://www3.nhk.or.jp/rss/news/cat1.xml",  # xã hội
    "https://www3.nhk.or.jp/rss/news/cat2.xml",  # khoa học
    "https://www3.nhk.or.jp/rss/news/cat3.xml",  # thể thao
]

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "ja-JP,ja;q=0.9,en;q=0.5",
}

AI_SLEEP      = 5    # giây delay giữa các call Gemini
MAX_SENTENCES = 4    # số câu tối đa mỗi bài (shadowing segments)
GEMINI_MODEL  = "gemini-2.0-flash"


# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Lấy danh sách bài từ RSS
# ─────────────────────────────────────────────────────────────────────────────
def fetch_rss_articles(limit: int) -> list[dict]:
    print(f"\n[1/4] Lấy danh sách bài từ RSS NHK...")
    articles = []
    seen_ids = set()

    for rss_url in RSS_FEEDS:
        if len(articles) >= limit * 4:  # lấy dư để bù skip
            break
        try:
            r = httpx.get(rss_url, headers=HEADERS, follow_redirects=True, timeout=12)
            root = ET.fromstring(r.text)
            items = root.findall(".//item")
            print(f"  {rss_url} → {len(items)} bài")

            for item in items:
                link  = item.findtext("link", "")
                title = item.findtext("title", "NHK News")

                # Trích news_id: .../html/YYYYMMDD/kXXXXXXXXXXXXXX000.html
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
            print(f"  [WARN] RSS lỗi {rss_url}: {e}")

    print(f"  Tổng cộng: {len(articles)} bài từ RSS")
    return articles


# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Cào nội dung 1 bài NHK Web Easy
# ─────────────────────────────────────────────────────────────────────────────
def scrape_article(easy_url: str, fallback_url: str = "") -> dict:
    """Trả về {"sentences": [...], "image_url": "..."}"""
    for url in filter(None, [easy_url, fallback_url]):
        try:
            r = httpx.get(url, headers=HEADERS, follow_redirects=True, timeout=15)
            if r.status_code != 200:
                continue

            soup = BeautifulSoup(r.text, "html.parser")

            # Lấy ảnh OG
            image_url = ""
            og = soup.find("meta", property="og:image")
            if og:
                image_url = og.get("content", "")

            # Xóa ruby (rt/rp) để giữ kanji gốc
            for tag in soup.find_all(["rt", "rp"]):
                tag.decompose()

            # Tìm vùng nội dung chính
            body = None
            for sel in [
                {"class": re.compile(r"article-main__body|article__body|content--detail-main|p-article-body")},
                {"id": re.compile(r"article-body|js-article-body|news_textbody")},
                "article",
                "main",
            ]:
                if isinstance(sel, dict):
                    body = soup.find(True, attrs=sel)
                else:
                    body = soup.find(sel)
                if body:
                    break

            if body:
                raw_text = body.get_text(separator="", strip=True)
            else:
                # Fallback: gom các đoạn có tiếng Nhật
                paras = [
                    p.get_text(strip=True)
                    for p in soup.find_all("p")
                    if re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", p.get_text())
                    and len(p.get_text(strip=True)) > 10
                ]
                if not paras:
                    continue
                raw_text = "。".join(paras)

            # Tách câu theo dấu câu Nhật
            parts = re.split(r"(?<=[。！？])", raw_text)
            sentences = [
                p.strip() for p in parts
                if len(p.strip()) > 8
                and re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", p)
            ]

            if sentences:
                return {"sentences": sentences[:MAX_SENTENCES], "image_url": image_url}

        except Exception as e:
            print(f"  [WARN] Lỗi cào {url}: {e}")

    return {"sentences": [], "image_url": ""}


# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Gemini phân tích ngôn ngữ
# ─────────────────────────────────────────────────────────────────────────────
def analyze_with_gemini(sentences: list[str], level: str) -> dict | None:
    joined = "\n".join(f"{i+1}. {s}" for i, s in enumerate(sentences))
    prompt = f"""Bạn là giáo viên dạy tiếng Nhật chuyên nghiệp. Hãy phân tích đoạn tin tức NHK dưới đây dành cho học viên trình độ JLPT {level}.

{joined}

Yêu cầu:
1. Với mỗi câu, trả về:
   - "kanji": câu nguyên văn (giữ nguyên kanji)
   - "furigana": câu với furigana dạng HTML <ruby>漢字<rt>ふりがな</rt></ruby>
   - "romaji": phiên âm Hepburn đầy đủ
   - "vi": bản dịch tiếng Việt tự nhiên, chính xác

2. Trích 4-6 từ vựng quan trọng đặc trưng trình độ JLPT {level}:
   - "word": từ vựng (kanji/kana)
   - "reading": đọc bằng hiragana
   - "meaning": nghĩa tiếng Việt ngắn gọn
   - "example": câu ví dụ (lấy từ bài hoặc tự tạo)

Trả về JSON THUẦN (không có markdown, không có ```json):
{{"segments":[{{"kanji":"","furigana":"","romaji":"","vi":""}}],"vocabularies":[{{"word":"","reading":"","meaning":"","example":""}}]}}"""

    for attempt in range(3):
        try:
            time.sleep(AI_SLEEP)
            model = genai.GenerativeModel(GEMINI_MODEL)
            resp  = model.generate_content(prompt)
            raw   = resp.text.strip()

            # Làm sạch markdown
            raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.MULTILINE)
            raw = re.sub(r"\s*```$", "", raw, flags=re.MULTILINE)
            raw = raw.strip()

            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                result = json.loads(match.group())
                if "segments" in result and len(result["segments"]) > 0:
                    return result
        except json.JSONDecodeError as e:
            print(f"  [WARN] JSON parse lỗi lần {attempt+1}: {e}")
        except Exception as e:
            print(f"  [WARN] Gemini lỗi lần {attempt+1}: {e}")
            time.sleep(10)

    return None


# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: Lưu vào DB
# ─────────────────────────────────────────────────────────────────────────────
def save_to_db(
    db,
    title: str,
    level_enum: LevelEnum,
    image_url: str,
    sentences: list[str],
    ai_result: dict | None,
    order_index: int,
) -> tuple:
    """
    Tạo: 1 Lesson + 1 ShadowingTopic + N ShadowingSegment + M Vocabulary
    Trả về (lesson, topic)
    """
    # ── Tạo Lesson riêng cho mỗi bài ──────────────────────────────────────
    lesson = Lesson(
        level=level_enum,
        chapter_name=title[:120],
        order_index=order_index,
    )
    db.add(lesson)
    db.commit()
    db.refresh(lesson)

    # ── Tạo ShadowingTopic ─────────────────────────────────────────────────
    full_script = "。".join(sentences) + ("。" if not sentences[-1].endswith("。") else "")
    topic = ShadowingTopic(
        title=title[:200],
        level=level_enum.value,
        lesson_id=lesson.id,
        image_url=image_url or None,
        full_audio_url=None,
        full_script_ja=full_script,
        total_duration=float(len(sentences) * 12),
    )
    db.add(topic)
    db.commit()
    db.refresh(topic)

    # ── Tạo ShadowingSegment ───────────────────────────────────────────────
    segments_data = (ai_result or {}).get("segments", [])
    for idx, sent in enumerate(sentences, 1):
        seg = segments_data[idx - 1] if idx - 1 < len(segments_data) else {}
        db.add(ShadowingSegment(
            topic_id=topic.id,
            order_index=idx,
            start_time=float((idx - 1) * 12),
            end_time=float(idx * 12),
            kanji_content=seg.get("kanji") or sent,
            furigana=seg.get("furigana") or sent,
            romaji=seg.get("romaji", "(chưa có)"),
            sino_vietnamese=None,
            translation_vi=seg.get("vi", "(chưa dịch)"),
        ))

    # ── Tạo Vocabulary (kèm cả lesson_id và topic_id) ─────────────────────
    vocabs_data = (ai_result or {}).get("vocabularies", [])
    for v in vocabs_data:
        word    = v.get("word", "").strip()
        meaning = v.get("meaning", "").strip()
        if not word or not meaning:
            continue
        db.add(Vocabulary(
            lesson_id=lesson.id,          # ← Hiển thị trong Flashcard
            topic_id=topic.id,            # ← Liên kết với shadowing
            word=word,
            reading=v.get("reading", ""),
            meaning=meaning,
            example=v.get("example", ""),
        ))

    db.commit()
    print(f"  [OK] Lesson #{lesson.id} | Topic #{topic.id}: {title[:70]}")
    print(f"       → {len(sentences)} segment, {len(vocabs_data)} từ vựng")
    return lesson, topic


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
def run(limit: int, levels: list[str]):
    db = SessionLocal()

    # Đếm lesson hiện có để tính order_index liên tục
    existing_count = db.query(Lesson).count()

    try:
        articles = fetch_rss_articles(limit=limit * len(levels))

        for level_str in levels:
            level_enum = LevelEnum[level_str]
            print(f"\n{'='*60}")
            print(f"  Bắt đầu cào level {level_str} — mục tiêu: {limit} bài")
            print(f"{'='*60}")

            saved   = 0
            skipped = 0
            order   = existing_count + 1

            for art in articles:
                if saved >= limit:
                    break

                print(f"\n  Bài {saved+1}/{limit}: {art['title'][:65]}")

                # Kiểm tra trùng tiêu đề
                dup = db.query(ShadowingTopic).filter(
                    ShadowingTopic.title.like(f"%{art['news_id']}%")
                ).first()
                if dup:
                    print("  [SKIP] Đã tồn tại trong DB, bỏ qua.")
                    skipped += 1
                    continue

                # Cào nội dung
                result    = scrape_article(art["easy_url"], art["rss_url"])
                sentences = result["sentences"]
                image_url = result["image_url"]

                if len(sentences) < 2:
                    print("  [SKIP] Quá ít câu, bỏ qua.")
                    skipped += 1
                    continue

                print(f"  → Cào được {len(sentences)} câu | Gọi Gemini AI...")

                ai_result = analyze_with_gemini(sentences, level_str)
                if not ai_result:
                    print("  [WARN] AI thất bại, lưu câu thô.")

                title = f"[{level_str}] {art['title']} [{art['news_id']}]"
                save_to_db(
                    db=db,
                    title=title,
                    level_enum=level_enum,
                    image_url=image_url,
                    sentences=sentences,
                    ai_result=ai_result,
                    order_index=order,
                )
                saved += 1
                order += 1
                existing_count += 1
                print(f"  → Tiến độ: {saved}/{limit} | Bỏ qua: {skipped}")

            print(f"\n[{level_str}] Hoàn tất: {saved} bài lưu, {skipped} bị bỏ qua.")

    except Exception as e:
        import traceback
        print(f"\n[ERROR] Lỗi hệ thống: {e}")
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="NHK Crawler v2 (N3+N2)")
    parser.add_argument("--limit",  type=int,   default=5,     help="Số bài mỗi level")
    parser.add_argument("--levels", type=str,   default="N3,N2", help="Level cách nhau bởi dấu phẩy: N3,N2")
    args = parser.parse_args()

    level_list = [l.strip().upper() for l in args.levels.split(",")]
    valid = {"N5", "N4", "N3", "N2", "N1"}
    level_list = [l for l in level_list if l in valid]

    if not level_list:
        print("[ERROR] Không có level hợp lệ. Dùng: N3,N2")
        sys.exit(1)

    print(f"[START] Crawler NHK v2")
    print(f"  Levels: {', '.join(level_list)}")
    print(f"  Limit:  {args.limit} bài/level")
    print(f"  Model:  {GEMINI_MODEL}")
    run(limit=args.limit, levels=level_list)
