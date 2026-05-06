"""
minna_crawler.py — Thu thập dữ liệu N5/N4 từ Minna no Nihongo
================================================================
Chiến lược:
  - Hội thoại + ngữ pháp từ nihongoichiban.com và japanesetest4you.com
  - Gemini AI tổng hợp hội thoại + từ vựng chuẩn Minna no Nihongo
  - Mỗi chương Minna → 1 Lesson + 1-2 ShadowingTopic (hội thoại A/B)

Cách chạy:
  cd api
  python scripts/minna_crawler.py --level N5 --start 1 --end 25
  python scripts/minna_crawler.py --level N4 --start 26 --end 50
  python scripts/minna_crawler.py --level N5 --start 1 --end 5 --dry-run
"""

import os, sys, re, time, json, argparse
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

GEMINI_MODEL = "gemini-2.0-flash"
AI_SLEEP     = 4  # giây delay giữa các call

# ─────────────────────────────────────────────────────────────────────────────
# Dữ liệu chương Minna no Nihongo (offline — không cần crawl web)
# N5: Chương 1–25 | N4: Chương 26–50
# ─────────────────────────────────────────────────────────────────────────────
MINNA_CHAPTERS = {
    # ── N5 (Bài 1–25) ─────────────────────────────────────────────────────
    1:  {"title": "はじめまして",          "grammar": ["～は ～です", "～は ～ですか", "～じゃありません"],
         "situation": "Tự giới thiệu bản thân lần đầu gặp gỡ"},
    2:  {"title": "あれは なんですか",      "grammar": ["これ/それ/あれ", "この/その/あの", "～の"],
         "situation": "Hỏi về đồ vật xung quanh"},
    3:  {"title": "ここは どこですか",      "grammar": ["ここ/そこ/あそこ", "～に あります/います"],
         "situation": "Hỏi địa điểm, nơi chốn"},
    4:  {"title": "何時に おきますか",      "grammar": ["時間の表現", "に (thời gian)", "から～まで"],
         "situation": "Nói về lịch trình trong ngày"},
    5:  {"title": "デパートで かいます",    "grammar": ["を (tân ngữ)", "で (địa điểm)", "～ましょう"],
         "situation": "Mua sắm tại cửa hàng"},
    6:  {"title": "やすみは なんようびですか","grammar": ["曜日", "に (ngày/tháng)", "～と"],
         "situation": "Nói về ngày nghỉ, kế hoạch tuần"},
    7:  {"title": "うまれは どこですか",    "grammar": ["どんな", "形容詞 (i/na)", "～が すきです"],
         "situation": "Nói về sở thích, quê hương"},
    8:  {"title": "雪祭りは どんな お祭り", "grammar": ["形容詞の連用形", "どうして", "から (lý do)"],
         "situation": "Mô tả lễ hội, sự kiện"},
    9:  {"title": "カリナさんの せが たかい","grammar": ["て-form nối câu", "が (tuy nhiên)", "でも"],
         "situation": "Mô tả ngoại hình, tính cách người"},
    10: {"title": "どうやって いきますか",  "grammar": ["で (phương tiện)", "に (đích đến)", "～から ～まで"],
         "situation": "Hỏi đường, phương tiện đi lại"},
    11: {"title": "誕生日は いつですか",    "grammar": ["te-form + ください", "を + motion verb", "te-form dạng lịch sự"],
         "situation": "Mua quà sinh nhật, đặt hàng"},
    12: {"title": "どんな 映画が 好きですか","grammar": ["～たり ～たり します", "～が 好き/嫌い/上手/下手"],
         "situation": "Nói về sở thích giải trí, phim ảnh"},
    13: {"title": "京都へ 行ったことが あります","grammar": ["te-form + います (trạng thái)", "に + mục đích"],
         "situation": "Kể chuyện chuyến du lịch"},
    14: {"title": "電車が 止まっています",  "grammar": ["て-form + います (tiến hành)", "transit verbs"],
         "situation": "Thông báo sự cố giao thông"},
    15: {"title": "もう チケットを 買いましたか","grammar": ["もう/まだ", "te-form + しまいます"],
         "situation": "Chuẩn bị cho chuyến đi"},
    16: {"title": "年を とっても 元気です",  "grammar": ["て-form + も (dù)", "普通形", "と思います"],
         "situation": "Nói về sức khỏe, tuổi tác"},
    17: {"title": "動物に 触っては いけません","grammar": ["て-form + は いけません", "て-form + も いいです"],
         "situation": "Quy định tại nơi công cộng"},
    18: {"title": "電話の かけかた",        "grammar": ["動詞の辞書形 + ことができます", "前に"],
         "situation": "Hướng dẫn sử dụng điện thoại"},
    19: {"title": "部屋が きれいに なりました","grammar": ["に/く + なります", "に/く + します"],
         "situation": "Nói về sự thay đổi, cải thiện"},
    20: {"title": "ふるさとの 料理は 作れますか","grammar": ["可能形 (potential form)"],
         "situation": "Nói về khả năng, kỹ năng nấu ăn"},
    21: {"title": "電気が ついていますよ",  "grammar": ["passive + te-form", "～てあります", "～ておきます"],
         "situation": "Chuẩn bị cho sự kiện"},
    22: {"title": "この ほうが もっと 便利です","grammar": ["比較 (so sánh)", "～より", "～の ほうが"],
         "situation": "So sánh sản phẩm khi mua sắm"},
    23: {"title": "あそこに 本屋が ありますよ","grammar": ["て-form + みます", "conditional たら"],
         "situation": "Khám phá khu phố mới"},
    24: {"title": "この カメラの 使い方",   "grammar": ["動詞 stem + 方", "～と (conditional)"],
         "situation": "Hướng dẫn sử dụng thiết bị"},
    25: {"title": "えきの 前に ありますよ",  "grammar": ["te-form + あります (kết quả)", "てから", "Review N5"],
         "situation": "Ôn tập tổng hợp N5"},

    # ── N4 (Bài 26–50) ────────────────────────────────────────────────────
    26: {"title": "迎えに 行きましょうか",  "grammar": ["て-form + あげます/もらいます/くれます"],
         "situation": "Nhờ giúp đỡ, làm ơn cho nhau"},
    27: {"title": "日本語が 上手に なりたい","grammar": ["～たい", "～たがっています"],
         "situation": "Nói về mong muốn, mục tiêu học tập"},
    28: {"title": "桜が 咲いたら 花見を","grammar": ["conditional たら", "もし"],
         "situation": "Lên kế hoạch theo điều kiện"},
    29: {"title": "ゆっくり 話して いただけますか","grammar": ["て-form + いただけますか", "～てほしい"],
         "situation": "Nhờ vả lịch sự tại nơi làm việc"},
    30: {"title": "普通形の 使い方",        "grammar": ["普通形 (plain form)", "～と言いました", "と思います"],
         "situation": "Trích dẫn, báo cáo thông tin"},
    31: {"title": "料理が できるように なった","grammar": ["ように なります", "ように します"],
         "situation": "Kể về quá trình học kỹ năng"},
    32: {"title": "はみがきを する前に",    "grammar": ["前に/後で", "te-form + から"],
         "situation": "Mô tả thói quen hàng ngày"},
    33: {"title": "財布を とられました",    "grammar": ["受け身 (passive voice)"],
         "situation": "Báo cáo sự cố, mất đồ"},
    34: {"title": "お客さまを 案内させます", "grammar": ["使役形 (causative)"],
         "situation": "Giao việc, quản lý nhóm"},
    35: {"title": "無理を させないで ください","grammar": ["使役受け身 (causative-passive)"],
         "situation": "Phàn nàn về áp lực công việc"},
    36: {"title": "事故で 電車が 遅れているようです","grammar": ["～ようです", "～らしいです", "～そうです"],
         "situation": "Phỏng đoán tình huống"},
    37: {"title": "文法の 勉強を するかどうか","grammar": ["かどうか", "疑問詞 + か"],
         "situation": "Phân vân quyết định"},
    38: {"title": "ここに 名前を 書いて おいてください","grammar": ["～ておく (chuẩn bị trước)"],
         "situation": "Hướng dẫn thủ tục hành chính"},
    39: {"title": "電車に 乗ったまま 寝てしまいました","grammar": ["～まま", "～てしまいます"],
         "situation": "Kể chuyện tình huống dở khóc dở cười"},
    40: {"title": "日本に いる間に",       "grammar": ["間 (trong khi)", "～ないうちに"],
         "situation": "Lên kế hoạch trong thời gian lưu trú"},
    41: {"title": "部長に ほめられました",  "grammar": ["passive + emotion", "～に よって"],
         "situation": "Kể về trải nghiệm tại công ty"},
    42: {"title": "もっと 早く 起きれば よかった","grammar": ["conditional ば", "～ば よかった"],
         "situation": "Nói về hối tiếc, bài học"},
    43: {"title": "引っ越しを 手伝って もらえませんか","grammar": ["て-form + もらえませんか", "い-adj くて/な-adj で"],
         "situation": "Nhờ bạn bè giúp chuyển nhà"},
    44: {"title": "行かなくても いいです",  "grammar": ["なくても いい", "なければ なりません"],
         "situation": "Nói về nghĩa vụ và sự miễn trừ"},
    45: {"title": "会議に 参加させて いただけますか","grammar": ["使役 + いただく (lịch sự cực cao)"],
         "situation": "Xin phép tham dự họp công ty"},
    46: {"title": "そんなに 食べると 太りますよ","grammar": ["conditional と (tự nhiên)", "～と いいですね"],
         "situation": "Lời khuyên về sức khỏe"},
    47: {"title": "病院へ 行った ほうが いい","grammar": ["た ほうが いい", "ない ほうが いい"],
         "situation": "Đưa ra lời khuyên chân thành"},
    48: {"title": "このまま では いけません","grammar": ["このまま", "～ば ～ほど"],
         "situation": "Thảo luận về vấn đề xã hội"},
    49: {"title": "試験に 合格する ために",  "grammar": ["ために (mục đích)", "～ように (mục đích/kỳ vọng)"],
         "situation": "Lên kế hoạch thi JLPT"},
    50: {"title": "N4 卒業おめでとう",      "grammar": ["Review N4 tổng hợp", "～はずです", "～わけです"],
         "situation": "Ôn tập và tổng kết N4"},
}

# Ngữ pháp theo level để Gemini tập trung
GRAMMAR_FOCUS = {
    "N5": "Dùng ngữ pháp N5 cơ bản: です/ます, て-form cơ bản, を/に/で/が, こそあど, 形容詞 đơn giản.",
    "N4": "Dùng ngữ pháp N4: passive, causative, potential, conditional (たら/ば/と), ようだ/らしい, te-form phức hợp.",
}


# ─────────────────────────────────────────────────────────────────────────────
# Gemini: Tạo hội thoại + từ vựng chuẩn Minna no Nihongo
# ─────────────────────────────────────────────────────────────────────────────
def generate_dialogue_with_gemini(chapter: int, info: dict, level: str) -> dict | None:
    grammar_list = ", ".join(info["grammar"])
    grammar_focus = GRAMMAR_FOCUS.get(level, "")
    situation = info["situation"]

    prompt = f"""Bạn là giáo viên tiếng Nhật chuyên dạy theo giáo trình Minna no Nihongo.

Hãy tạo một đoạn hội thoại tự nhiên cho **Bài {chapter}: {info['title']}** của giáo trình Minna no Nihongo {level}.

**Tình huống:** {situation}
**Ngữ pháp cần luyện:** {grammar_list}
**Yêu cầu ngữ pháp:** {grammar_focus}

Yêu cầu hội thoại:
- 4-6 lượt thoại (A nói → B nói → A nói...)
- Mỗi lượt thoại: 1 câu, dài 10-25 chữ, phù hợp trình độ {level}
- Từ vựng nằm trong phạm vi Minna no Nihongo Bài {chapter}
- Tự nhiên, thực tế, có thể dùng trong cuộc sống hàng ngày

Trả về JSON THUẦN (không markdown, không ```):
{{
  "dialogue_title": "Tên tình huống hội thoại tiếng Nhật ngắn gọn",
  "segments": [
    {{"speaker": "A", "kanji": "câu gốc", "furigana": "câu HTML ruby", "romaji": "phiên âm Hepburn", "vi": "dịch tiếng Việt tự nhiên"}}
  ],
  "vocabularies": [
    {{"word": "từ kanji/kana", "reading": "hiragana", "meaning": "nghĩa tiếng Việt ngắn", "example": "câu ví dụ từ hội thoại hoặc tự tạo"}}
  ]
}}

vocabularies: 6-8 từ vựng cốt lõi của bài, quan trọng cho JLPT {level}."""

    for attempt in range(3):
        try:
            time.sleep(AI_SLEEP)
            model = genai.GenerativeModel(GEMINI_MODEL)
            resp  = model.generate_content(prompt)
            raw   = resp.text.strip()

            # Làm sạch markdown fence nếu có
            raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.MULTILINE)
            raw = re.sub(r"\s*```$", "", raw, flags=re.MULTILINE)
            raw = raw.strip()

            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                result = json.loads(match.group())
                if "segments" in result and len(result["segments"]) >= 2:
                    print(f"  ✓ Gemini tạo {len(result['segments'])} lượt thoại, "
                          f"{len(result.get('vocabularies', []))} từ vựng")
                    return result

        except json.JSONDecodeError as e:
            print(f"  [WARN] JSON lỗi lần {attempt+1}: {e}")
        except Exception as e:
            print(f"  [WARN] Gemini lỗi lần {attempt+1}: {e}")
            time.sleep(10)

    return None


# ─────────────────────────────────────────────────────────────────────────────
# Lưu vào DB
# ─────────────────────────────────────────────────────────────────────────────
def save_to_db(db, chapter: int, info: dict, level_enum: LevelEnum,
               ai_result: dict, order_index: int) -> tuple:
    chapter_name = f"Bài {chapter}: {info['title']}"
    grammar_str  = " | ".join(info["grammar"])

    # 1 Lesson = 1 chương Minna
    lesson = Lesson(
        level=level_enum,
        chapter_name=chapter_name,
        order_index=order_index,
    )
    db.add(lesson)
    db.commit()
    db.refresh(lesson)

    # ShadowingTopic = hội thoại của chương
    dialogue_title = ai_result.get("dialogue_title", chapter_name)
    segments_data  = ai_result.get("segments", [])
    full_script    = "　".join(
        seg.get("kanji", "") for seg in segments_data
    )

    topic_title = f"[{level_enum.name}] Bài {chapter}: {dialogue_title}"
    topic = ShadowingTopic(
        title=topic_title[:200],
        level=level_enum.value,
        lesson_id=lesson.id,
        image_url=None,
        full_audio_url=None,
        full_script_ja=full_script,
        total_duration=float(len(segments_data) * 8),
    )
    db.add(topic)
    db.commit()
    db.refresh(topic)

    # ShadowingSegment — mỗi lượt thoại = 1 segment
    for idx, seg in enumerate(segments_data, 1):
        speaker_prefix = f"【{seg.get('speaker', '')}】 " if seg.get("speaker") else ""
        db.add(ShadowingSegment(
            topic_id    =topic.id,
            order_index =idx,
            start_time  =float((idx - 1) * 8),
            end_time    =float(idx * 8),
            kanji_content=speaker_prefix + seg.get("kanji", ""),
            furigana    =speaker_prefix + seg.get("furigana", seg.get("kanji", "")),
            romaji      =seg.get("romaji", ""),
            sino_vietnamese=None,
            translation_vi =seg.get("vi", ""),
        ))

    # Vocabulary — từ vựng của chương
    for v in ai_result.get("vocabularies", []):
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
          f"{len(segments_data)} lượt thoại | "
          f"{len(ai_result.get('vocabularies', []))} từ vựng")
    return lesson, topic


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
def run(level: str, start: int, end: int, dry_run: bool = False):
    level_enum = LevelEnum[level]
    db = SessionLocal() if not dry_run else None

    existing_count = db.query(Lesson).count() if db else 0

    chapters_in_range = {
        ch: info for ch, info in MINNA_CHAPTERS.items()
        if start <= ch <= end
    }

    print(f"\n{'='*65}")
    print(f"  Minna no Nihongo Crawler — Level {level}")
    print(f"  Chương {start}–{end} ({len(chapters_in_range)} bài)")
    print(f"  Dry-run: {dry_run}")
    print(f"{'='*65}\n")

    for i, (chapter, info) in enumerate(sorted(chapters_in_range.items())):
        print(f"\n[{i+1}/{len(chapters_in_range)}] Chương {chapter}: {info['title']}")
        print(f"  Ngữ pháp: {', '.join(info['grammar'][:3])}...")

        if dry_run:
            print(f"  [DRY-RUN] Sẽ gọi Gemini tạo hội thoại & từ vựng → lưu DB")
            continue

        # Kiểm tra đã tồn tại chưa
        dup = db.query(Lesson).filter(
            Lesson.chapter_name.like(f"%Bài {chapter}:%")
        ).first()
        if dup:
            print(f"  [SKIP] Bài {chapter} đã có trong DB (Lesson #{dup.id})")
            continue

        print(f"  → Gọi Gemini AI tạo hội thoại...")
        ai_result = generate_dialogue_with_gemini(chapter, info, level)

        if not ai_result:
            print(f"  [ERROR] Gemini thất bại bài {chapter}, bỏ qua.")
            continue

        order = existing_count + i + 1
        save_to_db(db, chapter, info, level_enum, ai_result, order)
        existing_count += 1

        print(f"  ✓ Hoàn thành bài {chapter}")

    if db:
        db.close()
    print(f"\n[DONE] Hoàn tất {level} bài {start}–{end}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Minna no Nihongo Crawler (N5/N4)")
    parser.add_argument("--level",   required=True, choices=["N5", "N4"],
                        help="Cấp độ: N5 (bài 1-25) hoặc N4 (bài 26-50)")
    parser.add_argument("--start",   type=int, default=1,
                        help="Bài bắt đầu (default: 1)")
    parser.add_argument("--end",     type=int, default=25,
                        help="Bài kết thúc (default: 25)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Chạy thử, không ghi DB")
    args = parser.parse_args()

    # Tự động điều chỉnh range theo level
    if args.level == "N5" and args.end == 25 and args.start == 1:
        start, end = 1, 25
    elif args.level == "N4" and args.end == 25 and args.start == 1:
        start, end = 26, 50
    else:
        start, end = args.start, args.end

    run(level=args.level, start=start, end=end, dry_run=args.dry_run)
