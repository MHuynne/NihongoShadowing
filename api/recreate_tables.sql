-- ============================================================================
-- SQL SCRIPT: Khởi tạo lại toàn bộ bảng trong dự án nihongo_learning
-- Cách chạy: mysql -u root -p nihongo_learning < recreate_tables.sql
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- 1. XÓA BẢNG CŨ (NẾU TỒN TẠI) Theo thứ tự để tránh xung đột khóa ngoại
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS `segment_topic_categories`;
DROP TABLE IF EXISTS `shadowing_segments`;
DROP TABLE IF EXISTS `shadowing_results`;
DROP TABLE IF EXISTS `vocabularies`;
DROP TABLE IF EXISTS `user_progress`;
DROP TABLE IF EXISTS `roleplay_message`;
DROP TABLE IF EXISTS `roleplay_session`;
DROP TABLE IF EXISTS `roleplay_scenario`;
DROP TABLE IF EXISTS `shadowing_topics`;
DROP TABLE IF EXISTS `lessons`;
DROP TABLE IF EXISTS `segment_topics`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `user_profiles`;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------------------------------------------------------
-- 2. TẠO CÁC BẢNG ĐỘC LẬP / BẢNG CHA trước
-- ----------------------------------------------------------------------------

-- Bảng categories
CREATE TABLE `categories` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_categories_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng lessons
CREATE TABLE `lessons` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `level` ENUM('N5', 'N4', 'N3', 'N2', 'N1') DEFAULT NULL,
    `chapter_name` VARCHAR(255) DEFAULT NULL,
    `order_index` INT DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_lessons_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng segment_topics
CREATE TABLE `segment_topics` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `image_url` TEXT DEFAULT NULL,
    `level` ENUM('N5', 'N4', 'N3', 'N2', 'N1') DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_segment_topics_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng user_profiles
CREATE TABLE `user_profiles` (
    `user_firebase_id` VARCHAR(128) NOT NULL,
    `jlpt_level` VARCHAR(10) DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_firebase_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng roleplay_scenario
CREATE TABLE `roleplay_scenario` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `icon_url` VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 3. TẠO CÁC BẢNG PHỤ THUỘC (BẢNG CON)
-- ----------------------------------------------------------------------------

-- Bảng shadowing_topics
CREATE TABLE `shadowing_topics` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(255) NOT NULL,
    `level` ENUM('N5', 'N4', 'N3', 'N2', 'N1') DEFAULT NULL,
    `lesson_id` INT DEFAULT NULL,
    `image_url` VARCHAR(255) DEFAULT NULL,
    `full_audio_url` VARCHAR(255) DEFAULT NULL,
    `full_script_ja` TEXT DEFAULT NULL,
    `total_duration` FLOAT DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_shadowing_topics_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `lessons` (`id`) ON DELETE SET NULL,
    INDEX `idx_shadowing_topics_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng segment_topic_categories
CREATE TABLE `segment_topic_categories` (
    `segment_topic_id` INT NOT NULL,
    `category_id` INT NOT NULL,
    PRIMARY KEY (`segment_topic_id`, `category_id`),
    CONSTRAINT `fk_stc_segment_topic` FOREIGN KEY (`segment_topic_id`) REFERENCES `segment_topics` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_stc_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng shadowing_segments
CREATE TABLE `shadowing_segments` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `topic_id` INT DEFAULT NULL,
    `segment_topic_id` INT DEFAULT NULL,
    `title` VARCHAR(255) DEFAULT NULL,
    `order_index` INT DEFAULT NULL,
    `start_time` FLOAT DEFAULT NULL,
    `end_time` FLOAT DEFAULT NULL,
    `kanji_content` TEXT DEFAULT NULL,
    `furigana` TEXT DEFAULT NULL,
    `romaji` TEXT DEFAULT NULL,
    `sino_vietnamese` TEXT DEFAULT NULL,
    `translation_vi` TEXT DEFAULT NULL,
    `image_url` TEXT DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_shadowing_segments_topic` FOREIGN KEY (`topic_id`) REFERENCES `shadowing_topics` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_shadowing_segments_st` FOREIGN KEY (`segment_topic_id`) REFERENCES `segment_topics` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng shadowing_results
CREATE TABLE `shadowing_results` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `user_id` INT DEFAULT NULL,
    `topic_id` INT NOT NULL,
    `overall_score` FLOAT DEFAULT NULL,
    `detail_scores` JSON DEFAULT NULL,
    `user_audio_url` VARCHAR(255) DEFAULT NULL,
    `mode` ENUM('VISIBLE', 'BLIND') DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_shadowing_results_topic` FOREIGN KEY (`topic_id`) REFERENCES `shadowing_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng vocabularies
CREATE TABLE `vocabularies` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `lesson_id` INT DEFAULT NULL,
    `topic_id` INT DEFAULT NULL,
    `word` VARCHAR(255) NOT NULL,
    `reading` VARCHAR(255) DEFAULT NULL,
    `meaning` VARCHAR(255) NOT NULL,
    `example` TEXT DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_vocabularies_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `lessons` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vocabularies_topic` FOREIGN KEY (`topic_id`) REFERENCES `shadowing_topics` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng user_progress
CREATE TABLE `user_progress` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `user_firebase_id` VARCHAR(128) NOT NULL,
    `lesson_id` INT NOT NULL,
    `flashcard_done` BOOLEAN NOT NULL DEFAULT FALSE,
    `test_score` FLOAT DEFAULT NULL,
    `test_passed` BOOLEAN NOT NULL DEFAULT FALSE,
    `shadowing_score` FLOAT DEFAULT NULL,
    `shadowing_passed` BOOLEAN NOT NULL DEFAULT FALSE,
    `lesson_completed` BOOLEAN NOT NULL DEFAULT FALSE,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_user_lesson` (`user_firebase_id`, `lesson_id`),
    INDEX `idx_up_user_firebase` (`user_firebase_id`),
    CONSTRAINT `fk_user_progress_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `lessons` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng roleplay_session
CREATE TABLE `roleplay_session` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `scenario_id` INT DEFAULT NULL,
    `user_id` INT DEFAULT NULL,
    `mode` ENUM('keigo', 'plain') DEFAULT 'keigo',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_roleplay_session_scenario` FOREIGN KEY (`scenario_id`) REFERENCES `roleplay_scenario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng roleplay_message
CREATE TABLE `roleplay_message` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `session_id` INT DEFAULT NULL,
    `role` VARCHAR(50) DEFAULT NULL,
    `content` TEXT DEFAULT NULL,
    `grammar_correction` JSON DEFAULT NULL,
    `suggestions` JSON DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_roleplay_message_session` FOREIGN KEY (`session_id`) REFERENCES `roleplay_session` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 4. SEED DỮ LIỆU BAN ĐẦU CHO CATEGORIES
-- ----------------------------------------------------------------------------
INSERT IGNORE INTO `categories` (`name`, `description`) VALUES
    ('Giao tiếp',   'Các câu hội thoại thông dụng trong giao tiếp hàng ngày'),
    ('Du lịch',     'Ngôn ngữ dùng khi đi du lịch, di chuyển, đặt phòng'),
    ('Công việc',   'Giao tiếp chuyên nghiệp trong môi trường làm việc'),
    ('Mua sắm',     'Hội thoại tại cửa hàng, siêu thị, chợ'),
    ('Nhà hàng',    'Gọi món, thanh toán, phục vụ tại nhà hàng'),
    ('Khẩn cấp',    'Tình huống cần giúp đỡ, bệnh viện, cảnh sát'),
    ('Giáo dục',    'Học tập, trường lớp, hỏi thăm bài học');
