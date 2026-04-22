"""
NHK Shadowing Crawler - Hybrid Strategy
=========================================
Strategy:
  1. Lay danh sach bai tu RSS (cat1 - xa hoi, cat2 - khoa hoc, cat3 - the thao)
     RSS tra ve URL dang: http://www3.nhk.or.jp/news/html/YYYYMMDD/kXXXXX.html
  2. Chuyen sang URL Web Easy: https://www3.nhk.or.jp/news/easy/kXXXXX/kXXXXX.html
  3. Cào noi dung bang httpx + BeautifulSoup (da doi duoc trang tinh)
  4. Gemini AI tao furigana, romaji, ban dich tieng Viet
  5. Luu vao DB: shadowing_topics + shadowing_segments + vocabularies

Chay:
  python scripts/nhk_shadowing_crawler.py
  python scripts/nhk_shadowing_crawler.py --limit 5 --level N2 --clear
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

# ─────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────
RSS_FEEDS = [
    "https://www3.nhk.or.jp/rss/news/cat1.xml",  # xa hoi (nhieu bai nhat)
    "https://www3.nhk.or.jp/rss/news/cat2.xml",  # khoa hoc
    "https://www3.nhk.or.jp/rss/news/cat3.xml",  # the thao
    "https://www3.nhk.or.jp/rss/news/cat0.xml",  # tong hop
]

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml",
    "Accept-Language": "ja-JP,ja;q=0.9",
}

AI_SLEEP     = 4   # giay delay giua cac call Gemini
MAX_SENTENCES = 3  # so cau toi da moi bai


# ─────────────────────────────────────────────
# STEP 1: Lay danh sach bai tu RSS
# ─────────────────────────────────────────────
def fetch_rss_articles(limit: int) -> list[dict]:
    print(f"[1/4] Lay danh sach bai tu RSS NHK...")
    articles = []
    seen_ids = set()

    for rss_url in RSS_FEEDS:
        if len(articles) >= limit:
            break
        try:
            r = httpx.get(rss_url, headers=HEADERS, follow_redirects=True, timeout=10)
            root = ET.fromstring(r.text)
            items = root.findall(".//item")
            print(f"  {rss_url} -> {len(items)} bai")

            for item in items:
                link = item.findtext("link", "")
                title = item.findtext("title", "NHK News")

                # Trich article_id tu URL RSS: .../html/YYYYMMDD/kXXXXXXXXXXXXXX000.html
                m = re.search(r"/(k\d{14})(?:000)?\.html", link)
                if not m:
                    continue
                news_id = m.group(1)

                if news_id in seen_ids:
                    continue
                seen_ids.add(news_id)

                # URL Web Easy chinh thuc
                easy_url = f"https://www3.nhk.or.jp/news/easy/{news_id}/{news_id}.html"

                articles.append({
                    "news_id": news_id,
                    "title": title.strip(),
                    "rss_url": link,
                    "easy_url": easy_url,
                })
                if len(articles) >= limit * 3:  # lay du de co the skip
                    break
        except Exception as e:
            print(f"  [WARN] RSS loi: {e}")

    print(f"  Tong: {len(articles)} bai tu RSS")
    return articles


# ─────────────────────────────────────────────
# STEP 2: Cao noi dung mot bai
# ─────────────────────────────────────────────
def scrape_article(url: str) -> dict:
    """Tra ve {"sentences": [...], "image_url": "..."}"""
    # Thu 2 URL: Web Easy va URL goc tu RSS
    urls_to_try = [url]

    for try_url in urls_to_try:
        try:
            r = httpx.get(try_url, headers=HEADERS, follow_redirects=True, timeout=12)
            if r.status_code != 200:
                continue

            soup = BeautifulSoup(r.text, "html.parser")

            # Lay image
            image_url = ""
            og_img = soup.find("meta", property="og:image")
            if og_img:
                image_url = og_img.get("content", "")

            # Chon noi dung theo thu tu uu tien
            body = None
            for selector in [
                {"class_": re.compile(r"article-main__body|article__body|content--detail-main|news-detail")},
                {"id": re.compile(r"article-body|js-article-body")},
                {"tag": "article"},
                {"tag": "main"},
            ]:
                if "class_" in selector:
                    body = soup.find(True, attrs={"class": selector["class_"]})
                elif "id" in selector:
                    body = soup.find(True, attrs={"id": selector["id"]})
                elif "tag" in selector:
                    body = soup.find(selector["tag"])
                if body:
                    break

            if not body:
                # Fallback: lay tat ca <p> co tieng Nhat
                paragraphs = [
                    p.get_text(strip=True)
                    for p in soup.find_all("p")
                    if re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", p.get_text())
                    and len(p.get_text(strip=True)) > 10
                ]
                if paragraphs:
                    combined = "。".join(paragraphs)
                    body_text = combined
                else:
                    continue
            else:
                # Xoa ruby annotation (giu kanji goc)
                for rt in body.find_all("rt"): rt.decompose()
                for rp in body.find_all("rp"): rp.decompose()
                body_text = body.get_text(separator="", strip=True)

            # Tach cau theo dau cau Nhat
            parts = re.split(r"(?<=[。！？])", body_text)
            sentences = []
            for part in parts:
                part = part.strip()
                # Phai co it nhat 1 ky tu Nhat va > 8 ky tu
                if (len(part) > 8
                        and re.search(r"[\u3040-\u30ff\u4e00-\u9fff]", part)):
                    sentences.append(part)

            if sentences:
                return {"sentences": sentences[:MAX_SENTENCES], "image_url": image_url}

        except Exception as e:
            print(f"  [WARN] Loi cao {try_url}: {e}")

    return {"sentences": [], "image_url": ""}


# ─────────────────────────────────────────────
# STEP 3: Gemini phan tich
# ─────────────────────────────────────────────
def analyze_with_gemini(sentences: list[str], level: str) -> dict | None:
    joined = "\n".join(f"{i+1}. {s}" for i, s in enumerate(sentences))
    prompt = f"""Phan tich doan tin tuc tieng Nhat theo trinh do JLPT {level}:

{joined}

Yeu cau:
1. Moi cau tra ve: kanji (nguyen van), furigana (co <ruby>chu<rt>furigana</rt></ruby>), romaji (Hepburn), vi (dich tieng Viet tu nhien).
2. Trich 3-5 tu vung JLPT {level} quan trong: word, reading (hiragana), meaning (tieng Viet).

Tra ve JSON THUAN (khong markdown, khong chu thich them):
{{"segments":[{{"kanji":"","furigana":"","romaji":"","vi":""}}],"vocabularies":[{{"word":"","reading":"","meaning":""}}]}}"""

    for attempt in range(3):
        try:
            time.sleep(AI_SLEEP)
            model = genai.GenerativeModel("gemini-2.5-flash")
            resp = model.generate_content(prompt)
            raw = resp.text.strip().strip("`").strip()
            if raw.lower().startswith("json"):
                raw = raw[4:].strip()
            # Tim object JSON dau tien
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                result = json.loads(match.group())
                if "segments" in result:
                    return result
        except json.JSONDecodeError as e:
            print(f"  [WARN] JSON parse loi lan {attempt+1}: {e}")
        except Exception as e:
            print(f"  [WARN] Gemini loi lan {attempt+1}: {e}")
    return None


# ─────────────────────────────────────────────
# STEP 4: Luu DB
# ─────────────────────────────────────────────
def save_to_db(db, lesson_id, title, level_enum, image_url, sentences, ai_result):
    full_script = "。".join(sentences) + "。"
    topic = ShadowingTopic(
        title=title[:100],
        level=level_enum.value,
        lesson_id=lesson_id,
        image_url=image_url or None,
        full_audio_url=None,
        full_script_ja=full_script,
        total_duration=float(len(sentences) * 10),
    )
    db.add(topic)
    db.commit()
    db.refresh(topic)

    segments_data = ai_result.get("segments", []) if ai_result else []
    if segments_data:
        for idx, seg in enumerate(segments_data, 1):
            raw_sent = sentences[idx - 1] if idx <= len(sentences) else ""
            db.add(ShadowingSegment(
                topic_id=topic.id,
                order_index=idx,
                start_time=float((idx - 1) * 10),
                end_time=float(idx * 10),
                kanji_content=seg.get("kanji") or raw_sent,
                furigana=seg.get("furigana", ""),
                romaji=seg.get("romaji", ""),
                sino_vietnamese=None,
                translation_vi=seg.get("vi", ""),
            ))
    else:
        print("  [WARN] AI that bai, luu segment tho.")
        for idx, sent in enumerate(sentences, 1):
            db.add(ShadowingSegment(
                topic_id=topic.id, order_index=idx,
                start_time=float((idx-1)*10), end_time=float(idx*10),
                kanji_content=sent, furigana=sent,
                romaji="(chua co)", translation_vi="(chua dich)",
            ))

    vocabs_data = ai_result.get("vocabularies", []) if ai_result else []
    for v in vocabs_data:
        if v.get("word") and v.get("meaning"):
            db.add(Vocabulary(
                topic_id=topic.id,
                word=v["word"], reading=v.get("reading", ""), meaning=v["meaning"],
            ))

    db.commit()
    print(f"  [OK] Topic #{topic.id}: {title[:60]}")
    return topic


# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
def run(limit: int = 10, level: str = "N3", clear_old: bool = False):
    db = SessionLocal()
    level_enum = LevelEnum[level]

    try:
        if clear_old:
            old = db.query(ShadowingTopic).filter(ShadowingTopic.level == level_enum.value).all()
            for t in old: db.delete(t)
            db.commit()
            print(f"[!] Da xoa {len(old)} topic level {level} cu.")

        # Lay hoac tao Lesson
        lesson = db.query(Lesson).filter(Lesson.level == level_enum).first()
        if not lesson:
            order = {"N5":1,"N4":2,"N3":3,"N2":4,"N1":5}.get(level, 99)
            lesson = Lesson(level=level_enum, chapter_name=f"NHK Web Easy ({level})", order_index=order)
            db.add(lesson); db.commit(); db.refresh(lesson)
            print(f"  Tao Lesson moi: id={lesson.id}")
        else:
            print(f"  Dung Lesson co san: id={lesson.id}")

        # Lay danh sach bai tu RSS
        articles = fetch_rss_articles(limit=limit)
        print(f"\n[2/4] Bat dau xu ly tung bai (limit={limit})...")

        saved = 0
        skipped = 0

        for art in articles:
            if saved >= limit:
                break

            print(f"\n[3/4] Bai {saved+1}/{limit}: {art['title'][:60]}")

            # Cao noi dung tu Web Easy
            result = scrape_article(art["easy_url"])
            sentences = result["sentences"]
            image_url = result["image_url"]

            if len(sentences) < 1:
                # Thu URL goc (non-Easy)
                result2 = scrape_article(art["rss_url"])
                sentences = result2["sentences"]
                image_url = result2.get("image_url", "")

            if len(sentences) < 1:
                print("  [SKIP] Bai trong sau 2 lan thu, bo qua.")
                skipped += 1
                continue

            print(f"  -> Cap duoc {len(sentences)} cau, goi Gemini AI...")
            ai_result = analyze_with_gemini(sentences, level)

            title = f"[{level}] {art['title']}"
            save_to_db(db, lesson.id, title, level_enum, image_url, sentences, ai_result)
            saved += 1
            print(f"  -> Tien do: {saved}/{limit} | Bo qua: {skipped}")

        print(f"\n[4/4] Hoan tat! Da luu {saved} bai, bo qua {skipped} bai.")

    except Exception as e:
        import traceback
        print(f"\n[ERROR] Loi he thong: {e}")
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="NHK Shadowing Crawler")
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--level", type=str, default="N3", choices=["N5","N4","N3","N2","N1"])
    parser.add_argument("--clear", action="store_true", help="Xoa topic level nay truoc khi cao")
    args = parser.parse_args()
    run(limit=args.limit, level=args.level, clear_old=args.clear)
