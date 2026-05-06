-- =============================================================
-- SEED N5 REAL: 5 bài học theo Minna no Nihongo
-- lesson IDs: 6001-6005 | topic IDs: 7001-7010 (2 topics/lesson)
-- =============================================================
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

DELETE FROM shadowing_segments WHERE topic_id BETWEEN 7001 AND 7010;
DELETE FROM shadowing_topics   WHERE id        BETWEEN 7001 AND 7010;
DELETE FROM vocabularies       WHERE lesson_id  BETWEEN 6001 AND 6005;
DELETE FROM lessons            WHERE id         BETWEEN 6001 AND 6005;

-- =============================================================
-- BÀI 1: Chào hỏi & Giới thiệu bản thân
-- =============================================================
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6001, 'N5', N'Bài 1 – Chào hỏi & Giới thiệu', 1);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6001, NULL, 'はじめまして', 'はじめまして', N'Rất vui được gặp bạn', 'はじめまして、田中です。'),
(6001, NULL, 'よろしくおねがいします', 'よろしくおねがいします', N'Mong được giúp đỡ', 'よろしくおねがいします。'),
(6001, NULL, 'わたし', 'わたし', N'Tôi', 'わたしは学生です。'),
(6001, NULL, 'なまえ', 'なまえ', N'Tên', 'なまえは田中です。'),
(6001, NULL, 'にほんご', 'にほんご', N'Tiếng Nhật', 'にほんごをべんきょうします。'),
(6001, NULL, 'がくせい', 'がくせい', N'Học sinh / Sinh viên', 'わたしはがくせいです。'),
(6001, NULL, 'せんせい', 'せんせい', N'Giáo viên', 'やまださんはせんせいです。'),
(6001, NULL, 'どうぞ', 'どうぞ', N'Xin mời / Vâng', 'どうぞよろしく。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7001, N'Tự giới thiệu – Gặp lần đầu', 'N5', 6001,
 'はじめまして。わたしはナムです。ベトナムからきました。にほんごをべんきょうしています。どうぞよろしくおねがいします。', 20.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7001, 1,  0.0,  5.0, 'はじめまして。わたしはナムです。', 'はじめまして。わたしはナムです。', 'Hajimemashite. Watashi wa Namu desu.', N'Sơ kiến. Ngã thị Nam.', N'Rất vui được gặp bạn. Tôi là Nam.'),
(7001, 2,  5.5, 11.0, 'ベトナムからきました。にほんごをべんきょうしています。', 'ベトナムからきました。にほんごをべんきょうしています。', 'Betonamu kara kimashita. Nihongo o benkyou shite imasu.', N'Từ Việt Nam đến. Học tiếng Nhật.', N'Tôi đến từ Việt Nam. Tôi đang học tiếng Nhật.'),
(7001, 3, 11.5, 18.0, 'どうぞよろしくおねがいします。', 'どうぞよろしくおねがいします。', 'Douzo yoroshiku onegaishimasu.', N'Đa tạ quan chiếu.', N'Mong được giúp đỡ nhiều nhé.');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7002, N'Hỏi nghề nghiệp – Giới thiệu công việc', 'N5', 6001,
 'おしごとはなんですか。わたしはがくせいです。やまださんはせんせいです。どうぞよろしく。', 18.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7002, 1,  0.0,  5.0, 'おしごとはなんですか。', 'おしごとはなんですか。', 'Oshigoto wa nan desuka.', N'Công việc là gì?', N'Công việc của bạn là gì?'),
(7002, 2,  5.5, 11.0, 'わたしはがくせいです。やまださんはせんせいです。', 'わたしはがくせいです。やまださんはせんせいです。', 'Watashi wa gakusei desu. Yamada-san wa sensei desu.', N'Ngã thị học sinh. Sơn Điền tiên sinh.', N'Tôi là học sinh. Anh Yamada là giáo viên.'),
(7002, 3, 11.5, 17.0, 'どうぞよろしくおねがいします。', 'どうぞよろしくおねがいします。', 'Douzo yoroshiku onegaishimasu.', N'Đa tạ quan chiếu.', N'Rất mong được giúp đỡ.');

-- =============================================================
-- BÀI 2: Đây là gì? – Đồ vật xung quanh
-- =============================================================
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6002, 'N5', N'Bài 2 – Đây là gì? (これは何ですか)', 2);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6002, NULL, 'これ', 'これ', N'Cái này', 'これはほんです。'),
(6002, NULL, 'それ', 'それ', N'Cái đó (gần người nghe)', 'それはなんですか。'),
(6002, NULL, 'あれ', 'あれ', N'Cái kia (xa cả hai)', 'あれはじしょです。'),
(6002, NULL, 'なん / なに', 'なん / なに', N'Cái gì', 'これはなんですか。'),
(6002, NULL, 'ほん', 'ほん', N'Sách', 'これはほんです。'),
(6002, NULL, 'じしょ', 'じしょ', N'Từ điển', 'じしょをかします。'),
(6002, NULL, 'えんぴつ', 'えんぴつ', N'Bút chì', 'えんぴつがあります。'),
(6002, NULL, 'かばん', 'かばん', N'Túi xách / Cặp', 'これはわたしのかばんです。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7003, N'Hỏi đồ vật – これは何ですか', 'N5', 6002,
 'これはなんですか。ほんです。それはじしょですか。いいえ、えんぴつです。あれはだれのかばんですか。', 22.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7003, 1,  0.0,  6.0, 'これはなんですか。ほんです。', 'これはなんですか。ほんです。', 'Kore wa nan desuka. Hon desu.', N'Thử thị hà? Thư dã.', N'Cái này là gì? Là quyển sách.'),
(7003, 2,  6.5, 13.0, 'それはじしょですか。いいえ、えんぴつです。', 'それはじしょですか。いいえ、えんぴつです。', 'Sore wa jisho desuka. Iie, enpitsu desu.', N'Thị từ điển? Phủ, bút chì.', N'Cái đó là từ điển à? Không, là bút chì.'),
(7003, 3, 13.5, 21.0, 'あれはだれのかばんですか。', 'あれはだれのかばんですか。', 'Are wa dare no kaban desuka.', N'Tha thị thùy đích túi?', N'Cái kia là túi của ai vậy?');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7004, N'Trả đồ vật – これをどうぞ', 'N5', 6002,
 'これはわたしのほんです。どうぞ。ありがとうございます。それもわたしのえんぴつです。', 19.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7004, 1,  0.0,  6.0, 'これはわたしのほんです。どうぞ。', 'これはわたしのほんです。どうぞ。', 'Kore wa watashi no hon desu. Douzo.', N'Ngã đích thư, thỉnh.', N'Đây là sách của tôi. Xin mời.'),
(7004, 2,  6.5, 11.0, 'ありがとうございます。', 'ありがとうございます。', 'Arigatou gozaimasu.', N'Đa tạ.', N'Cảm ơn bạn rất nhiều.'),
(7004, 3, 11.5, 18.0, 'それもわたしのえんぴつです。', 'それもわたしのえんぴつです。', 'Sore mo watashi no enpitsu desu.', N'Tha diệc ngã đích bút chì.', N'Cái đó cũng là bút chì của tôi.');

-- =============================================================
-- BÀI 3: Ở đâu? – Địa điểm và nơi chốn
-- =============================================================
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6003, 'N5', N'Bài 3 – Ở đâu? (どこですか)', 3);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6003, NULL, 'どこ', 'どこ', N'Ở đâu', 'トイレはどこですか。'),
(6003, NULL, 'ここ', 'ここ', N'Đây / Ở đây', 'ここはがっこうです。'),
(6003, NULL, 'そこ', 'そこ', N'Đó / Ở đó', 'そこにあります。'),
(6003, NULL, 'あそこ', 'あそこ', N'Kia / Ở kia', 'トイレはあそこです。'),
(6003, NULL, 'がっこう', 'がっこう', N'Trường học', 'がっこうへいきます。'),
(6003, NULL, 'びょういん', 'びょういん', N'Bệnh viện', 'びょういんはどこですか。'),
(6003, NULL, 'えき', 'えき', N'Ga (tàu)', 'えきのちかくです。'),
(6003, NULL, 'ちかく', 'ちかく', N'Gần đây / Gần', 'えきのちかくにあります。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7005, N'Hỏi đường – どこですか', 'N5', 6003,
 'すみません、えきはどこですか。あそこです。ありがとうございます。びょういんはちかくにありますか。', 21.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7005, 1,  0.0,  6.5, 'すみません、えきはどこですか。', 'すみません、えきはどこですか。', 'Sumimasen, eki wa doko desuka.', N'Thất lễ, nhà ga ở đâu?', N'Xin lỗi, ga tàu ở đâu ạ?'),
(7005, 2,  7.0, 11.0, 'あそこです。ありがとうございます。', 'あそこです。ありがとうございます。', 'Asoko desu. Arigatou gozaimasu.', N'Ở kia. Đa tạ.', N'Ở đằng kia. Cảm ơn bạn nhiều.'),
(7005, 3, 11.5, 20.0, 'びょういんはちかくにありますか。', 'びょういんはちかくにありますか。', 'Byouin wa chikaku ni arimasuka.', N'Y viện ở gần chỗ đây?', N'Bệnh viện có ở gần đây không?');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7006, N'Chỉ đường trong trường – ここはどこ', 'N5', 6003,
 'ここはがっこうです。としょかんはそこです。トイレはあそこです。わかりましたか。', 20.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7006, 1,  0.0,  5.0, 'ここはがっこうです。としょかんはそこです。', 'ここはがっこうです。としょかんはそこです。', 'Koko wa gakkou desu. Toshokan wa soko desu.', N'Thử thị học hiệu. Đồ thư quán ở đó.', N'Đây là trường học. Thư viện ở đó.'),
(7006, 2,  5.5, 11.0, 'トイレはあそこです。', 'トイレはあそこです。', 'Toire wa asoko desu.', N'Nhà vệ sinh ở kia.', N'Nhà vệ sinh ở đằng kia.'),
(7006, 3, 11.5, 19.0, 'わかりましたか。はい、わかりました。', 'わかりましたか。はい、わかりました。', 'Wakarimashitaka. Hai, wakarimashita.', N'Hiểu rồi chưa? Hiểu rồi.', N'Bạn hiểu chưa? Dạ, tôi hiểu rồi.');

-- =============================================================
-- BÀI 4: Mấy giờ rồi? – Thời gian và lịch
-- =============================================================
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6004, 'N5', N'Bài 4 – Mấy giờ rồi? (何時ですか)', 4);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6004, NULL, 'なんじ', 'なんじ', N'Mấy giờ', 'いまなんじですか。'),
(6004, NULL, 'いま', 'いま', N'Bây giờ', 'いまごじです。'),
(6004, NULL, 'ごぜん', 'ごぜん', N'Buổi sáng (AM)', 'ごぜんくじにおきます。'),
(6004, NULL, 'ごご', 'ごご', N'Buổi chiều (PM)', 'ごごさんじにべんきょうします。'),
(6004, NULL, 'はじまる', 'はじまる', N'Bắt đầu', 'じゅぎょうははちじにはじまります。'),
(6004, NULL, 'おわる', 'おわる', N'Kết thúc', 'しごとはごじにおわります。'),
(6004, NULL, 'じゅぎょう', 'じゅぎょう', N'Tiết học / Bài giảng', 'じゅぎょうははちじです。'),
(6004, NULL, 'やすみ', 'やすみ', N'Nghỉ ngơi / Ngày nghỉ', 'きょうはやすみです。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7007, N'Hỏi giờ – いま何時ですか', 'N5', 6004,
 'いまなんじですか。ごぜんくじです。じゅぎょうははちじにはじまります。やすみはじゅういちじからです。', 22.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7007, 1,  0.0,  6.0, 'いまなんじですか。ごぜんくじです。', 'いまなんじですか。ごぜんくじです。', 'Ima nanji desuka. Gozen kuji desu.', N'Hiện tại mấy giờ? Sáng 9 giờ.', N'Bây giờ là mấy giờ? Là 9 giờ sáng.'),
(7007, 2,  6.5, 13.0, 'じゅぎょうははちじにはじまります。', 'じゅぎょうははちじにはじまります。', 'Jugyou wa hachi-ji ni hajimarimasu.', N'Thụ nghiệp 8 giờ khai thủy.', N'Tiết học bắt đầu lúc 8 giờ.'),
(7007, 3, 13.5, 21.0, 'やすみはじゅういちじからです。', 'やすみはじゅういちじからです。', 'Yasumi wa juuichi-ji kara desu.', N'Nghỉ từ 11 giờ.', N'Giờ nghỉ bắt đầu từ 11 giờ.');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7008, N'Lịch học – 毎日のスケジュール', 'N5', 6004,
 'まいにちごぜんはちじにがっこうへいきます。じゅぎょうはごごさんじにおわります。うちへかえります。', 21.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7008, 1,  0.0,  7.0, 'まいにちごぜんはちじにがっこうへいきます。', 'まいにちごぜんはちじにがっこうへいきます。', 'Mainichi gozen hachiji ni gakkou e ikimasu.', N'Mỗi ngày sáng 8 giờ đến trường.', N'Mỗi ngày tôi đến trường lúc 8 giờ sáng.'),
(7008, 2,  7.5, 13.0, 'じゅぎょうはごごさんじにおわります。', 'じゅぎょうはごごさんじにおわります。', 'Jugyou wa gogo sanji ni owarimasu.', N'Thụ nghiệp chiều 3 giờ kết thúc.', N'Tiết học kết thúc lúc 3 giờ chiều.'),
(7008, 3, 13.5, 20.0, 'うちへかえります。', 'うちへかえります。', 'Uchi e kaerimasu.', N'Về nhà.', N'Tôi về nhà.');

-- =============================================================
-- BÀI 5: Mua sắm – Giá cả và số đếm
-- =============================================================
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6005, 'N5', N'Bài 5 – Mua sắm (いくらですか)', 5);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6005, NULL, 'いくら', 'いくら', N'Bao nhiêu tiền', 'これはいくらですか。'),
(6005, NULL, 'かう', 'かう', N'Mua', 'スーパーでかいものをします。'),
(6005, NULL, 'たかい', 'たかい', N'Đắt / Cao', 'このかばんはたかいです。'),
(6005, NULL, 'やすい', 'やすい', N'Rẻ / Thấp', 'このほんはやすいです。'),
(6005, NULL, 'スーパー', 'スーパー', N'Siêu thị', 'スーパーへいきます。'),
(6005, NULL, 'おかね', 'おかね', N'Tiền', 'おかねがありません。'),
(6005, NULL, 'ください', 'ください', N'Xin cho tôi / Vui lòng', 'みずをください。'),
(6005, NULL, 'みず', 'みず', N'Nước', 'みずをのみます。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7009, N'Mua hàng – スーパーで買い物', 'N5', 6005,
 'すみません、これはいくらですか。さんびゃくえんです。じゃあ、これをください。ありがとうございます。', 22.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7009, 1,  0.0,  7.0, 'すみません、これはいくらですか。', 'すみません、これはいくらですか。', 'Sumimasen, kore wa ikura desuka.', N'Thất lễ, thử vật giá tiền?', N'Xin lỗi, cái này giá bao nhiêu ạ?'),
(7009, 2,  7.5, 13.0, 'さんびゃくえんです。じゃあ、これをください。', 'さんびゃくえんです。じゃあ、これをください。', 'Sanbyaku en desu. Jaa, kore o kudasai.', N'Ba trăm yên. Vậy cho tôi cái này.', N'Là 300 yên. Vậy cho tôi cái này nhé.'),
(7009, 3, 13.5, 21.0, 'ありがとうございます。またきてください。', 'ありがとうございます。またきてください。', 'Arigatou gozaimasu. Mata kite kudasai.', N'Đa tạ. Lại lai quang lâm.', N'Cảm ơn bạn. Hãy ghé lại lần sau nhé.');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7010, N'So sánh giá – 高い・安い', 'N5', 6005,
 'このかばんはたかいです。あのかばんはやすいです。やすいほうをかいます。おかねはいくらありますか。', 22.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7010, 1,  0.0,  7.0, 'このかばんはたかいです。あのかばんはやすいです。', 'このかばんはたかいです。あのかばんはやすいです。', 'Kono kaban wa takai desu. Ano kaban wa yasui desu.', N'Thử túi quý. Tha túi liêm.', N'Cái túi này đắt. Cái túi kia rẻ.'),
(7010, 2,  7.5, 13.0, 'やすいほうをかいます。', 'やすいほうをかいます。', 'Yasui hou o kaimasu.', N'Mua cái rẻ hơn.', N'Tôi sẽ mua cái rẻ hơn.'),
(7010, 3, 13.5, 21.0, 'おかねはいくらありますか。', 'おかねはいくらありますか。', 'Okane wa ikura arimasuka.', N'Tiền có bao nhiêu?', N'Bạn có bao nhiêu tiền?');
