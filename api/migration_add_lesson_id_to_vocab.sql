-- =========================================================
-- MIGRATION: Thêm lesson_id vào bảng vocabularies
-- Chạy file này trên database nihongo_learning
-- =========================================================

-- Bước 1: Thêm cột lesson_id (nullable) vào vocabularies
ALTER TABLE `vocabularies`
    ADD COLUMN `lesson_id` INT DEFAULT NULL AFTER `id`,
    ADD CONSTRAINT `fk_vocab_lesson`
        FOREIGN KEY (`lesson_id`) REFERENCES `lessons`(`id`) ON DELETE CASCADE;

-- Bước 2: Cho phép topic_id là NULL (trước đây NOT NULL ngầm định)
ALTER TABLE `vocabularies`
    MODIFY COLUMN `topic_id` INT DEFAULT NULL;

-- =========================================================
-- CẬP NHẬT seed data: gán lesson_id cho vocabularies
-- (Tạm thời cả 4 topic chưa có lesson → giữ nguyên topic_id)
-- Khi có lesson thật, chạy lệnh UPDATE bên dưới:
-- =========================================================

-- Ví dụ: Nếu lesson id=1 là "Chương N5 - Giao tiếp cơ bản"
-- và muốn gắn thêm từ vựng chung cho cả chương:
--
-- INSERT INTO `vocabularies` (lesson_id, topic_id, word, reading, meaning, example) VALUES
-- (1, NULL, 'こんにちは', 'こんにちは (Konnichiwa)', 'Xin chào', 'こんにちは、田中さん。');
--
-- Để chuyển từ topic-level sang lesson-level (gắn thêm lesson_id):
-- UPDATE `vocabularies` SET lesson_id = 1 WHERE topic_id = 2;  -- topic "Siêu thị" thuộc lesson 1

-- =========================================================
-- Kiểm tra kết quả
-- =========================================================
-- SELECT v.id, v.lesson_id, v.topic_id, v.word, v.meaning
-- FROM vocabularies v
-- ORDER BY v.lesson_id, v.topic_id, v.id;
