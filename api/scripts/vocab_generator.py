"""
vocab_generator.py — Tạo tối đa 40 từ vựng có Kanji cho mỗi Shadowing Topic
==============================================================================
Script này:
  1. Lấy tất cả ShadowingTopic từ DB (hoặc lọc theo level/topic_id)
  2. Với mỗi topic: gom nội dung từ ShadowingSegment
  3. Gọi Gemini AI → tạo tối đa 40 từ vựng CÓ KANJI liên quan đến nội dung
  4. Lưu vào bảng vocabularies (gắn lesson_id + topic_id)
  5. Bỏ qua nếu topic đã có >= 30 từ vựng (đã đủ)

Cách chạy:
  cd api

  # Tạo từ vựng cho TẤT CẢ topic chưa đủ từ
  python scripts/vocab_generator.py

  # Chỉ tạo cho 1 topic cụ thể
  python scripts/vocab_generator.py --topic-id 5

  # Chỉ tạo cho level N3
  python scripts/vocab_generator.py --level N3

  # Ghi đè (xóa từ vựng cũ, tạo lại)
  python scripts/vocab_generator.py --topic-id 5 --overwrite

  # Chỉ xem, không ghi DB (dry-run)
  python scripts/vocab_generator.py --level N5 --dry-run
"""

import os, sys, re, time, json, argparse
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from database import SessionLocal
from models.shadowing_topic   import ShadowingTopic
from models.shadowing_segment import ShadowingSegment
from models.vocabulary        import Vocabulary
from models.lesson            import LevelEnum

GEMINI_MODEL  = "gemini-2.0-flash"
AI_SLEEP      = 4        # giây delay giữa các call
MAX_VOCAB     = 40       # số từ tối đa mỗi topic
SKIP_THRESHOLD = 30      # bỏ qua topic đã có >= số từ này


# ─────────────────────────────────────────────────────────────────────────────
# Gemini: Tạo danh sách từ vựng có Kanji
# ─────────────────────────────────────────────────────────────────────────────

def _level_from_topic(topic: ShadowingTopic) -> str:
    """Lấy level string từ topic."""
    if topic.level:
        val = topic.level if isinstance(topic.level, str) else topic.level.value
        return val  # "N5", "N4", "N3", "N2"
    if topic.lesson and topic.lesson.level:
        return topic.lesson.level.value
    # Đoán từ title
    for lv in ["N1", "N2", "N3", "N4", "N5"]:
        if lv in (topic.title or ""):
            return lv
    return "N3"


def _build_content(topic: ShadowingTopic, segments: list) -> str:
    """Gom nội dung bài học từ các segment."""
    parts = []
    if topic.title:
        parts.append(f"Tiêu đề: {topic.title}")
    if topic.full_script_ja:
        parts.append(f"Nội dung: {topic.full_script_ja[:800]}")
    for seg in segments[:6]:
        if seg.kanji_content:
            parts.append(seg.kanji_content[:200])
    return "\n".join(parts)


JLPT_KANJI_INSTRUCTIONS = {
    "N5": (
        "Từ vựng N5 cơ bản: danh từ thông dụng, động từ nhóm 1&2 đơn giản, "
        "tính từ い/な cơ bản. TẤT CẢ phải có chữ Kanji (không dùng từ kana thuần)."
        "Ví dụ: 学校、先生、食べる、飲む、大きい、きれい→dùng 綺麗."
    ),
    "N4": (
        "Từ vựng N4: danh từ phức hợp, động từ ghép, tính từ biểu cảm, từ Hán-Việt. "
        "TẤT CẢ phải có ít nhất 1 chữ Kanji. "
        "Ví dụ: 準備、経験、運動する、正直な、予定."
    ),
    "N3": (
        "Từ vựng N3: từ thời sự, học thuật, cảm xúc phức tạp, collocation. "
        "TẤT CẢ phải có chữ Kanji. Ưu tiên từ 2-3 kanji ghép. "
        "Ví dụ: 影響、可能性、状況、判断する、環境."
    ),
    "N2": (
        "Từ vựng N2: từ chuyên ngành nhẹ, kinh tế, xã hội, luật, văn học. "
        "TẤT CẢ phải có chữ Kanji, ưu tiên yoji-jukugo và kango (Hán tự phức hợp). "
        "Ví dụ: 維持、促進、一方的、抱負、過程、貢献."
    ),
}


def generate_vocab_with_gemini(
    topic: ShadowingTopic,
    segments: list,
    existing_words: set[str],
    level: str,
) -> list[dict] | None:
    """
    Gọi Gemini tạo tối đa 40 từ vựng có Kanji dựa trên nội dung topic.
    Trả về list[{"word", "reading", "meaning", "example"}] hoặc None nếu thất bại.
    """
    content     = _build_content(topic, segments)
    instruction = JLPT_KANJI_INSTRUCTIONS.get(level, JLPT_KANJI_INSTRUCTIONS["N3"])
    skip_hint   = ""
    if existing_words:
        sample = "、".join(list(existing_words)[:10])
        skip_hint = f"\nĐã có các từ: {sample} — KHÔNG lặp lại các từ này."

    prompt = f"""Bạn là giáo viên chuyên luyện thi JLPT {level}.

Dựa trên nội dung bài học sau:
---
{content}
---

Hãy tạo ĐÚNG {MAX_VOCAB} từ vựng tiếng Nhật CÓ KANJI phù hợp với trình độ JLPT {level}.

**Quy tắc bắt buộc:**
{instruction}
- Mỗi từ PHẢI chứa ít nhất 1 chữ Kanji (漢字) — không chấp nhận từ kana thuần như: です、します、ます
- Ưu tiên từ liên quan đến chủ đề bài học
- Bổ sung từ vựng phổ biến JLPT {level} nếu chưa đủ 40{skip_hint}

**Mỗi từ vựng gồm:**
- "word": từ viết bằng Kanji (ví dụ: 食べ物、学習、経済的)
- "reading": cách đọc bằng Hiragana đầy đủ (ví dụ: たべもの、がくしゅう、けいざいてき)
- "meaning": nghĩa tiếng Việt ngắn gọn (ví dụ: đồ ăn, học tập, về mặt kinh tế)
- "example": câu ví dụ ngắn có chứa từ đó (tiếng Nhật, 8-18 chữ)

Trả về JSON THUẦN, không markdown, không ```json:
{{"vocabularies":[{{"word":"","reading":"","meaning":"","example":""}}]}}

Phải trả về đúng {MAX_VOCAB} từ."""

    for attempt in range(3):
        try:
            time.sleep(AI_SLEEP)
            model  = genai.GenerativeModel(GEMINI_MODEL)
            resp   = model.generate_content(prompt)
            raw    = resp.text.strip()

            # Làm sạch markdown
            raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.MULTILINE)
            raw = re.sub(r"\s*```$",           "", raw, flags=re.MULTILINE)
            raw = raw.strip()

            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if not match:
                print(f"  [WARN] Không parse được JSON lần {attempt+1}")
                continue

            result = json.loads(match.group())
            vocabs = result.get("vocabularies", [])

            # Lọc từ BẮT BUỘC có Kanji
            filtered = []
            for v in vocabs:
                word = v.get("word", "").strip()
                if not word:
                    continue
                # Kiểm tra có chữ Kanji không (Unicode range U+4E00–U+9FFF)
                has_kanji = bool(re.search(r'[\u4e00-\u9fff]', word))
                if not has_kanji:
                    continue
                # Bỏ qua từ đã tồn tại
                if word in existing_words:
                    continue
                filtered.append(v)

            if len(filtered) < 5:
                print(f"  [WARN] Quá ít từ có Kanji ({len(filtered)}), thử lại...")
                continue

            print(f"  ✓ Tạo được {len(filtered)} từ có Kanji "
                  f"(yêu cầu {MAX_VOCAB}, lọc {len(vocabs) - len(filtered)} từ kana)")
            return filtered[:MAX_VOCAB]

        except json.JSONDecodeError as e:
            print(f"  [WARN] JSON lỗi lần {attempt+1}: {e}")
        except Exception as e:
            print(f"  [WARN] Gemini lỗi lần {attempt+1}: {e}")
            time.sleep(10)

    return None


# ─────────────────────────────────────────────────────────────────────────────
# Lưu từ vựng vào DB
# ─────────────────────────────────────────────────────────────────────────────

def save_vocabs(db, topic: ShadowingTopic, vocab_list: list[dict]) -> int:
    """Lưu danh sách từ vựng vào DB. Trả về số từ đã lưu."""
    saved = 0
    for v in vocab_list:
        word    = v.get("word",    "").strip()
        reading = v.get("reading", "").strip()
        meaning = v.get("meaning", "").strip()
        example = v.get("example", "").strip()

        if not word or not meaning:
            continue

        db.add(Vocabulary(
            lesson_id=topic.lesson_id,
            topic_id =topic.id,
            word     =word,
            reading  =reading,
            meaning  =meaning,
            example  =example,
        ))
        saved += 1

    db.commit()
    return saved


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def run(
    topic_id:  int  | None,
    level:     str  | None,
    overwrite: bool,
    dry_run:   bool,
):
    db = SessionLocal()

    try:
        # ── Lọc danh sách topic cần xử lý ────────────────────────────────
        query = db.query(ShadowingTopic)
        if topic_id:
            query = query.filter(ShadowingTopic.id == topic_id)
        elif level:
            query = query.filter(ShadowingTopic.level == level)

        topics = query.order_by(ShadowingTopic.id).all()
        print(f"\n{'='*65}")
        print(f"  Vocab Generator — {len(topics)} topic cần xử lý")
        print(f"  Level: {level or 'tất cả'} | Overwrite: {overwrite} | Dry-run: {dry_run}")
        print(f"{'='*65}\n")

        total_saved   = 0
        total_skipped = 0
        total_failed  = 0

        for i, topic in enumerate(topics):
            print(f"\n[{i+1}/{len(topics)}] Topic #{topic.id}: {topic.title[:65]}")

            # Lấy từ vựng hiện có của topic này
            existing = db.query(Vocabulary)\
                         .filter(Vocabulary.topic_id == topic.id)\
                         .all()
            existing_words = {v.word for v in existing}

            print(f"  → Đang có {len(existing_words)} từ vựng")

            # Bỏ qua nếu đủ từ rồi (trừ khi overwrite)
            if not overwrite and len(existing_words) >= SKIP_THRESHOLD:
                print(f"  [SKIP] Đã đủ {len(existing_words)} từ (ngưỡng {SKIP_THRESHOLD})")
                total_skipped += 1
                continue

            # Nếu overwrite: xóa từ vựng cũ
            if overwrite and existing:
                if not dry_run:
                    db.query(Vocabulary)\
                      .filter(Vocabulary.topic_id == topic.id)\
                      .delete()
                    db.commit()
                print(f"  [OVERWRITE] Xóa {len(existing)} từ cũ")
                existing_words = set()

            # Lấy segments để làm context
            segments = db.query(ShadowingSegment)\
                         .filter(ShadowingSegment.topic_id == topic.id)\
                         .order_by(ShadowingSegment.order_index)\
                         .all()

            lv = _level_from_topic(topic)
            need_count = MAX_VOCAB - (0 if overwrite else len(existing_words))

            print(f"  → Level: {lv} | Cần tạo thêm: {need_count} từ | Gọi Gemini...")

            if dry_run:
                print(f"  [DRY-RUN] Sẽ gọi Gemini tạo {need_count} từ → lưu DB")
                continue

            vocab_list = generate_vocab_with_gemini(
                topic, segments, existing_words, lv
            )

            if not vocab_list:
                print(f"  [ERROR] Gemini thất bại cho topic #{topic.id}")
                total_failed += 1
                continue

            saved = save_vocabs(db, topic, vocab_list)
            total_saved += saved
            print(f"  ✓ Đã lưu {saved} từ vựng cho topic #{topic.id}")

        print(f"\n{'='*65}")
        print(f"  HOÀN TẤT")
        print(f"  Đã lưu:  {total_saved} từ vựng mới")
        print(f"  Bỏ qua:  {total_skipped} topic (đủ từ rồi)")
        print(f"  Lỗi:     {total_failed} topic")
        print(f"{'='*65}")

    except Exception as e:
        import traceback
        print(f"\n[ERROR] {e}")
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Tạo tối đa 40 từ vựng có Kanji cho mỗi Shadowing Topic"
    )
    parser.add_argument(
        "--topic-id", type=int, default=None,
        help="Chỉ xử lý 1 topic cụ thể theo ID"
    )
    parser.add_argument(
        "--level", choices=["N5", "N4", "N3", "N2", "N1"], default=None,
        help="Lọc theo cấp độ JLPT"
    )
    parser.add_argument(
        "--overwrite", action="store_true",
        help="Xóa từ vựng cũ và tạo lại hoàn toàn"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Chạy thử, không ghi DB"
    )
    args = parser.parse_args()

    print(f"[START] Vocab Generator — Max {MAX_VOCAB} từ/topic, bắt buộc có Kanji")
    run(
        topic_id =args.topic_id,
        level    =args.level,
        overwrite=args.overwrite,
        dry_run  =args.dry_run,
    )
