-- 1. TẠO BẢNG (Chạy lệnh này nếu FastAPI chưa tự tạo)
CREATE TABLE IF NOT EXISTS `shadowing_topics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(255) NOT NULL,
  `level` ENUM('N5', 'N4', 'N3', 'N2', 'N1') DEFAULT NULL,
  `image_url` VARCHAR(255) DEFAULT NULL,
  `full_audio_url` VARCHAR(255) DEFAULT NULL,
  `full_script_ja` TEXT DEFAULT NULL,
  `total_duration` FLOAT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `shadowing_segments` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `topic_id` INT NOT NULL,
  `order_index` INT DEFAULT 0,
  `start_time` FLOAT DEFAULT 0.0,
  `end_time` FLOAT DEFAULT 0.0,
  `kanji_content` TEXT DEFAULT NULL,
  `furigana` TEXT DEFAULT NULL,
  `romaji` TEXT DEFAULT NULL,
  `sino_vietnamese` TEXT DEFAULT NULL,
  `translation_vi` TEXT DEFAULT NULL,
  FOREIGN KEY (`topic_id`) REFERENCES `shadowing_topics`(`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `vocabularies` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `topic_id` INT NOT NULL,
  `word` VARCHAR(255) NOT NULL,
  `reading` VARCHAR(255) DEFAULT NULL,
  `meaning` VARCHAR(255) NOT NULL,
  `example` TEXT DEFAULT NULL,
  FOREIGN KEY (`topic_id`) REFERENCES `shadowing_topics`(`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `shadowing_results` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT DEFAULT NULL,
  `topic_id` INT NOT NULL,
  `overall_score` FLOAT DEFAULT NULL,
  `detail_scores` JSON DEFAULT NULL,
  `user_audio_url` VARCHAR(255) DEFAULT NULL,
  `mode` ENUM('VISIBLE', 'BLIND') DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`topic_id`) REFERENCES `shadowing_topics`(`id`) ON DELETE CASCADE
);

-- ==================================================== --
-- 2. DỮ LIỆU MẪU (BỔ SUNG RẤT NHIỀU CHỦ ĐỀ VÀ TỪ VỰNG)
-- ==================================================== --

-- Xóa data cũ và Đặt lại ID để luôn chuẩn
DELETE FROM `vocabularies`;
DELETE FROM `shadowing_segments`;
DELETE FROM `shadowing_topics`;

ALTER TABLE `shadowing_topics` AUTO_INCREMENT = 1;
ALTER TABLE `shadowing_segments` AUTO_INCREMENT = 1;
ALTER TABLE `vocabularies` AUTO_INCREMENT = 1;

-- ==================================================== --
-- CHỦ ĐỀ 1: Phỏng vấn xin việc (N4)
-- ==================================================== --
INSERT INTO `shadowing_topics` (`id`, `title`, `level`, `total_duration`) VALUES 
(1, 'Phỏng vấn xin việc', 'N4', 30.5);

INSERT INTO `vocabularies` (`topic_id`, `word`, `reading`, `meaning`, `example`) VALUES
(1, '面接', 'めんせつ (Mensetsu)', 'Phỏng vấn', '明日、面接があります。'),
(1, '緊張', 'きんちょう (Kinchou)', 'Căng thẳng, hồi hộp', '緊張しないでください。'),
(1, '頑張る', 'がんばる (Ganbaru)', 'Cố gắng', 'はい、頑張ります。');

INSERT INTO `shadowing_segments` (`topic_id`, `order_index`, `start_time`, `end_time`, `kanji_content`, `furigana`, `romaji`, `sino_vietnamese`, `translation_vi`) VALUES
(1, 1, 0.0, 3.5, 'はじめまして、よろしくお願いします。', 'はじめまして、よろしくお願いします。', 'Hajimemashite, yoroshiku onegaishimasu.', 'Sơ kiến, dữ nguyện', 'Rất vui được gặp bạn, mong được giúp đỡ.'),
(1, 2, 4.0, 6.5, '緊張していますか？', 'きんちょうしていますか？', 'Kinchou shiteimasuka?', 'Khẩn trương', 'Bạn có đang hồi hộp không?'),
(1, 3, 7.0, 10.0, '少し緊張していますが、頑張ります。', 'すこしきんちょうしていますが、がんばります。', 'Sukoshi kinchou shiteimasuga, ganbarimasu.', 'Thiểu khẩn trương, ngoan trương', 'Tôi hơi hồi hộp một chút nhưng sẽ cố gắng.');

-- ==================================================== --
-- CHỦ ĐỀ 2: Đi siêu thị (N5)
-- ==================================================== --
INSERT INTO `shadowing_topics` (`id`, `title`, `level`, `total_duration`) VALUES 
(2, 'Mua sắm ở siêu thị', 'N5', 20.0);

INSERT INTO `vocabularies` (`topic_id`, `word`, `reading`, `meaning`, `example`) VALUES
(2, 'スーパー', 'すーぱー (Su-pa-)', 'Siêu thị', 'スーパーで買い物をします。'),
(2, '卵', 'たまご (Tamago)', 'Trứng', '卵を3つ買いました。'),
(2, '探す', 'さがす (Sagasu)', 'Tìm kiếm', '本を探しています。');

INSERT INTO `shadowing_segments` (`topic_id`, `order_index`, `start_time`, `end_time`, `kanji_content`, `furigana`, `romaji`, `sino_vietnamese`, `translation_vi`) VALUES
(2, 1, 0.0, 3.0, 'すみません、卵はどこですか？', 'すみません、たまごはどこですか？', 'Sumimasen, tamago wa doko desuka?', 'Noãn', 'Xin lỗi, trứng ở đâu vậy ạ?'),
(2, 2, 3.5, 5.0, 'あちらです。', 'あちらです。', 'Achira desu.', '', 'Ở đằng kia ạ.'),
(2, 3, 5.5, 7.0, 'ありがとうございます。', 'ありがとうございます。', 'Arigatou gozaimasu.', '', 'Cảm ơn bạn nhé.');

-- ==================================================== --
-- CHỦ ĐỀ 3: Khám bệnh (N4)
-- ==================================================== --
INSERT INTO `shadowing_topics` (`id`, `title`, `level`, `total_duration`) VALUES 
(3, 'Cuộc hẹn với Bác sĩ', 'N4', 45.0);

INSERT INTO `vocabularies` (`topic_id`, `word`, `reading`, `meaning`, `example`) VALUES
(3, '病院', 'びょういん (Byouin)', 'Bệnh viện', '明日、病院へ行きます。'),
(3, '風邪', 'かぜ (Kaze)', 'Cảm cúm', '風邪を引きました。'),
(3, '薬', 'くすり (Kusuri)', 'Thuốc', '薬を飲んでください。');

INSERT INTO `shadowing_segments` (`topic_id`, `order_index`, `start_time`, `end_time`, `kanji_content`, `furigana`, `romaji`, `sino_vietnamese`, `translation_vi`) VALUES
(3, 1, 0.0, 3.0, 'どうしましたか？', 'どうしましたか？', 'Doushimashitaka?', '', 'Bạn bị sao thế?'),
(3, 2, 3.5, 6.5, '昨日から熱があります。', 'きのうからねつがあります。', 'Kinou kara netsu ga arimasu.', 'Tạc nhật, nhiệt', 'Tôi bị sốt từ hôm qua.'),
(3, 3, 7.0, 11.0, '風邪ですね。薬を出します。', 'かぜですね。くすりをだします。', 'Kaze desune. Kusuri o dashimasu.', 'Phong tà, dược', 'Anh/chị bị cảm rồi. Tôi sẽ kê đơn thuốc nhé.');

-- ==================================================== --
-- CHỦ ĐỀ 4: Công việc (N3)
-- ==================================================== --
INSERT INTO `shadowing_topics` (`id`, `title`, `level`, `total_duration`) VALUES 
(4, 'Thuyết trình dự án', 'N3', 60.0);

INSERT INTO `vocabularies` (`topic_id`, `word`, `reading`, `meaning`, `example`) VALUES
(4, '企画', 'きかく (Kikaku)', 'Kế hoạch, Dự án', '新しい企画を考えます。'),
(4, '提案', 'ていあん (Teian)', 'Đề xuất', '社長に提案しました。'),
(4, '成功', 'せいこう (Seikou)', 'Thành công', 'プロジェクトが成功した。');

INSERT INTO `shadowing_segments` (`topic_id`, `order_index`, `start_time`, `end_time`, `kanji_content`, `furigana`, `romaji`, `sino_vietnamese`, `translation_vi`) VALUES
(4, 1, 0.0, 4.0, '新しい企画を提案します。', 'あたらしいきかくをていあんします。', 'Atarashii kikaku o teian shimasu.', 'Tân, xí hoạ, đề án', 'Tôi xin trình bày đề xuất cho dự án mới.'),
(4, 2, 4.5, 8.0, 'それは素晴らしいアイデアですね。', 'それはすばらしいアイデアですね。', 'Sore wa subarashii aidea desune.', 'Tố tình', 'Đó quả là một ý tưởng rất tuyệt vời đấy.'),
(4, 3, 8.5, 12.0, '成功に向けて頑張りましょう。', 'せいこうにむけてがんばりましょう。', 'Seikou ni mukete ganbarimashou.', 'Thành công, ngoan trương', 'Chúng ta cùng nỗ lực để hướng tới thành công nào!');
