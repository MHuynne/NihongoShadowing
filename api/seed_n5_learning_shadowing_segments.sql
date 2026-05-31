

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

START TRANSACTION;

DELETE FROM segment_topic_categories
WHERE segment_topic_id BETWEEN 9101 AND 9112;
DELETE FROM shadowing_segments
WHERE topic_id BETWEEN 8101 AND 8112
   OR segment_topic_id BETWEEN 9101 AND 9112;

DELETE FROM vocabularies
WHERE lesson_id BETWEEN 6101 AND 6112
   OR topic_id BETWEEN 8101 AND 8112;

DELETE FROM shadowing_topics
WHERE id BETWEEN 8101 AND 8112;

DELETE FROM lessons
WHERE id BETWEEN 6101 AND 6112;

DELETE FROM segment_topics
WHERE id BETWEEN 9101 AND 9112;

SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------
-- Categories
-- ---------------------------------------------------------
INSERT IGNORE INTO categories (name, description) VALUES
('Giao tiếp', 'Các mẫu hội thoại thông dụng hằng ngày'),
('Mua sắm', 'Câu nói dùng khi mua hàng, hỏi giá và thanh toán'),
('Nhà hàng', 'Gọi món, hỏi thực đơn và thanh toán tại quán ăn'),
('Du lịch', 'Di chuyển, hỏi đường, khách sạn và địa điểm'),
('Giáo dục', 'Tình huống lớp học, bài tập và luyện tập'),
('Đời sống', 'Sinh hoạt cá nhân, gia đình, thời gian và thói quen');

-- ---------------------------------------------------------
-- Segment topics
-- ---------------------------------------------------------
INSERT INTO segment_topics (id, title, description, image_url, level) VALUES
(9101, 'Chào hỏi cơ bản', 'Luyện chào hỏi, giới thiệu tên và mở đầu cuộc trò chuyện.', 'https://picsum.photos/seed/n5-greetings/900/500', 'N5'),
(9102, 'Giới thiệu bản thân', 'Nói tên, quốc tịch, nghề nghiệp và thông tin cá nhân đơn giản.', 'https://picsum.photos/seed/n5-self-intro/900/500', 'N5'),
(9103, 'Hỏi giờ và lịch hẹn', 'Hỏi thời gian, xác nhận lịch học và lịch gặp.', 'https://picsum.photos/seed/n5-time/900/500', 'N5'),
(9104, 'Mua sắm tại cửa hàng', 'Hỏi giá, chọn món đồ và thanh toán.', 'https://picsum.photos/seed/n5-shopping/900/500', 'N5'),
(9105, 'Gọi món ở nhà hàng', 'Gọi món, hỏi đồ uống và thanh toán tại nhà hàng.', 'https://picsum.photos/seed/n5-restaurant/900/500', 'N5'),
(9106, 'Hỏi đường', 'Hỏi vị trí nhà ga, rẽ trái/phải và xác nhận đường đi.', 'https://picsum.photos/seed/n5-directions/900/500', 'N5'),
(9107, 'Đi học', 'Nói về lớp học, giáo viên, bài tập và việc học tiếng Nhật.', 'https://picsum.photos/seed/n5-school/900/500', 'N5'),
(9108, 'Sinh hoạt hằng ngày', 'Nói về giờ thức dậy, ăn sáng, đi làm và nghỉ ngơi.', 'https://picsum.photos/seed/n5-daily-life/900/500', 'N5'),
(9109, 'Gia đình', 'Giới thiệu thành viên gia đình và nói về nghề nghiệp.', 'https://picsum.photos/seed/n5-family/900/500', 'N5'),
(9110, 'Thời tiết', 'Nói về trời nắng, mưa, lạnh, nóng và kế hoạch trong ngày.', 'https://picsum.photos/seed/n5-weather/900/500', 'N5'),
(9111, 'Sở thích', 'Nói về âm nhạc, phim, thể thao và hoạt động cuối tuần.', 'https://picsum.photos/seed/n5-hobby/900/500', 'N5'),
(9112, 'Ôn tập hội thoại N5', 'Tổng hợp các mẫu câu N5 thường gặp trong hội thoại ngắn.', 'https://picsum.photos/seed/n5-review/900/500', 'N5');

-- ---------------------------------------------------------
-- Segment topic categories
-- ---------------------------------------------------------
INSERT INTO segment_topic_categories (segment_topic_id, category_id)
SELECT 9101, id FROM categories WHERE name = 'Giao tiếp'
UNION ALL SELECT 9102, id FROM categories WHERE name = 'Giao tiếp'
UNION ALL SELECT 9103, id FROM categories WHERE name = 'Đời sống'
UNION ALL SELECT 9104, id FROM categories WHERE name = 'Mua sắm'
UNION ALL SELECT 9105, id FROM categories WHERE name = 'Nhà hàng'
UNION ALL SELECT 9106, id FROM categories WHERE name = 'Du lịch'
UNION ALL SELECT 9107, id FROM categories WHERE name = 'Giáo dục'
UNION ALL SELECT 9108, id FROM categories WHERE name = 'Đời sống'
UNION ALL SELECT 9109, id FROM categories WHERE name = 'Đời sống'
UNION ALL SELECT 9110, id FROM categories WHERE name = 'Đời sống'
UNION ALL SELECT 9111, id FROM categories WHERE name = 'Đời sống'
UNION ALL SELECT 9112, id FROM categories WHERE name = 'Giao tiếp';

-- ---------------------------------------------------------
-- Lessons
-- ---------------------------------------------------------
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6101, 'N5', 'N5 Bài 1 - Chào hỏi cơ bản', 1),
(6102, 'N5', 'N5 Bài 2 - Giới thiệu bản thân', 2),
(6103, 'N5', 'N5 Bài 3 - Hỏi giờ và lịch hẹn', 3),
(6104, 'N5', 'N5 Bài 4 - Mua sắm tại cửa hàng', 4),
(6105, 'N5', 'N5 Bài 5 - Gọi món ở nhà hàng', 5),
(6106, 'N5', 'N5 Bài 6 - Hỏi đường', 6),
(6107, 'N5', 'N5 Bài 7 - Đi học', 7),
(6108, 'N5', 'N5 Bài 8 - Sinh hoạt hằng ngày', 8),
(6109, 'N5', 'N5 Bài 9 - Gia đình', 9),
(6110, 'N5', 'N5 Bài 10 - Thời tiết', 10),
(6111, 'N5', 'N5 Bài 11 - Sở thích', 11),
(6112, 'N5', 'N5 Bài 12 - Ôn tập hội thoại N5', 12);

-- ---------------------------------------------------------
-- Shadowing topics
-- ---------------------------------------------------------
INSERT INTO shadowing_topics (id, title, level, lesson_id, image_url, full_script_ja, total_duration) VALUES
(8101, 'Shadowing N5 - Chào hỏi cơ bản', 'N5', 6101, 'https://picsum.photos/seed/n5-greetings/900/500', 'こんにちは。はじめまして。わたしはアンです。どうぞよろしくお願いします。', 16.0),
(8102, 'Shadowing N5 - Giới thiệu bản thân', 'N5', 6102, 'https://picsum.photos/seed/n5-self-intro/900/500', 'わたしはベトナム人です。学生です。日本語を勉強しています。よろしくお願いします。', 18.0),
(8103, 'Shadowing N5 - Hỏi giờ và lịch hẹn', 'N5', 6103, 'https://picsum.photos/seed/n5-time/900/500', '今、何時ですか。九時です。授業は十時からです。駅で会いましょう。', 18.0),
(8104, 'Shadowing N5 - Mua sắm tại cửa hàng', 'N5', 6104, 'https://picsum.photos/seed/n5-shopping/900/500', 'すみません、これはいくらですか。五百円です。これをください。ありがとうございます。', 20.0),
(8105, 'Shadowing N5 - Gọi món ở nhà hàng', 'N5', 6105, 'https://picsum.photos/seed/n5-restaurant/900/500', 'メニューをお願いします。水をください。ラーメンを一つお願いします。お会計をお願いします。', 22.0),
(8106, 'Shadowing N5 - Hỏi đường', 'N5', 6106, 'https://picsum.photos/seed/n5-directions/900/500', '駅はどこですか。まっすぐ行ってください。右に曲がってください。駅は左です。', 20.0),
(8107, 'Shadowing N5 - Đi học', 'N5', 6107, 'https://picsum.photos/seed/n5-school/900/500', '今日は日本語の授業があります。先生は親切です。宿題をしました。よく聞いてください。', 21.0),
(8108, 'Shadowing N5 - Sinh hoạt hằng ngày', 'N5', 6108, 'https://picsum.photos/seed/n5-daily-life/900/500', '毎朝六時に起きます。朝ごはんを食べます。会社へ行きます。夜、休みます。', 21.0),
(8109, 'Shadowing N5 - Gia đình', 'N5', 6109, 'https://picsum.photos/seed/n5-family/900/500', 'わたしの家族は四人です。父は会社員です。母は先生です。妹は学生です。', 19.0),
(8110, 'Shadowing N5 - Thời tiết', 'N5', 6110, 'https://picsum.photos/seed/n5-weather/900/500', '今日はいい天気です。少し暑いです。明日は雨です。傘を持って行きます。', 19.0),
(8111, 'Shadowing N5 - Sở thích', 'N5', 6111, 'https://picsum.photos/seed/n5-hobby/900/500', 'わたしの趣味は音楽です。週末に映画を見ます。友だちとサッカーをします。', 20.0),
(8112, 'Shadowing N5 - Ôn tập hội thoại', 'N5', 6112, 'https://picsum.photos/seed/n5-review/900/500', 'こんにちは。お元気ですか。はい、元気です。明日、一緒に勉強しましょう。', 18.0);

-- ---------------------------------------------------------
-- Shadowing segments
-- ---------------------------------------------------------
INSERT INTO shadowing_segments
(topic_id, segment_topic_id, title, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi, image_url)
VALUES
(8101, 9101, 'Chào buổi gặp đầu tiên', 1, 0.0, 4.0, 'こんにちは。', 'こんにちは。', 'Konnichiwa.', NULL, 'Xin chào.', 'https://picsum.photos/seed/n5-greetings-1/900/500'),
(8101, 9101, 'Rất vui được gặp bạn', 2, 4.0, 8.0, 'はじめまして。', 'はじめまして。', 'Hajimemashite.', NULL, 'Rất vui được gặp bạn lần đầu.', 'https://picsum.photos/seed/n5-greetings-2/900/500'),
(8101, 9102, 'Nói tên của mình', 3, 8.0, 12.0, 'わたしはアンです。', 'わたしはアンです。', 'Watashi wa An desu.', NULL, 'Tôi là An.', 'https://picsum.photos/seed/n5-greetings-3/900/500'),
(8101, 9101, 'Kết thúc lời chào', 4, 12.0, 16.0, 'どうぞよろしくお願いします。', 'どうぞよろしくおねがいします。', 'Douzo yoroshiku onegaishimasu.', NULL, 'Rất mong được giúp đỡ.', 'https://picsum.photos/seed/n5-greetings-4/900/500'),

(8102, 9102, 'Nói quốc tịch', 1, 0.0, 4.5, 'わたしはベトナム人です。', 'わたしはベトナムじんです。', 'Watashi wa Betonamu-jin desu.', NULL, 'Tôi là người Việt Nam.', 'https://picsum.photos/seed/n5-self-intro-1/900/500'),
(8102, 9102, 'Nói nghề nghiệp', 2, 4.5, 8.0, '学生です。', 'がくせいです。', 'Gakusei desu.', NULL, 'Tôi là học sinh/sinh viên.', 'https://picsum.photos/seed/n5-self-intro-2/900/500'),
(8102, 9107, 'Nói việc đang học', 3, 8.0, 13.0, '日本語を勉強しています。', 'にほんごをべんきょうしています。', 'Nihongo o benkyou shiteimasu.', NULL, 'Tôi đang học tiếng Nhật.', 'https://picsum.photos/seed/n5-self-intro-3/900/500'),
(8102, 9101, 'Kết thúc giới thiệu', 4, 13.0, 18.0, 'よろしくお願いします。', 'よろしくおねがいします。', 'Yoroshiku onegaishimasu.', NULL, 'Mong được giúp đỡ.', 'https://picsum.photos/seed/n5-self-intro-4/900/500'),

(8103, 9103, 'Hỏi giờ hiện tại', 1, 0.0, 4.5, '今、何時ですか。', 'いま、なんじですか。', 'Ima, nanji desu ka.', NULL, 'Bây giờ là mấy giờ?', 'https://picsum.photos/seed/n5-time-1/900/500'),
(8103, 9103, 'Trả lời giờ', 2, 4.5, 8.0, '九時です。', 'くじです。', 'Kuji desu.', NULL, 'Là 9 giờ.', 'https://picsum.photos/seed/n5-time-2/900/500'),
(8103, 9107, 'Nói thời gian lớp học', 3, 8.0, 13.0, '授業は十時からです。', 'じゅぎょうはじゅうじからです。', 'Jugyou wa juuji kara desu.', NULL, 'Lớp học bắt đầu từ 10 giờ.', 'https://picsum.photos/seed/n5-time-3/900/500'),
(8103, 9106, 'Hẹn gặp ở ga', 4, 13.0, 18.0, '駅で会いましょう。', 'えきであいましょう。', 'Eki de aimashou.', NULL, 'Hãy gặp nhau ở nhà ga.', 'https://picsum.photos/seed/n5-time-4/900/500'),

(8104, 9104, 'Gọi nhân viên', 1, 0.0, 4.0, 'すみません。', 'すみません。', 'Sumimasen.', NULL, 'Xin lỗi / cho tôi hỏi.', 'https://picsum.photos/seed/n5-shopping-1/900/500'),
(8104, 9104, 'Hỏi giá', 2, 4.0, 9.0, 'これはいくらですか。', 'これはいくらですか。', 'Kore wa ikura desu ka.', NULL, 'Cái này bao nhiêu tiền?', 'https://picsum.photos/seed/n5-shopping-2/900/500'),
(8104, 9104, 'Nghe giá tiền', 3, 9.0, 14.0, '五百円です。', 'ごひゃくえんです。', 'Gohyaku-en desu.', NULL, 'Là 500 yên.', 'https://picsum.photos/seed/n5-shopping-3/900/500'),
(8104, 9104, 'Mua món đồ', 4, 14.0, 20.0, 'これをください。ありがとうございます。', 'これをください。ありがとうございます。', 'Kore o kudasai. Arigatou gozaimasu.', NULL, 'Cho tôi cái này. Cảm ơn.', 'https://picsum.photos/seed/n5-shopping-4/900/500'),

(8105, 9105, 'Xin thực đơn', 1, 0.0, 5.0, 'メニューをお願いします。', 'メニューをおねがいします。', 'Menyuu o onegaishimasu.', NULL, 'Cho tôi xin thực đơn.', 'https://picsum.photos/seed/n5-restaurant-1/900/500'),
(8105, 9105, 'Xin nước', 2, 5.0, 10.0, '水をください。', 'みずをください。', 'Mizu o kudasai.', NULL, 'Cho tôi nước.', 'https://picsum.photos/seed/n5-restaurant-2/900/500'),
(8105, 9105, 'Gọi món ăn', 3, 10.0, 16.0, 'ラーメンを一つお願いします。', 'ラーメンをひとつおねがいします。', 'Raamen o hitotsu onegaishimasu.', NULL, 'Cho tôi một phần ramen.', 'https://picsum.photos/seed/n5-restaurant-3/900/500'),
(8105, 9105, 'Xin thanh toán', 4, 16.0, 22.0, 'お会計をお願いします。', 'おかいけいをおねがいします。', 'Okaikei o onegaishimasu.', NULL, 'Cho tôi thanh toán.', 'https://picsum.photos/seed/n5-restaurant-4/900/500'),

(8106, 9106, 'Hỏi nhà ga ở đâu', 1, 0.0, 5.0, '駅はどこですか。', 'えきはどこですか。', 'Eki wa doko desu ka.', NULL, 'Nhà ga ở đâu?', 'https://picsum.photos/seed/n5-directions-1/900/500'),
(8106, 9106, 'Đi thẳng', 2, 5.0, 10.0, 'まっすぐ行ってください。', 'まっすぐいってください。', 'Massugu itte kudasai.', NULL, 'Hãy đi thẳng.', 'https://picsum.photos/seed/n5-directions-2/900/500'),
(8106, 9106, 'Rẽ phải', 3, 10.0, 15.0, '右に曲がってください。', 'みぎにまがってください。', 'Migi ni magatte kudasai.', NULL, 'Hãy rẽ phải.', 'https://picsum.photos/seed/n5-directions-3/900/500'),
(8106, 9106, 'Vị trí bên trái', 4, 15.0, 20.0, '駅は左です。', 'えきはひだりです。', 'Eki wa hidari desu.', NULL, 'Nhà ga ở bên trái.', 'https://picsum.photos/seed/n5-directions-4/900/500'),

(8107, 9107, 'Có lớp tiếng Nhật', 1, 0.0, 5.0, '今日は日本語の授業があります。', 'きょうはにほんごのじゅぎょうがあります。', 'Kyou wa nihongo no jugyou ga arimasu.', NULL, 'Hôm nay có lớp tiếng Nhật.', 'https://picsum.photos/seed/n5-school-1/900/500'),
(8107, 9107, 'Nói về giáo viên', 2, 5.0, 10.0, '先生は親切です。', 'せんせいはしんせつです。', 'Sensei wa shinsetsu desu.', NULL, 'Giáo viên thân thiện.', 'https://picsum.photos/seed/n5-school-2/900/500'),
(8107, 9107, 'Nói đã làm bài tập', 3, 10.0, 15.0, '宿題をしました。', 'しゅくだいをしました。', 'Shukudai o shimashita.', NULL, 'Tôi đã làm bài tập.', 'https://picsum.photos/seed/n5-school-3/900/500'),
(8107, 9107, 'Nhắc lắng nghe', 4, 15.0, 21.0, 'よく聞いてください。', 'よくきいてください。', 'Yoku kiite kudasai.', NULL, 'Hãy nghe kỹ.', 'https://picsum.photos/seed/n5-school-4/900/500'),

(8108, 9108, 'Thức dậy buổi sáng', 1, 0.0, 5.0, '毎朝六時に起きます。', 'まいあさろくじにおきます。', 'Maiasa rokuji ni okimasu.', NULL, 'Mỗi sáng tôi thức dậy lúc 6 giờ.', 'https://picsum.photos/seed/n5-daily-life-1/900/500'),
(8108, 9108, 'Ăn sáng', 2, 5.0, 10.0, '朝ごはんを食べます。', 'あさごはんをたべます。', 'Asagohan o tabemasu.', NULL, 'Tôi ăn sáng.', 'https://picsum.photos/seed/n5-daily-life-2/900/500'),
(8108, 9108, 'Đi làm', 3, 10.0, 15.0, '会社へ行きます。', 'かいしゃへいきます。', 'Kaisha e ikimasu.', NULL, 'Tôi đi đến công ty.', 'https://picsum.photos/seed/n5-daily-life-3/900/500'),
(8108, 9108, 'Nghỉ ngơi buổi tối', 4, 15.0, 21.0, '夜、休みます。', 'よる、やすみます。', 'Yoru, yasumimasu.', NULL, 'Buổi tối tôi nghỉ ngơi.', 'https://picsum.photos/seed/n5-daily-life-4/900/500'),

(8109, 9109, 'Số người trong gia đình', 1, 0.0, 5.0, 'わたしの家族は四人です。', 'わたしのかぞくはよにんです。', 'Watashi no kazoku wa yonin desu.', NULL, 'Gia đình tôi có 4 người.', 'https://picsum.photos/seed/n5-family-1/900/500'),
(8109, 9109, 'Nghề của bố', 2, 5.0, 10.0, '父は会社員です。', 'ちちはかいしゃいんです。', 'Chichi wa kaishain desu.', NULL, 'Bố tôi là nhân viên công ty.', 'https://picsum.photos/seed/n5-family-2/900/500'),
(8109, 9109, 'Nghề của mẹ', 3, 10.0, 15.0, '母は先生です。', 'はははせんせいです。', 'Haha wa sensei desu.', NULL, 'Mẹ tôi là giáo viên.', 'https://picsum.photos/seed/n5-family-3/900/500'),
(8109, 9109, 'Nói về em gái', 4, 15.0, 19.0, '妹は学生です。', 'いもうとはがくせいです。', 'Imouto wa gakusei desu.', NULL, 'Em gái tôi là học sinh/sinh viên.', 'https://picsum.photos/seed/n5-family-4/900/500'),

(8110, 9110, 'Thời tiết hôm nay', 1, 0.0, 5.0, '今日はいい天気です。', 'きょうはいいてんきです。', 'Kyou wa ii tenki desu.', NULL, 'Hôm nay thời tiết đẹp.', 'https://picsum.photos/seed/n5-weather-1/900/500'),
(8110, 9110, 'Trời hơi nóng', 2, 5.0, 9.0, '少し暑いです。', 'すこしあついです。', 'Sukoshi atsui desu.', NULL, 'Trời hơi nóng.', 'https://picsum.photos/seed/n5-weather-2/900/500'),
(8110, 9110, 'Ngày mai trời mưa', 3, 9.0, 14.0, '明日は雨です。', 'あしたはあめです。', 'Ashita wa ame desu.', NULL, 'Ngày mai trời mưa.', 'https://picsum.photos/seed/n5-weather-3/900/500'),
(8110, 9110, 'Mang ô', 4, 14.0, 19.0, '傘を持って行きます。', 'かさをもっていきます。', 'Kasa o motte ikimasu.', NULL, 'Tôi sẽ mang ô đi.', 'https://picsum.photos/seed/n5-weather-4/900/500'),

(8111, 9111, 'Nói sở thích', 1, 0.0, 5.0, 'わたしの趣味は音楽です。', 'わたしのしゅみはおんがくです。', 'Watashi no shumi wa ongaku desu.', NULL, 'Sở thích của tôi là âm nhạc.', 'https://picsum.photos/seed/n5-hobby-1/900/500'),
(8111, 9111, 'Xem phim cuối tuần', 2, 5.0, 10.0, '週末に映画を見ます。', 'しゅうまつにえいがをみます。', 'Shuumatsu ni eiga o mimasu.', NULL, 'Cuối tuần tôi xem phim.', 'https://picsum.photos/seed/n5-hobby-2/900/500'),
(8111, 9111, 'Chơi bóng đá', 3, 10.0, 15.0, '友だちとサッカーをします。', 'ともだちとサッカーをします。', 'Tomodachi to sakkaa o shimasu.', NULL, 'Tôi chơi bóng đá với bạn.', 'https://picsum.photos/seed/n5-hobby-3/900/500'),
(8111, 9111, 'Rất vui', 4, 15.0, 20.0, 'とても楽しいです。', 'とてもたのしいです。', 'Totemo tanoshii desu.', NULL, 'Rất vui.', 'https://picsum.photos/seed/n5-hobby-4/900/500'),

(8112, 9112, 'Chào hỏi ôn tập', 1, 0.0, 4.5, 'こんにちは。', 'こんにちは。', 'Konnichiwa.', NULL, 'Xin chào.', 'https://picsum.photos/seed/n5-review-1/900/500'),
(8112, 9112, 'Hỏi sức khỏe', 2, 4.5, 9.0, 'お元気ですか。', 'おげんきですか。', 'Ogenki desu ka.', NULL, 'Bạn khỏe không?', 'https://picsum.photos/seed/n5-review-2/900/500'),
(8112, 9112, 'Trả lời sức khỏe', 3, 9.0, 13.0, 'はい、元気です。', 'はい、げんきです。', 'Hai, genki desu.', NULL, 'Vâng, tôi khỏe.', 'https://picsum.photos/seed/n5-review-3/900/500'),
(8112, 9112, 'Rủ học cùng', 4, 13.0, 18.0, '明日、一緒に勉強しましょう。', 'あした、いっしょにべんきょうしましょう。', 'Ashita, issho ni benkyou shimashou.', NULL, 'Ngày mai hãy cùng học nhé.', 'https://picsum.photos/seed/n5-review-4/900/500');

-- ---------------------------------------------------------
-- Vocabulary
-- ---------------------------------------------------------
INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6101, 8101, 'こんにちは', 'こんにちは', 'Xin chào', 'こんにちは。はじめまして。'),
(6101, 8101, 'はじめまして', 'はじめまして', 'Rất vui được gặp lần đầu', 'はじめまして。アンです。'),
(6101, 8101, 'わたし', 'わたし', 'Tôi', 'わたしはアンです。'),
(6101, 8101, 'お願いします', 'おねがいします', 'Xin nhờ / mong được giúp đỡ', 'どうぞよろしくお願いします。'),
(6101, 8101, '名前', 'なまえ', 'Tên', 'お名前は何ですか。'),

(6102, 8102, 'ベトナム人', 'ベトナムじん', 'Người Việt Nam', 'わたしはベトナム人です。'),
(6102, 8102, '学生', 'がくせい', 'Học sinh / sinh viên', '学生です。'),
(6102, 8102, '日本語', 'にほんご', 'Tiếng Nhật', '日本語を勉強しています。'),
(6102, 8102, '勉強します', 'べんきょうします', 'Học', '毎日勉強します。'),
(6102, 8102, '国', 'くに', 'Đất nước', 'お国はどちらですか。'),

(6103, 8103, '今', 'いま', 'Bây giờ', '今、何時ですか。'),
(6103, 8103, '何時', 'なんじ', 'Mấy giờ', '何時に行きますか。'),
(6103, 8103, '九時', 'くじ', '9 giờ', '九時です。'),
(6103, 8103, '授業', 'じゅぎょう', 'Lớp học', '授業は十時からです。'),
(6103, 8103, '駅', 'えき', 'Nhà ga', '駅で会いましょう。'),

(6104, 8104, 'いくら', 'いくら', 'Bao nhiêu tiền', 'これはいくらですか。'),
(6104, 8104, '円', 'えん', 'Yên', '五百円です。'),
(6104, 8104, 'これ', 'これ', 'Cái này', 'これをください。'),
(6104, 8104, 'ください', 'ください', 'Xin cho tôi', '水をください。'),
(6104, 8104, 'ありがとうございます', 'ありがとうございます', 'Cảm ơn', 'ありがとうございます。'),

(6105, 8105, 'メニュー', 'メニュー', 'Thực đơn', 'メニューをお願いします。'),
(6105, 8105, '水', 'みず', 'Nước', '水をください。'),
(6105, 8105, 'ラーメン', 'ラーメン', 'Mì ramen', 'ラーメンを一つお願いします。'),
(6105, 8105, '一つ', 'ひとつ', 'Một cái / một phần', '一つください。'),
(6105, 8105, 'お会計', 'おかいけい', 'Thanh toán', 'お会計をお願いします。'),

(6106, 8106, 'どこ', 'どこ', 'Ở đâu', '駅はどこですか。'),
(6106, 8106, 'まっすぐ', 'まっすぐ', 'Đi thẳng', 'まっすぐ行ってください。'),
(6106, 8106, '右', 'みぎ', 'Bên phải', '右に曲がってください。'),
(6106, 8106, '左', 'ひだり', 'Bên trái', '駅は左です。'),
(6106, 8106, '曲がります', 'まがります', 'Rẽ', '右に曲がります。'),

(6107, 8107, '今日', 'きょう', 'Hôm nay', '今日は授業があります。'),
(6107, 8107, '先生', 'せんせい', 'Giáo viên', '先生は親切です。'),
(6107, 8107, '親切', 'しんせつ', 'Tốt bụng / thân thiện', '親切な人です。'),
(6107, 8107, '宿題', 'しゅくだい', 'Bài tập về nhà', '宿題をしました。'),
(6107, 8107, '聞きます', 'ききます', 'Nghe / hỏi', 'よく聞いてください。'),

(6108, 8108, '毎朝', 'まいあさ', 'Mỗi sáng', '毎朝六時に起きます。'),
(6108, 8108, '起きます', 'おきます', 'Thức dậy', '六時に起きます。'),
(6108, 8108, '朝ごはん', 'あさごはん', 'Bữa sáng', '朝ごはんを食べます。'),
(6108, 8108, '会社', 'かいしゃ', 'Công ty', '会社へ行きます。'),
(6108, 8108, '休みます', 'やすみます', 'Nghỉ ngơi', '夜、休みます。'),

(6109, 8109, '家族', 'かぞく', 'Gia đình', 'わたしの家族は四人です。'),
(6109, 8109, '四人', 'よにん', 'Bốn người', '家族は四人です。'),
(6109, 8109, '父', 'ちち', 'Bố tôi', '父は会社員です。'),
(6109, 8109, '母', 'はは', 'Mẹ tôi', '母は先生です。'),
(6109, 8109, '妹', 'いもうと', 'Em gái', '妹は学生です。'),

(6110, 8110, '天気', 'てんき', 'Thời tiết', '今日はいい天気です。'),
(6110, 8110, '暑い', 'あつい', 'Nóng', '少し暑いです。'),
(6110, 8110, '明日', 'あした', 'Ngày mai', '明日は雨です。'),
(6110, 8110, '雨', 'あめ', 'Mưa', '雨です。'),
(6110, 8110, '傘', 'かさ', 'Ô / dù', '傘を持って行きます。'),

(6111, 8111, '趣味', 'しゅみ', 'Sở thích', 'わたしの趣味は音楽です。'),
(6111, 8111, '音楽', 'おんがく', 'Âm nhạc', '音楽が好きです。'),
(6111, 8111, '週末', 'しゅうまつ', 'Cuối tuần', '週末に映画を見ます。'),
(6111, 8111, '映画', 'えいが', 'Phim', '映画を見ます。'),
(6111, 8111, '友だち', 'ともだち', 'Bạn bè', '友だちとサッカーをします。'),

(6112, 8112, '元気', 'げんき', 'Khỏe / khỏe mạnh', 'お元気ですか。'),
(6112, 8112, 'はい', 'はい', 'Vâng', 'はい、元気です。'),
(6112, 8112, '一緒に', 'いっしょに', 'Cùng nhau', '一緒に勉強しましょう。'),
(6112, 8112, '明日', 'あした', 'Ngày mai', '明日、会いましょう。'),
(6112, 8112, 'しましょう', 'しましょう', 'Hãy cùng làm', '勉強しましょう。');

COMMIT;

-- ---------------------------------------------------------
-- Quick checks
-- ---------------------------------------------------------
SELECT 'lessons' AS table_name, COUNT(*) AS row_count
FROM lessons
WHERE id BETWEEN 6101 AND 6112
UNION ALL
SELECT 'shadowing_topics', COUNT(*)
FROM shadowing_topics
WHERE id BETWEEN 8101 AND 8112
UNION ALL
SELECT 'segment_topics', COUNT(*)
FROM segment_topics
WHERE id BETWEEN 9101 AND 9112
UNION ALL
SELECT 'shadowing_segments', COUNT(*)
FROM shadowing_segments
WHERE topic_id BETWEEN 8101 AND 8112
   OR segment_topic_id BETWEEN 9101 AND 9112
UNION ALL
SELECT 'vocabularies', COUNT(*)
FROM vocabularies
WHERE lesson_id BETWEEN 6101 AND 6112
   OR topic_id BETWEEN 8101 AND 8112;

