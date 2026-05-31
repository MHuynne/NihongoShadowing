-- =========================================================
-- ADDITIONAL SEED: 1 N5 LESSON + 25 N4 LESSONS
-- Database target: nihongo_learning1
-- Charset: utf8mb4
--
-- Managed ID ranges:
--   N5 extra lesson:       lesson 6113, topic 8113, segment_topic 9113
--   N4 lessons:            lessons 6201-6225
--   N4 shadowing topics:   topics 8201-8225
--   N4 segment topics:     segment_topics 9201-9225
--
-- Each shadowing topic has exactly 2 shadowing_segments.
-- Safe to re-run. Only managed ID ranges are deleted/recreated.
-- =========================================================

SET NAMES utf8mb4;
SET @OLD_SQL_SAFE_UPDATES := @@SQL_SAFE_UPDATES;
SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS = 0;

START TRANSACTION;

DELETE FROM segment_topic_categories
WHERE segment_topic_id = 9113
   OR segment_topic_id BETWEEN 9201 AND 9225;

DELETE FROM shadowing_segments
WHERE id IN (
    SELECT id FROM (
        SELECT id
        FROM shadowing_segments
        WHERE topic_id = 8113
           OR topic_id BETWEEN 8201 AND 8225
           OR segment_topic_id = 9113
           OR segment_topic_id BETWEEN 9201 AND 9225
    ) AS managed_shadowing_segment_ids
);

DELETE FROM vocabularies
WHERE id IN (
    SELECT id FROM (
        SELECT id
        FROM vocabularies
        WHERE lesson_id = 6113
           OR lesson_id BETWEEN 6201 AND 6225
           OR topic_id = 8113
           OR topic_id BETWEEN 8201 AND 8225
    ) AS managed_vocabulary_ids
);

DELETE FROM shadowing_topics
WHERE id = 8113
   OR id BETWEEN 8201 AND 8225;

DELETE FROM lessons
WHERE id = 6113
   OR id BETWEEN 6201 AND 6225;

DELETE FROM segment_topics
WHERE id = 9113
   OR id BETWEEN 9201 AND 9225;

SET FOREIGN_KEY_CHECKS = 1;

INSERT IGNORE INTO categories (name, description) VALUES
('Giao tiếp', 'Các mẫu hội thoại thông dụng hằng ngày'),
('Mua sắm', 'Câu nói dùng khi mua hàng, hỏi giá và thanh toán'),
('Nhà hàng', 'Gọi món, hỏi thực đơn và thanh toán tại quán ăn'),
('Du lịch', 'Di chuyển, hỏi đường, khách sạn và địa điểm'),
('Giáo dục', 'Tình huống lớp học, bài tập và luyện tập'),
('Đời sống', 'Sinh hoạt cá nhân, gia đình, thời gian và thói quen'),
('Công việc', 'Mẫu câu dùng trong văn phòng và công việc đơn giản');

-- ---------------------------------------------------------
-- 1 extra N5 lesson
-- ---------------------------------------------------------
INSERT INTO segment_topics (id, title, description, image_url, level) VALUES
(9113, 'N5 - Hẹn gặp bạn bè', 'Luyện rủ bạn gặp nhau và xác nhận địa điểm đơn giản.', 'https://picsum.photos/seed/n5-meet-friend/900/500', 'N5');

INSERT INTO segment_topic_categories (segment_topic_id, category_id)
SELECT 9113, id FROM categories WHERE name = 'Giao tiếp';

INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6113, 'N5', 'N5 Bài 13 - Hẹn gặp bạn bè', 13);

INSERT INTO shadowing_topics (id, title, level, lesson_id, image_url, full_script_ja, total_duration) VALUES
(8113, 'Shadowing N5 - Hẹn gặp bạn bè', 'N5', 6113, 'https://picsum.photos/seed/n5-meet-friend/900/500', '明日、駅で会いましょう。三時はどうですか。', 10.0);

INSERT INTO shadowing_segments
(topic_id, segment_topic_id, title, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi, image_url)
VALUES
(8113, 9113, 'Rủ gặp ở nhà ga', 1, 0.0, 5.0, '明日、駅で会いましょう。', 'あした、えきであいましょう。', 'Ashita, eki de aimashou.', NULL, 'Ngày mai hãy gặp nhau ở nhà ga.', 'https://picsum.photos/seed/n5-meet-friend-1/900/500'),
(8113, 9113, 'Xác nhận thời gian', 2, 5.0, 10.0, '三時はどうですか。', 'さんじはどうですか。', 'Sanji wa dou desu ka.', NULL, 'Ba giờ thì thế nào?', 'https://picsum.photos/seed/n5-meet-friend-2/900/500');

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6113, 8113, '明日', 'あした', 'Ngày mai', '明日、会いましょう。'),
(6113, 8113, '駅', 'えき', 'Nhà ga', '駅で会いましょう。'),
(6113, 8113, '会います', 'あいます', 'Gặp', '友だちに会います。'),
(6113, 8113, '三時', 'さんじ', 'Ba giờ', '三時はどうですか。'),
(6113, 8113, 'どうですか', 'どうですか', 'Thế nào?', 'これはどうですか。');

-- ---------------------------------------------------------
-- 25 N4 lessons
-- ---------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_n4_seed;
CREATE TEMPORARY TABLE tmp_n4_seed (
    idx INT PRIMARY KEY,
    segment_topic_id INT NOT NULL,
    lesson_id INT NOT NULL,
    topic_id INT NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    theme_vi VARCHAR(100) NOT NULL,
    topic_title VARCHAR(255) NOT NULL,
    sentence_1 VARCHAR(255) NOT NULL,
    furigana_1 VARCHAR(255) NOT NULL,
    romaji_1 VARCHAR(255) NOT NULL,
    translation_1 VARCHAR(255) NOT NULL,
    sentence_2 VARCHAR(255) NOT NULL,
    furigana_2 VARCHAR(255) NOT NULL,
    romaji_2 VARCHAR(255) NOT NULL,
    translation_2 VARCHAR(255) NOT NULL,
    vocab_1 VARCHAR(50) NOT NULL,
    reading_1 VARCHAR(50) NOT NULL,
    meaning_1 VARCHAR(100) NOT NULL,
    vocab_2 VARCHAR(50) NOT NULL,
    reading_2 VARCHAR(50) NOT NULL,
    meaning_2 VARCHAR(100) NOT NULL,
    vocab_3 VARCHAR(50) NOT NULL,
    reading_3 VARCHAR(50) NOT NULL,
    meaning_3 VARCHAR(100) NOT NULL,
    vocab_4 VARCHAR(50) NOT NULL,
    reading_4 VARCHAR(50) NOT NULL,
    meaning_4 VARCHAR(100) NOT NULL,
    vocab_5 VARCHAR(50) NOT NULL,
    reading_5 VARCHAR(50) NOT NULL,
    meaning_5 VARCHAR(100) NOT NULL
) CHARACTER SET utf8mb4;

INSERT INTO tmp_n4_seed VALUES
(1, 9201, 6201, 8201, 'Giao tiếp', 'Xin phép và nhờ giúp đỡ', 'N4 Bài 1 - Xin phép và nhờ giúp đỡ', 'この写真を撮ってもいいですか。', 'このしゃしんをとってもいいですか。', 'Kono shashin o totte mo ii desu ka.', 'Tôi chụp bức ảnh này được không?', 'すみません、少し手伝っていただけませんか。', 'すみません、すこしてつだっていただけませんか。', 'Sumimasen, sukoshi tetsudatte itadakemasen ka.', 'Xin lỗi, bạn có thể giúp tôi một chút được không?', '写真', 'しゃしん', 'Ảnh', '撮ります', 'とります', 'Chụp', '手伝います', 'てつだいます', 'Giúp đỡ', '少し', 'すこし', 'Một chút', 'いただけませんか', 'いただけませんか', 'Có thể làm giúp tôi không'),
(2, 9202, 6202, 8202, 'Du lịch', 'Hỏi đường lịch sự', 'N4 Bài 2 - Hỏi đường lịch sự', '駅へ行きたいんですが、道を教えてください。', 'えきへいきたいんですが、みちをおしえてください。', 'Eki e ikitain desu ga, michi o oshiete kudasai.', 'Tôi muốn đi đến nhà ga, xin hãy chỉ đường.', 'この道をまっすぐ行くと、右にあります。', 'このみちをまっすぐいくと、みぎにあります。', 'Kono michi o massugu iku to, migi ni arimasu.', 'Nếu đi thẳng đường này thì nó ở bên phải.', '駅', 'えき', 'Nhà ga', '道', 'みち', 'Đường', '教えます', 'おしえます', 'Chỉ / dạy', 'まっすぐ', 'まっすぐ', 'Thẳng', '右', 'みぎ', 'Bên phải'),
(3, 9203, 6203, 8203, 'Nhà hàng', 'Đặt món và yêu cầu', 'N4 Bài 3 - Đặt món và yêu cầu', 'おすすめの料理は何ですか。', 'おすすめのりょうりはなんですか。', 'Osusume no ryouri wa nan desu ka.', 'Món ăn được gợi ý là gì?', '辛くしないでください。', 'からくしないでください。', 'Karaku shinaide kudasai.', 'Xin đừng làm cay.', 'おすすめ', 'おすすめ', 'Gợi ý', '料理', 'りょうり', 'Món ăn', '辛い', 'からい', 'Cay', 'ください', 'ください', 'Xin hãy', '何', 'なん', 'Cái gì'),
(4, 9204, 6204, 8204, 'Mua sắm', 'Đổi trả hàng', 'N4 Bài 4 - Đổi trả hàng', 'この服はサイズが合わないんです。', 'このふくはサイズがあわないんです。', 'Kono fuku wa saizu ga awanain desu.', 'Cái áo này không vừa cỡ.', 'ほかのサイズに替えてもらえますか。', 'ほかのサイズにかえてもらえますか。', 'Hoka no saizu ni kaete moraemasu ka.', 'Tôi có thể đổi sang cỡ khác không?', '服', 'ふく', 'Quần áo', 'サイズ', 'サイズ', 'Kích cỡ', '合います', 'あいます', 'Vừa / hợp', '替えます', 'かえます', 'Đổi', 'ほか', 'ほか', 'Khác'),
(5, 9205, 6205, 8205, 'Đời sống', 'Nói lý do đến muộn', 'N4 Bài 5 - Nói lý do đến muộn', '電車が遅れたので、少し遅くなりました。', 'でんしゃがおくれたので、すこしおそくなりました。', 'Densha ga okureta node, sukoshi osoku narimashita.', 'Vì tàu bị trễ nên tôi đến hơi muộn.', '次から気をつけます。', 'つぎからきをつけます。', 'Tsugi kara ki o tsukemasu.', 'Từ lần sau tôi sẽ chú ý.', '電車', 'でんしゃ', 'Tàu điện', '遅れます', 'おくれます', 'Bị trễ', '少し', 'すこし', 'Một chút', '次', 'つぎ', 'Lần sau', '気をつけます', 'きをつけます', 'Chú ý'),
(6, 9206, 6206, 8206, 'Giáo dục', 'Hỏi bài trong lớp', 'N4 Bài 6 - Hỏi bài trong lớp', 'この文法の使い方がよくわかりません。', 'このぶんぽうのつかいかたがよくわかりません。', 'Kono bunpou no tsukaikata ga yoku wakarimasen.', 'Tôi không hiểu rõ cách dùng ngữ pháp này.', 'もう一度説明していただけませんか。', 'もういちどせつめいしていただけませんか。', 'Mou ichido setsumei shite itadakemasen ka.', 'Thầy/cô có thể giải thích lại một lần nữa không?', '文法', 'ぶんぽう', 'Ngữ pháp', '使い方', 'つかいかた', 'Cách dùng', '説明', 'せつめい', 'Giải thích', 'もう一度', 'もういちど', 'Một lần nữa', 'わかります', 'わかります', 'Hiểu'),
(7, 9207, 6207, 8207, 'Công việc', 'Báo cáo công việc', 'N4 Bài 7 - Báo cáo công việc', '資料はもう作ってあります。', 'しりょうはもうつくってあります。', 'Shiryou wa mou tsukutte arimasu.', 'Tài liệu đã được chuẩn bị sẵn rồi.', 'あとでメールで送ります。', 'あとでメールでおくります。', 'Ato de meeru de okurimasu.', 'Lát nữa tôi sẽ gửi bằng email.', '資料', 'しりょう', 'Tài liệu', '作ります', 'つくります', 'Làm / tạo', 'メール', 'メール', 'Email', '送ります', 'おくります', 'Gửi', 'あとで', 'あとで', 'Sau đó'),
(8, 9208, 6208, 8208, 'Đời sống', 'Nói về sức khỏe', 'N4 Bài 8 - Nói về sức khỏe', '昨日から頭が痛いんです。', 'きのうからあたまがいたいんです。', 'Kinou kara atama ga itain desu.', 'Từ hôm qua tôi bị đau đầu.', '今日は早く帰って休みます。', 'きょうははやくかえってやすみます。', 'Kyou wa hayaku kaette yasumimasu.', 'Hôm nay tôi sẽ về sớm và nghỉ ngơi.', '昨日', 'きのう', 'Hôm qua', '頭', 'あたま', 'Đầu', '痛い', 'いたい', 'Đau', '早く', 'はやく', 'Sớm / nhanh', '休みます', 'やすみます', 'Nghỉ ngơi'),
(9, 9209, 6209, 8209, 'Du lịch', 'Đặt phòng khách sạn', 'N4 Bài 9 - Đặt phòng khách sạn', '今晩泊まる部屋はありますか。', 'こんばんとまるへやはありますか。', 'Konban tomaru heya wa arimasu ka.', 'Tối nay còn phòng để ở không?', '朝食は料金に入っていますか。', 'ちょうしょくはりょうきんにはいっていますか。', 'Choushoku wa ryoukin ni haitte imasu ka.', 'Bữa sáng có bao gồm trong giá không?', '今晩', 'こんばん', 'Tối nay', '泊まります', 'とまります', 'Ở lại', '部屋', 'へや', 'Phòng', '朝食', 'ちょうしょく', 'Bữa sáng', '料金', 'りょうきん', 'Giá tiền'),
(10, 9210, 6210, 8210, 'Giao tiếp', 'Mời và từ chối lịch sự', 'N4 Bài 10 - Mời và từ chối lịch sự', '週末、一緒に映画を見に行きませんか。', 'しゅうまつ、いっしょにえいがをみにいきませんか。', 'Shuumatsu, issho ni eiga o mi ni ikimasen ka.', 'Cuối tuần cùng đi xem phim không?', 'すみません、その日は用事があります。', 'すみません、そのひはようじがあります。', 'Sumimasen, sono hi wa youji ga arimasu.', 'Xin lỗi, ngày đó tôi có việc bận.', '週末', 'しゅうまつ', 'Cuối tuần', '一緒に', 'いっしょに', 'Cùng nhau', '映画', 'えいが', 'Phim', '用事', 'ようじ', 'Việc bận', '日', 'ひ', 'Ngày'),
(11, 9211, 6211, 8211, 'Đời sống', 'Nói về thói quen', 'N4 Bài 11 - Nói về thói quen', '毎朝、走ることにしています。', 'まいあさ、はしることにしています。', 'Maiasa, hashiru koto ni shiteimasu.', 'Mỗi sáng tôi có thói quen chạy bộ.', '健康のために続けています。', 'けんこうのためにつづけています。', 'Kenkou no tame ni tsuzuketeimasu.', 'Tôi duy trì vì sức khỏe.', '毎朝', 'まいあさ', 'Mỗi sáng', '走ります', 'はしります', 'Chạy', '健康', 'けんこう', 'Sức khỏe', '続けます', 'つづけます', 'Tiếp tục', 'ために', 'ために', 'Vì / để'),
(12, 9212, 6212, 8212, 'Mua sắm', 'So sánh sản phẩm', 'N4 Bài 12 - So sánh sản phẩm', 'このかばんはあのかばんより軽いです。', 'このかばんはあのかばんよりかるいです。', 'Kono kaban wa ano kaban yori karui desu.', 'Cái cặp này nhẹ hơn cái cặp kia.', 'でも、値段は少し高いです。', 'でも、ねだんはすこしたかいです。', 'Demo, nedan wa sukoshi takai desu.', 'Nhưng giá hơi đắt.', 'かばん', 'かばん', 'Cặp / túi', '軽い', 'かるい', 'Nhẹ', '値段', 'ねだん', 'Giá', '高い', 'たかい', 'Đắt / cao', 'より', 'より', 'Hơn'),
(13, 9213, 6213, 8213, 'Nhà hàng', 'Đặt bàn', 'N4 Bài 13 - Đặt bàn', '今夜七時に二人で予約したいです。', 'こんやしちじにふたりでよやくしたいです。', 'Konya shichiji ni futari de yoyaku shitai desu.', 'Tối nay 7 giờ tôi muốn đặt bàn cho hai người.', '窓の近くの席は空いていますか。', 'まどのちかくのせきはあいていますか。', 'Mado no chikaku no seki wa aiteimasu ka.', 'Chỗ gần cửa sổ còn trống không?', '今夜', 'こんや', 'Tối nay', '二人', 'ふたり', 'Hai người', '予約', 'よやく', 'Đặt trước', '窓', 'まど', 'Cửa sổ', '席', 'せき', 'Chỗ ngồi'),
(14, 9214, 6214, 8214, 'Công việc', 'Xin nghỉ phép', 'N4 Bài 14 - Xin nghỉ phép', '明日、病院へ行くので休ませてください。', 'あした、びょういんへいくのでやすませてください。', 'Ashita, byouin e iku node yasumasete kudasai.', 'Ngày mai vì đi bệnh viện nên xin cho tôi nghỉ.', '仕事は今日中に終わらせます。', 'しごとはきょうじゅうにおわらせます。', 'Shigoto wa kyoujuu ni owarasemasu.', 'Tôi sẽ hoàn thành công việc trong hôm nay.', '病院', 'びょういん', 'Bệnh viện', '休みます', 'やすみます', 'Nghỉ', '仕事', 'しごと', 'Công việc', '今日中', 'きょうじゅう', 'Trong hôm nay', '終わります', 'おわります', 'Kết thúc'),
(15, 9215, 6215, 8215, 'Du lịch', 'Mua vé tàu', 'N4 Bài 15 - Mua vé tàu', '京都までの切符を一枚ください。', 'きょうとまでのきっぷをいちまいください。', 'Kyouto made no kippu o ichimai kudasai.', 'Cho tôi một vé đến Kyoto.', '指定席はありますか。', 'していせきはありますか。', 'Shiteiseki wa arimasu ka.', 'Có ghế đặt trước không?', '京都', 'きょうと', 'Kyoto', '切符', 'きっぷ', 'Vé', '一枚', 'いちまい', 'Một tờ', '指定席', 'していせき', 'Ghế đặt trước', 'あります', 'あります', 'Có'),
(16, 9216, 6216, 8216, 'Giáo dục', 'Nộp bài tập', 'N4 Bài 16 - Nộp bài tập', '宿題を出すのを忘れてしまいました。', 'しゅくだいをだすのをわすれてしまいました。', 'Shukudai o dasu no o wasurete shimaimashita.', 'Tôi lỡ quên nộp bài tập.', '今日の午後までに出してもいいですか。', 'きょうのごごまでにだしてもいいですか。', 'Kyou no gogo made ni dashite mo ii desu ka.', 'Tôi nộp trước chiều nay được không?', '宿題', 'しゅくだい', 'Bài tập', '出します', 'だします', 'Nộp / đưa ra', '忘れます', 'わすれます', 'Quên', '午後', 'ごご', 'Buổi chiều', 'までに', 'までに', 'Trước hạn'),
(17, 9217, 6217, 8217, 'Đời sống', 'Kế hoạch cuối tuần', 'N4 Bài 17 - Kế hoạch cuối tuần', '週末は友だちの家へ遊びに行きます。', 'しゅうまつはともだちのいえへあそびにいきます。', 'Shuumatsu wa tomodachi no ie e asobi ni ikimasu.', 'Cuối tuần tôi sẽ đến nhà bạn chơi.', '雨が降ったら、家で映画を見ます。', 'あめがふったら、いえでえいがをみます。', 'Ame ga futtara, ie de eiga o mimasu.', 'Nếu trời mưa thì tôi xem phim ở nhà.', '週末', 'しゅうまつ', 'Cuối tuần', '友だち', 'ともだち', 'Bạn bè', '遊びます', 'あそびます', 'Chơi', '雨', 'あめ', 'Mưa', '降ります', 'ふります', 'Rơi / mưa'),
(18, 9218, 6218, 8218, 'Giao tiếp', 'Nêu ý kiến', 'N4 Bài 18 - Nêu ý kiến', '私はこの考え方がいいと思います。', 'わたしはこのかんがえかたがいいとおもいます。', 'Watashi wa kono kangaekata ga ii to omoimasu.', 'Tôi nghĩ cách nghĩ này là tốt.', '理由は二つあります。', 'りゆうはふたつあります。', 'Riyuu wa futatsu arimasu.', 'Có hai lý do.', '考え方', 'かんがえかた', 'Cách nghĩ', '思います', 'おもいます', 'Nghĩ', '理由', 'りゆう', 'Lý do', '二つ', 'ふたつ', 'Hai cái', '私', 'わたし', 'Tôi'),
(19, 9219, 6219, 8219, 'Công việc', 'Nhận điện thoại', 'N4 Bài 19 - Nhận điện thoại', '田中さんは今、席を外しています。', 'たなかさんはいま、せきをはずしています。', 'Tanaka-san wa ima, seki o hazushiteimasu.', 'Anh/chị Tanaka hiện đang rời chỗ.', '戻ったら、こちらから電話します。', 'もどったら、こちらからでんわします。', 'Modottara, kochira kara denwa shimasu.', 'Khi quay lại, chúng tôi sẽ gọi điện.', '今', 'いま', 'Bây giờ', '席', 'せき', 'Chỗ ngồi', '外します', 'はずします', 'Rời khỏi', '戻ります', 'もどります', 'Quay lại', '電話', 'でんわ', 'Điện thoại'),
(20, 9220, 6220, 8220, 'Đời sống', 'Nhận xét món ăn', 'N4 Bài 20 - Nhận xét món ăn', 'この料理は見た目よりおいしいです。', 'このりょうりはみためよりおいしいです。', 'Kono ryouri wa mitame yori oishii desu.', 'Món này ngon hơn vẻ ngoài.', '家でも作ってみたいです。', 'いえでもつくってみたいです。', 'Ie demo tsukutte mitai desu.', 'Tôi cũng muốn thử làm ở nhà.', '料理', 'りょうり', 'Món ăn', '見た目', 'みため', 'Vẻ ngoài', 'おいしい', 'おいしい', 'Ngon', '家', 'いえ', 'Nhà', '作ります', 'つくります', 'Làm / nấu'),
(21, 9221, 6221, 8221, 'Du lịch', 'Hỏi thông tin điểm đến', 'N4 Bài 21 - Hỏi thông tin điểm đến', 'この町で有名な場所はどこですか。', 'このまちでゆうめいなばしょはどこですか。', 'Kono machi de yuumei na basho wa doko desu ka.', 'Địa điểm nổi tiếng ở thị trấn này là đâu?', 'バスで行けるか調べてみます。', 'バスでいけるかしらべてみます。', 'Basu de ikeru ka shirabete mimasu.', 'Tôi sẽ thử tra xem có thể đi bằng xe buýt không.', '町', 'まち', 'Thị trấn', '有名', 'ゆうめい', 'Nổi tiếng', '場所', 'ばしょ', 'Địa điểm', '調べます', 'しらべます', 'Tra cứu', 'バス', 'バス', 'Xe buýt'),
(22, 9222, 6222, 8222, 'Giáo dục', 'Luyện thi', 'N4 Bài 22 - Luyện thi', '試験まであと一週間しかありません。', 'しけんまであといっしゅうかんしかありません。', 'Shiken made ato isshuukan shika arimasen.', 'Chỉ còn một tuần nữa là đến kỳ thi.', '毎日、漢字を復習するつもりです。', 'まいにち、かんじをふくしゅうするつもりです。', 'Mainichi, kanji o fukushuu suru tsumori desu.', 'Tôi định ôn lại kanji mỗi ngày.', '試験', 'しけん', 'Kỳ thi', '一週間', 'いっしゅうかん', 'Một tuần', '漢字', 'かんじ', 'Chữ Hán', '復習', 'ふくしゅう', 'Ôn tập', 'つもり', 'つもり', 'Dự định'),
(23, 9223, 6223, 8223, 'Mua sắm', 'Hỏi khuyến mãi', 'N4 Bài 23 - Hỏi khuyến mãi', 'この商品はセールになっていますか。', 'このしょうひんはセールになっていますか。', 'Kono shouhin wa seeru ni natteimasu ka.', 'Sản phẩm này đang giảm giá phải không?', '二つ買うと、少し安くなります。', 'ふたつかうと、すこしやすくなります。', 'Futatsu kau to, sukoshi yasuku narimasu.', 'Nếu mua hai cái thì sẽ rẻ hơn một chút.', '商品', 'しょうひん', 'Sản phẩm', 'セール', 'セール', 'Giảm giá', '買います', 'かいます', 'Mua', '安い', 'やすい', 'Rẻ', '二つ', 'ふたつ', 'Hai cái'),
(24, 9224, 6224, 8224, 'Giao tiếp', 'Xin lỗi và giải thích', 'N4 Bài 24 - Xin lỗi và giải thích', '返事が遅くなって、申し訳ありません。', 'へんじがおそくなって、もうしわけありません。', 'Henji ga osoku natte, moushiwake arimasen.', 'Xin lỗi vì trả lời muộn.', '昨日は忙しくて、メールを読めませんでした。', 'きのうはいそがしくて、メールをよめませんでした。', 'Kinou wa isogashikute, meeru o yomemasen deshita.', 'Hôm qua tôi bận nên không đọc được email.', '返事', 'へんじ', 'Trả lời', '遅い', 'おそい', 'Muộn / chậm', '申し訳ありません', 'もうしわけありません', 'Thành thật xin lỗi', '忙しい', 'いそがしい', 'Bận', '読みます', 'よみます', 'Đọc'),
(25, 9225, 6225, 8225, 'Đời sống', 'Tổng ôn N4', 'N4 Bài 25 - Tổng ôn hội thoại', '日本語で自分の意見を言えるようになりました。', 'にほんごでじぶんのいけんをいえるようになりました。', 'Nihongo de jibun no iken o ieru you ni narimashita.', 'Tôi đã có thể nói ý kiến của mình bằng tiếng Nhật.', 'これからも毎日練習を続けます。', 'これからもまいにちれんしゅうをつづけます。', 'Kore kara mo mainichi renshuu o tsuzukemasu.', 'Từ giờ tôi cũng sẽ tiếp tục luyện tập mỗi ngày.', '自分', 'じぶん', 'Bản thân', '意見', 'いけん', 'Ý kiến', '言えます', 'いえます', 'Có thể nói', '練習', 'れんしゅう', 'Luyện tập', '続けます', 'つづけます', 'Tiếp tục');

INSERT INTO segment_topics (id, title, description, image_url, level)
SELECT
    segment_topic_id,
    CONCAT('N4 - ', theme_vi),
    CONCAT('Luyện shadowing N4: ', theme_vi, '.'),
    CONCAT('https://picsum.photos/seed/n4-', idx, '/900/500'),
    'N4'
FROM tmp_n4_seed;

INSERT INTO segment_topic_categories (segment_topic_id, category_id)
SELECT s.segment_topic_id, c.id
FROM tmp_n4_seed s
JOIN categories c ON c.name = s.category_name COLLATE utf8mb4_unicode_ci;

INSERT INTO lessons (id, level, chapter_name, order_index)
SELECT lesson_id, 'N4', topic_title, idx
FROM tmp_n4_seed;

INSERT INTO shadowing_topics (id, title, level, lesson_id, image_url, full_script_ja, total_duration)
SELECT
    topic_id,
    CONCAT('Shadowing ', topic_title),
    'N4',
    lesson_id,
    CONCAT('https://picsum.photos/seed/n4-topic-', idx, '/900/500'),
    CONCAT(sentence_1, sentence_2),
    12.0
FROM tmp_n4_seed;

INSERT INTO shadowing_segments
(topic_id, segment_topic_id, title, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi, image_url)
SELECT topic_id, segment_topic_id, 'Câu 1', 1, 0.0, 6.0, sentence_1, furigana_1, romaji_1, NULL, translation_1, CONCAT('https://picsum.photos/seed/n4-', idx, '-1/900/500')
FROM tmp_n4_seed;

INSERT INTO shadowing_segments
(topic_id, segment_topic_id, title, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi, image_url)
SELECT topic_id, segment_topic_id, 'Câu 2', 2, 6.0, 12.0, sentence_2, furigana_2, romaji_2, NULL, translation_2, CONCAT('https://picsum.photos/seed/n4-', idx, '-2/900/500')
FROM tmp_n4_seed;

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example)
SELECT lesson_id, topic_id, vocab_1, reading_1, meaning_1, sentence_1 FROM tmp_n4_seed;

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example)
SELECT lesson_id, topic_id, vocab_2, reading_2, meaning_2, sentence_1 FROM tmp_n4_seed;

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example)
SELECT lesson_id, topic_id, vocab_3, reading_3, meaning_3, sentence_2 FROM tmp_n4_seed;

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example)
SELECT lesson_id, topic_id, vocab_4, reading_4, meaning_4, sentence_2 FROM tmp_n4_seed;

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example)
SELECT lesson_id, topic_id, vocab_5, reading_5, meaning_5, sentence_2 FROM tmp_n4_seed;

DROP TEMPORARY TABLE IF EXISTS tmp_n4_seed;

COMMIT;

SELECT 'lessons' AS table_name, COUNT(*) AS row_count
FROM lessons
WHERE id = 6113 OR id BETWEEN 6201 AND 6225
UNION ALL
SELECT 'shadowing_topics', COUNT(*)
FROM shadowing_topics
WHERE id = 8113 OR id BETWEEN 8201 AND 8225
UNION ALL
SELECT 'segment_topics', COUNT(*)
FROM segment_topics
WHERE id = 9113 OR id BETWEEN 9201 AND 9225
UNION ALL
SELECT 'shadowing_segments', COUNT(*)
FROM shadowing_segments
WHERE topic_id = 8113 OR topic_id BETWEEN 8201 AND 8225
UNION ALL
SELECT 'vocabularies', COUNT(*)
FROM vocabularies
WHERE lesson_id = 6113 OR lesson_id BETWEEN 6201 AND 6225;

SET SQL_SAFE_UPDATES = @OLD_SQL_SAFE_UPDATES;
