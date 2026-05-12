SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

DELETE FROM shadowing_segments WHERE topic_id BETWEEN 7011 AND 7020;
DELETE FROM shadowing_topics   WHERE id        BETWEEN 7011 AND 7020;
DELETE FROM vocabularies       WHERE lesson_id  BETWEEN 6006 AND 6010;
DELETE FROM lessons            WHERE id         BETWEEN 6006 AND 6010;

-- BÀI 6: Đi đâu? – Động từ di chuyển
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6006, 'N5', N'Bài 6 – Đi đâu? (どこへいきますか)', 6);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6006, NULL, 'いきます', 'いきます', N'Đi', 'がっこうへいきます。'),
(6006, NULL, 'きます', 'きます', N'Đến / Tới', 'うちへきます。'),
(6006, NULL, 'かえります', 'かえります', N'Trở về', 'うちへかえります。'),
(6006, NULL, 'でんしゃ', 'でんしゃ', N'Tàu điện', 'でんしゃでいきます。'),
(6006, NULL, 'バス', 'バス', N'Xe buýt', 'バスにのります。'),
(6006, NULL, 'あるく', 'あるく', N'Đi bộ', 'あるいていきます。'),
(6006, NULL, 'どこへ', 'どこへ', N'Đi đâu', 'どこへいきますか。'),
(6006, NULL, 'いっしょに', 'いっしょに', N'Cùng nhau', 'いっしょにいきましょう。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7011, N'Hỏi đi đâu – どこへいきますか', 'N5', 6006,
 'どこへいきますか。えきへいきます。なにでいきますか。でんしゃでいきます。いっしょにいきましょう。', 22.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7011, 1,  0.0,  6.0, 'どこへいきますか。えきへいきます。', 'どこへいきますか。えきへいきます。', 'Doko e ikimasuka. Eki e ikimasu.', N'Đi đâu vậy? Đi đến ga.', N'Bạn đi đâu vậy? Tôi đi đến ga.'),
(7011, 2,  6.5, 13.0, 'なにでいきますか。でんしゃでいきます。', 'なにでいきますか。でんしゃでいきます。', 'Nani de ikimasuka. Densha de ikimasu.', N'Đi bằng gì? Đi bằng tàu điện.', N'Bạn đi bằng gì? Tôi đi bằng tàu điện.'),
(7011, 3, 13.5, 21.0, 'いっしょにいきましょう。', 'いっしょにいきましょう。', 'Issho ni ikimashou.', N'Cùng đi nào.', N'Chúng ta cùng đi nhé!');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7012, N'Kế hoạch cuối tuần – 週末の予定', 'N5', 6006,
 'あしたどこへいきますか。ともだちのうちへいきます。バスでいきますか。いいえ、あるいていきます。', 21.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7012, 1,  0.0,  6.0, 'あしたどこへいきますか。ともだちのうちへいきます。', 'あしたどこへいきますか。ともだちのうちへいきます。', 'Ashita doko e ikimasuka. Tomodachi no uchi e ikimasu.', N'Ngày mai đi đâu? Đến nhà bạn.', N'Ngày mai bạn đi đâu? Tôi đến nhà bạn bè.'),
(7012, 2,  6.5, 12.0, 'バスでいきますか。', 'バスでいきますか。', 'Basu de ikimasuka.', N'Đi bằng xe buýt?', N'Bạn đi bằng xe buýt à?'),
(7012, 3, 12.5, 20.0, 'いいえ、あるいていきます。', 'いいえ、あるいていきます。', 'Iie, aruite ikimasu.', N'Không, đi bộ.', N'Không, tôi đi bộ.');

-- BÀI 7: Ăn uống hàng ngày
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6007, 'N5', N'Bài 7 – Ăn uống (たべます・のみます)', 7);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6007, NULL, 'たべます', 'たべます', N'Ăn', 'ごはんをたべます。'),
(6007, NULL, 'のみます', 'のみます', N'Uống', 'みずをのみます。'),
(6007, NULL, 'ごはん', 'ごはん', N'Cơm / Bữa ăn', 'あさごはんをたべます。'),
(6007, NULL, 'パン', 'パン', N'Bánh mì', 'あさはパンをたべます。'),
(6007, NULL, 'コーヒー', 'コーヒー', N'Cà phê', 'コーヒーをのみます。'),
(6007, NULL, 'おいしい', 'おいしい', N'Ngon', 'このりょうりはおいしいです。'),
(6007, NULL, 'レストラン', 'レストラン', N'Nhà hàng', 'レストランでたべます。'),
(6007, NULL, 'いっしょに', 'いっしょに', N'Cùng nhau', 'いっしょにたべましょう。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7013, N'Mời ăn trưa – 昼ごはんに誘う', 'N5', 6007,
 'ひるごはんをいっしょにたべませんか。いいですね。どこでたべますか。あのレストランはどうですか。おいしいですよ。', 24.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7013, 1,  0.0,  7.0, 'ひるごはんをいっしょにたべませんか。いいですね。', 'ひるごはんをいっしょにたべませんか。いいですね。', 'Hirugohan o issho ni tabemasenka. Ii desune.', N'Cùng ăn trưa không? Hay đấy.', N'Chúng ta cùng ăn trưa không? Hay đấy nhỉ.'),
(7013, 2,  7.5, 14.0, 'どこでたべますか。あのレストランはどうですか。', 'どこでたべますか。あのレストランはどうですか。', 'Doko de tabemasuka. Ano resutoran wa dou desuka.', N'Ăn ở đâu? Nhà hàng kia thế nào?', N'Ăn ở đâu? Nhà hàng kia thế nào?'),
(7013, 3, 14.5, 23.0, 'おいしいですよ。', 'おいしいですよ。', 'Oishii desu yo.', N'Ngon lắm đó.', N'Ngon lắm đó!');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7014, N'Bữa sáng hàng ngày – 毎朝の朝ごはん', 'N5', 6007,
 'まいあさなにをたべますか。パンをたべます。なにをのみますか。コーヒーをのみます。', 20.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7014, 1,  0.0,  6.0, 'まいあさなにをたべますか。パンをたべます。', 'まいあさなにをたべますか。パンをたべます。', 'Maiasa nani o tabemasuka. Pan o tabemasu.', N'Mỗi sáng ăn gì? Ăn bánh mì.', N'Mỗi sáng bạn ăn gì? Tôi ăn bánh mì.'),
(7014, 2,  6.5, 12.0, 'なにをのみますか。コーヒーをのみます。', 'なにをのみますか。コーヒーをのみます。', 'Nani o nomimasuka. Koohii o nomimasu.', N'Uống gì? Uống cà phê.', N'Bạn uống gì? Tôi uống cà phê.'),
(7014, 3, 12.5, 19.0, 'コーヒーはおいしいですね。', 'コーヒーはおいしいですね。', 'Koohii wa oishii desune.', N'Cà phê ngon nhỉ.', N'Cà phê ngon nhỉ!');

-- BÀI 8: Số đếm và đơn vị
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6008, 'N5', N'Bài 8 – Số đếm (いくつ・何枚)', 8);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6008, NULL, 'いくつ', 'いくつ', N'Bao nhiêu (đồ vật)', 'りんごはいくつですか。'),
(6008, NULL, 'なんまい', 'なんまい', N'Mấy tờ / mấy cái (phẳng)', 'きってをなんまいかいますか。'),
(6008, NULL, 'なんぼん', 'なんぼん', N'Mấy cái (dài, tròn)', 'えんぴつをなんぼんかいますか。'),
(6008, NULL, 'なんこ', 'なんこ', N'Mấy cái (tròn nhỏ)', 'たまごをなんこかいますか。'),
(6008, NULL, 'ひとつ', 'ひとつ', N'Một cái', 'ひとつください。'),
(6008, NULL, 'ふたつ', 'ふたつ', N'Hai cái', 'りんごをふたつください。'),
(6008, NULL, 'みっつ', 'みっつ', N'Ba cái', 'みっつあります。'),
(6008, NULL, 'たくさん', 'たくさん', N'Nhiều', 'りんごがたくさんあります。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7015, N'Đặt hàng – 注文する', 'N5', 6008,
 'りんごをいくつかいますか。みっつください。たまごはなんこですか。ろっこください。たくさんありますね。', 23.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7015, 1,  0.0,  7.0, 'りんごをいくつかいますか。みっつください。', 'りんごをいくつかいますか。みっつください。', 'Ringo o ikutsu kaimasuka. Mittsu kudasai.', N'Mua bao nhiêu táo? Ba cái.', N'Bạn mua bao nhiêu quả táo? Cho tôi ba cái.'),
(7015, 2,  7.5, 14.0, 'たまごはなんこですか。ろっこください。', 'たまごはなんこですか。ろっこください。', 'Tamago wa nanko desuka. Rokko kudasai.', N'Trứng mấy cái? Sáu cái.', N'Trứng mấy cái? Cho tôi sáu cái.'),
(7015, 3, 14.5, 22.0, 'たくさんありますね。', 'たくさんありますね。', 'Takusan arimasu ne.', N'Nhiều nhỉ.', N'Nhiều quá nhỉ!');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7016, N'Đếm đồ vật – 物を数える', 'N5', 6008,
 'えんぴつをなんぼんかいますか。にほんかいます。きってをなんまいかいますか。じゅうまいください。', 21.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7016, 1,  0.0,  6.5, 'えんぴつをなんぼんかいますか。にほんかいます。', 'えんぴつをなんぼんかいますか。にほんかいます。', 'Enpitsu o nanbon kaimasuka. Nihon kaimasu.', N'Mua mấy cây bút chì? Hai cây.', N'Bạn mua mấy cây bút chì? Mua hai cây.'),
(7016, 2,  7.0, 13.0, 'きってをなんまいかいますか。', 'きってをなんまいかいますか。', 'Kitte o nanmai kaimasuka.', N'Mua mấy con tem?', N'Bạn mua mấy con tem?'),
(7016, 3, 13.5, 20.0, 'じゅうまいください。', 'じゅうまいください。', 'Juumai kudasai.', N'Cho mười tờ.', N'Cho tôi mười con tem.');

-- BÀI 9: Ngày tháng và lịch
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6009, 'N5', N'Bài 9 – Ngày tháng (何月何日ですか)', 9);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6009, NULL, 'なんがつ', 'なんがつ', N'Tháng mấy', 'いまなんがつですか。'),
(6009, NULL, 'なんにち', 'なんにち', N'Ngày mấy', 'きょうはなんにちですか。'),
(6009, NULL, 'たんじょうび', 'たんじょうび', N'Sinh nhật', 'たんじょうびはいつですか。'),
(6009, NULL, 'ことし', 'ことし', N'Năm nay', 'ことしはなんねんですか。'),
(6009, NULL, 'きのう', 'きのう', N'Hôm qua', 'きのうはどようびでした。'),
(6009, NULL, 'あした', 'あした', N'Ngày mai', 'あしたはにちようびです。'),
(6009, NULL, 'なんようび', 'なんようび', N'Thứ mấy', 'きょうはなんようびですか。'),
(6009, NULL, 'やすみ', 'やすみ', N'Ngày nghỉ', 'にちようびはやすみです。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7017, N'Hỏi sinh nhật – 誕生日はいつ?', 'N5', 6009,
 'たんじょうびはいつですか。さんがつじゅうごにちです。なんようびですか。もくようびです。おめでとうございます。', 24.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7017, 1,  0.0,  7.0, 'たんじょうびはいつですか。さんがつじゅうごにちです。', 'たんじょうびはいつですか。さんがつじゅうごにちです。', 'Tanjoubi wa itsu desuka. Sangatsu juugonichi desu.', N'Sinh nhật khi nào? Ngày 15 tháng 3.', N'Sinh nhật của bạn là khi nào? Ngày 15 tháng 3.'),
(7017, 2,  7.5, 13.0, 'なんようびですか。もくようびです。', 'なんようびですか。もくようびです。', 'Nanyoubi desuka. Mokuyoubi desu.', N'Thứ mấy? Thứ năm.', N'Là thứ mấy? Là thứ năm.'),
(7017, 3, 13.5, 23.0, 'おめでとうございます。', 'おめでとうございます。', 'Omedetou gozaimasu.', N'Chúc mừng.', N'Chúc mừng sinh nhật!');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7018, N'Hỏi thứ trong tuần – 何曜日ですか', 'N5', 6009,
 'きょうはなんようびですか。かようびです。あしたはなんようびですか。すいようびです。やすみはいつですか。にちようびです。', 23.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7018, 1,  0.0,  7.0, 'きょうはなんようびですか。かようびです。', 'きょうはなんようびですか。かようびです。', 'Kyou wa nanyoubi desuka. Kayoubi desu.', N'Hôm nay thứ mấy? Thứ ba.', N'Hôm nay là thứ mấy? Là thứ ba.'),
(7018, 2,  7.5, 14.0, 'あしたはすいようびです。', 'あしたはすいようびです。', 'Ashita wa suiyoubi desu.', N'Ngày mai là thứ tư.', N'Ngày mai là thứ tư.'),
(7018, 3, 14.5, 22.0, 'やすみはいつですか。にちようびです。', 'やすみはいつですか。にちようびです。', 'Yasumi wa itsu desuka. Nichiyoubi desu.', N'Nghỉ hôm nào? Chủ nhật.', N'Ngày nghỉ là khi nào? Là chủ nhật.');

-- BÀI 10: Gia đình
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6010, 'N5', N'Bài 10 – Gia đình (かぞく)', 10);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6010, NULL, 'かぞく', 'かぞく', N'Gia đình', 'わたしのかぞくはよにんです。'),
(6010, NULL, 'ちち', 'ちち', N'Bố (của mình)', 'ちちはかいしゃいんです。'),
(6010, NULL, 'はは', 'はは', N'Mẹ (của mình)', 'はははせんせいです。'),
(6010, NULL, 'あに', 'あに', N'Anh trai (của mình)', 'あにはだいがくせいです。'),
(6010, NULL, 'いもうと', 'いもうと', N'Em gái (của mình)', 'いもうとはこうこうせいです。'),
(6010, NULL, 'なんにん', 'なんにん', N'Mấy người', 'かぞくはなんにんですか。'),
(6010, NULL, 'おとうさん', 'おとうさん', N'Bố (của người khác)', 'おとうさんはおげんきですか。'),
(6010, NULL, 'おかあさん', 'おかあさん', N'Mẹ (của người khác)', 'おかあさんはどちらですか。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7019, N'Giới thiệu gia đình – 家族紹介', 'N5', 6010,
 'かぞくはなんにんですか。よにんです。ちちとははとあにとわたしです。おとうさんはおしごとはなんですか。かいしゃいんです。', 26.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7019, 1,  0.0,  7.0, 'かぞくはなんにんですか。よにんです。', 'かぞくはなんにんですか。よにんです。', 'Kazoku wa nannin desuka. Yonin desu.', N'Gia đình mấy người? Bốn người.', N'Gia đình bạn có mấy người? Có bốn người.'),
(7019, 2,  7.5, 15.0, 'ちちとははとあにとわたしです。', 'ちちとははとあにとわたしです。', 'Chichi to haha to ani to watashi desu.', N'Bố mẹ anh trai và tôi.', N'Có bố, mẹ, anh trai và tôi.'),
(7019, 3, 15.5, 25.0, 'おとうさんはおしごとはなんですか。かいしゃいんです。', 'おとうさんはおしごとはなんですか。かいしゃいんです。', 'Otousan no oshigoto wa nan desuka. Kaishain desu.', N'Bố làm nghề gì? Nhân viên công ty.', N'Bố của bạn làm nghề gì? Là nhân viên công ty.');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7020, N'Hỏi thăm gia đình – ご家族は?', 'N5', 6010,
 'ごかぞくはなんにんですか。ごにんです。おかあさんはおげんきですか。はい、げんきです。いもうとさんはなんさいですか。じゅうさんさいです。', 26.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7020, 1,  0.0,  7.0, 'ごかぞくはなんにんですか。ごにんです。', 'ごかぞくはなんにんですか。ごにんです。', 'Gokazoku wa nannin desuka. Gonin desu.', N'Gia đình mấy người? Năm người.', N'Gia đình bạn có mấy người? Có năm người.'),
(7020, 2,  7.5, 14.0, 'おかあさんはおげんきですか。はい、げんきです。', 'おかあさんはおげんきですか。はい、げんきです。', 'Okaasan wa ogenki desuka. Hai, genki desu.', N'Mẹ bạn có khoẻ không? Khoẻ.', N'Mẹ của bạn có khoẻ không? Dạ khoẻ.'),
(7020, 3, 14.5, 25.0, 'いもうとさんはなんさいですか。じゅうさんさいです。', 'いもうとさんはなんさいですか。じゅうさんさいです。', 'Imoutosan wa nansai desuka. Juusansai desu.', N'Em gái bao nhiêu tuổi? Mười ba tuổi.', N'Em gái của bạn bao nhiêu tuổi? Mười ba tuổi.');
