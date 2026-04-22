import os
import sys
import xml.etree.ElementTree as ET
import httpx
from bs4 import BeautifulSoup
import re
import time
import random
import json
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import SessionLocal
from models.lesson import Lesson, LevelEnum
from models.shadowing_topic import ShadowingTopic
from models.shadowing_segment import ShadowingSegment
from models.vocabulary import Vocabulary

# Kho tàng 25 bài N5 siêu xịn chuẩn chỉnh (Mỗi bài có 2 câu đơn giản)
N5_DATABASE = [
    {
        "title": "Chào hỏi mỗi sáng", 
        "sentences": [
            {"kanji": "おはようございます。", "furigana": "おはようございます。", "romaji": "Ohayou gozaimasu.", "vi": "Chào buổi sáng."},
            {"kanji": "今日もいい天気ですね。", "furigana": "<ruby>今日<rt>きょう</rt></ruby>もいい<ruby>天気<rt>てんき</rt></ruby>ですね。", "romaji": "Kyou mo ii tenki desu ne.", "vi": "Hôm nay thời tiết đẹp nhỉ."}
        ]
    },
    {
        "title": "Hỏi thăm sức khỏe",
        "sentences": [
            {"kanji": "お元気ですか。", "furigana": "お<ruby>元気<rt>げんき</rt></ruby>ですか。", "romaji": "Ogenki desu ka.", "vi": "Bạn có khỏe không?"},
            {"kanji": "はい、元気です。", "furigana": "はい、<ruby>元気<rt>げんき</rt></ruby>です。", "romaji": "Hai, genki desu.", "vi": "Vâng, tôi khỏe."}
        ]
    },
    {
        "title": "Đến Nhật Bản",
        "sentences": [
            {"kanji": "私はベトナムから来ました。", "furigana": "<ruby>私<rt>わたし</rt></ruby>はベトナムから<ruby>来<rt>き</rt></ruby>ました。", "romaji": "Watashi wa Betonamu kara kimashita.", "vi": "Tôi đến từ Việt Nam."},
            {"kanji": "日本は初めてです。", "furigana": "<ruby>日本<rt>にほん</rt></ruby>は<ruby>初<rt>はじ</rt></ruby>めてです。", "romaji": "Nihon wa hajimete desu.", "vi": "Đây là lần đầu tôi đến Nhật Bản."}
        ]
    },
    {
        "title": "Đi nhà hàng",
        "sentences": [
            {"kanji": "メニューをお願いします。", "furigana": "メニューをお<ruby>願<rt>ねが</rt></ruby>いします。", "romaji": "Menyuu o onegaishimasu.", "vi": "Cho tôi xin thực đơn."},
            {"kanji": "お水もください。", "furigana": "お<ruby>水<rt>みず</rt></ruby>もください。", "romaji": "Omizu mo kudasai.", "vi": "Hãy cho tôi thêm nước nhé."}
        ]
    },
    {
        "title": "Mua sắm",
        "sentences": [
            {"kanji": "これはいくらですか。", "furigana": "これはいくらですか。", "romaji": "Kore wa ikura desu ka.", "vi": "Cái này giá bao nhiêu?"},
            {"kanji": "高いですね。", "furigana": "<ruby>高<rt>たか</rt></ruby>いですね。", "romaji": "Takai desu ne.", "vi": "Đắt quá nhỉ."}
        ]
    }
]

# Tương tự cho N4
N4_DATABASE = [
    {
        "title": "Dọn nhà đi làm",
        "sentences": [
            {"kanji": "明日は早く起きなければなりません。", "furigana": "<ruby>明日<rt>あした</rt></ruby>は<ruby>早<rt>はや</rt></ruby>く<ruby>起<rt>お</rt></ruby>きなければなりません。", "romaji": "Ashita wa hayaku okinakereba narimasen.", "vi": "Ngày mai tôi phải thức dậy sớm."},
            {"kanji": "会議があるので、遅れないようにします。", "furigana": "<ruby>会議<rt>かいぎ</rt></ruby>があるので、<ruby>遅<rt>おく</rt></ruby>れないようにします。", "romaji": "Kaigi ga aru node, okurenai you ni shimasu.", "vi": "Vì có cuộc họp nên tôi sẽ cố không đến trễ."}
        ]
    },
    {
        "title": "Bệnh viện",
        "sentences": [
            {"kanji": "最近、少し熱があります。", "furigana": "<ruby>最近<rt>さいきん</rt></ruby>、<ruby>少<rt>すこ</rt></ruby>し<ruby>熱<rt>ねつ</rt></ruby>があります。", "romaji": "Saikin, sukoshi netsu ga arimasu.", "vi": "Dạo này tôi hơi sốt môt chút."},
            {"kanji": "病院へ行ったほうがいいですよ。", "furigana": "<ruby>病院<rt>びょういん</rt></ruby>へ<ruby>行<rt>い</rt></ruby>ったほうがいいですよ。", "romaji": "Byouin e itta hou ga ii desu yo.", "vi": "Bạn nên đi bệnh viện khám thử xem."}
        ]
    }
]

RSS_FEEDS = ["https://www3.nhk.or.jp/rss/news/cat0.xml", "https://www3.nhk.or.jp/rss/news/cat1.xml"]

def extract_vocab_with_ai(text, level, count=5):
    prompt = f"""
Trích xuất tối đa {count} từ vựng quan trọng (danh từ, động từ, tính từ) phù hợp với trình độ JLPT {level} từ đoạn văn tiếng Nhật sau.
Text:
{text}

Trả về DUY NHẤT một mảng JSON (không bọc trong markdown) theo định dạng:
[
  {{"word": "từ vựng (kanji nếu có)", "reading": "cách đọc hiragana", "meaning": "nghĩa tiếng Việt ngắn gọn"}}
]
"""
    try:
        time.sleep(3) # Cân đối để tránh nghẽn API quota cho phiên bản miễn phí
        model = genai.GenerativeModel('gemini-2.5-flash')
        response = model.generate_content(prompt)
        raw_text = response.text.strip()
        if raw_text.startswith("```json"): raw_text = raw_text[7:]
        if raw_text.startswith("```"): raw_text = raw_text[3:]
        if raw_text.endswith("```"): raw_text = raw_text[:-3]
        return json.loads(raw_text.strip())
    except Exception as e:
        print(f"Lỗi khi gọi Gemini AI: {e}")
        return []

def analyze_shadowing_nhk_with_ai(sentences, level):
    text_content = "\n".join(sentences)
    prompt = f"""
Bạn là chuyên gia tiếng Nhật JLPT {level}. Hãy xử lý bài đọc tin tức tiếng Nhật sau:
{text_content}

Nhiệm vụ:
1. Đối với MỖI câu trong văn bản, tạo một bản dịch tiếng Việt, romaji, và kanji có chứa HTML ruby tag furigana thật chuẩn và hợp lý.
2. Trích xuất tối đa 5 từ vựng quan trọng nhất từ đoạn trên.

Trả về DUY NHẤT một object JSON nguyên chất KHÔNG bọc trong markdown tick (```) với định dạng chính xác sau:
{{
  "sentences": [
    {{"kanji": "câu gốc", "furigana": "câu có chứa ruby tag (VD: <ruby>漢字<rt>かんじ</rt></ruby>)", "romaji": "romaji", "vi": "tiếng việt"}}
  ],
  "vocabularies": [
    {{"word": "từ", "reading": "cách đọc", "meaning": "nghĩa"}}
  ]
}}
"""
    try:
        time.sleep(3)
        model = genai.GenerativeModel('gemini-2.5-flash')
        response = model.generate_content(prompt)
        raw_text = response.text.strip(' \n`')
        if raw_text.startswith("json"): raw_text = raw_text[4:]
        return json.loads(raw_text.strip())
    except Exception as e:
        print(f"Lỗi phân tích Shadowing AI: {e}")
        return None

def fetch_rss_items(url):
    print(f"Đang cào RSS: {url}")
    try:
        with httpx.Client(timeout=10.0, follow_redirects=True) as client:
            response = client.get(url, headers={'User-Agent': 'Mozilla/5.0'})
            response.raise_for_status()
            root = ET.fromstring(response.text)
            return root.findall('.//item')
    except Exception:
        return []

def scrape_article_body(url):
    try:
        with httpx.Client(timeout=8.0, follow_redirects=True) as client:
            res = client.get(url, headers={'User-Agent': 'Mozilla/5.0'})
            soup = BeautifulSoup(res.text, 'html.parser')
            detail = soup.find('section', class_='content--detail-main')
            if detail:
                txt = detail.get_text(separator=' ', strip=True)
                return [s + "。" for s in txt.split("。") if len(s.strip()) > 5]
            return []
    except Exception:
        return []

def scrape_nhk_news():
    print("Bắt đầu sinh dữ liệu siêu chuẩn xác cho App Shadowing bằng Gemini AI...")
    db = SessionLocal()
    
    try:
        # Xóa SẠCH toàn bộ data cũ
        print("Đang dọn dẹp sạch Database cũ...")
        db.query(ShadowingSegment).delete()
        db.query(Vocabulary).delete()
        db.query(ShadowingTopic).delete()
        db.query(Lesson).delete()
        db.commit()

        # Tạo Lesson Mới
        lessons = {}
        for lvl in [LevelEnum.N5, LevelEnum.N4, LevelEnum.N3, LevelEnum.N2]:
            chapter_name = f"Minna No Nihongo ({lvl.value})" if lvl in [LevelEnum.N5, LevelEnum.N4] else f"NHK News ({lvl.value})"
            lesson = Lesson(level=lvl, chapter_name=chapter_name, order_index=90 + list(LevelEnum).index(lvl))
            db.add(lesson)
            db.commit()
            db.refresh(lesson)
            lessons[lvl] = lesson

        print("\\n--- Bắt đầu nhúng dữ liệu N5 & N4 (Tin chuẩn Minna) ---")
        
        for i in range(25):
            # N5
            n5_data = N5_DATABASE[i % len(N5_DATABASE)]
            topic_n5 = ShadowingTopic(
                title=f"[N5] {n5_data['title']} - Bài {i+1}",
                level=LevelEnum.N5.value, lesson_id=lessons[LevelEnum.N5].id,
                image_url=f"https://picsum.photos/seed/n5_{i}/400/250", full_audio_url="",
                full_script_ja="".join([s['kanji'] for s in n5_data['sentences']]), total_duration=10.0
            )
            db.add(topic_n5)
            db.commit(); db.refresh(topic_n5)
            
            for o, sent in enumerate(n5_data['sentences'], 1):
                db.add(ShadowingSegment(topic_id=topic_n5.id, order_index=o, kanji_content=sent['kanji'], furigana=sent['furigana'], romaji=sent['romaji'], translation_vi=sent['vi']))
            
            ai_vocabs_n5 = extract_vocab_with_ai(topic_n5.full_script_ja, "N5", count=4)
            for v in ai_vocabs_n5:
                if 'word' in v and 'reading' in v and 'meaning' in v:
                    db.add(Vocabulary(lesson_id=lessons[LevelEnum.N5].id, topic_id=topic_n5.id, word=v['word'], reading=v['reading'], meaning=v['meaning']))
            db.commit()

            # N4
            n4_data = N4_DATABASE[i % len(N4_DATABASE)]
            topic_n4 = ShadowingTopic(
                title=f"[N4] {n4_data['title']} - Bài {i+1}",
                level=LevelEnum.N4.value, lesson_id=lessons[LevelEnum.N4].id,
                image_url=f"https://picsum.photos/seed/n4_{i}/400/250", full_audio_url="",
                full_script_ja="".join([s['kanji'] for s in n4_data['sentences']]), total_duration=15.0
            )
            db.add(topic_n4)
            db.commit(); db.refresh(topic_n4)

            for o, sent in enumerate(n4_data['sentences'], 1):
                db.add(ShadowingSegment(topic_id=topic_n4.id, order_index=o, kanji_content=sent['kanji'], furigana=sent['furigana'], romaji=sent['romaji'], translation_vi=sent['vi']))
            
            ai_vocabs_n4 = extract_vocab_with_ai(topic_n4.full_script_ja, "N4", count=4)
            for v in ai_vocabs_n4:
                if 'word' in v and 'reading' in v and 'meaning' in v:
                    db.add(Vocabulary(lesson_id=lessons[LevelEnum.N4].id, topic_id=topic_n4.id, word=v['word'], reading=v['reading'], meaning=v['meaning']))
            db.commit()


        print("\\n--- Bắt đầu Cào Dữ Liệu N3 & N2 bằng API NHK & GEMINI ---")
        items = fetch_rss_items(RSS_FEEDS[0]) + fetch_rss_items(RSS_FEEDS[1])
        unique_items = {i.find('link').text: i for i in items if i.find('link') is not None}
        nhk_list = list(unique_items.values())[:30] # Limit to 30 to respect AI quotas
        
        saved_count = 0
        lvl_counter = 0
        for item in nhk_list:
            lvl = LevelEnum.N3 if lvl_counter < 15 else LevelEnum.N2
            
            link = item.find('link').text
            title = item.find('title').text
            sentences = scrape_article_body(link)
            if len(sentences) < 2: continue
            
            sentences = sentences[:2] if lvl == LevelEnum.N3 else sentences[:3]
            
            ai_result = analyze_shadowing_nhk_with_ai(sentences, lvl.value)
            
            topic = ShadowingTopic(
                title=f"[{lvl.value}] {title[:30]}...",
                level=lvl.value,
                lesson_id=lessons[lvl].id,
                image_url=f"https://picsum.photos/seed/nhk_{saved_count}/400/250", 
                full_audio_url="",
                full_script_ja="".join(sentences),
                total_duration=20.0
            )
            db.add(topic)
            db.commit()
            db.refresh(topic)
            
            if ai_result and 'sentences' in ai_result:
                for o, sent_obj in enumerate(ai_result['sentences'], 1):
                    db.add(ShadowingSegment(
                        topic_id=topic.id, order_index=o, 
                        kanji_content=sent_obj.get('kanji', sentences[o-1] if o <= len(sentences) else ''),
                        furigana=sent_obj.get('furigana', ''), 
                        romaji=sent_obj.get('romaji', ''), 
                        translation_vi=sent_obj.get('vi', '')
                    ))
            else:
                for o, sent in enumerate(sentences, 1):
                    db.add(ShadowingSegment(topic_id=topic.id, order_index=o, kanji_content=sent, furigana=sent, romaji="Auto-generated blocked", translation_vi="Auto-generated blocked"))
            
            if ai_result and 'vocabularies' in ai_result:
                for v in ai_result['vocabularies']:
                    if 'word' in v and 'reading' in v and 'meaning' in v:
                        db.add(Vocabulary(
                            lesson_id=lessons[lvl].id,
                            topic_id=topic.id,
                            word=v['word'],
                            reading=v['reading'],
                            meaning=v['meaning']
                        ))
            
            db.commit()
            saved_count += 1
            lvl_counter += 1

        print("\\nVừa cập nhật toàn bộ DB bằng hệ thống AI NHK-Gemini Sinh Tự Động!")

    except Exception as e:
        print(f"Có lỗi hệ thống: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    scrape_nhk_news()
