-- Migration: Thêm bảng segment_topics và segment_topic_categories
-- Thêm FK segment_topic_id vào shadowing_segments
-- Chạy thủ công nếu database đã tồn tại (create_all không chạy ALTER TABLE)

-- 1. Tạo bảng segment_topics
CREATE TABLE IF NOT EXISTS segment_topics (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    image_url   TEXT
);

-- 2. Tạo bảng join segment_topic_categories
CREATE TABLE IF NOT EXISTS segment_topic_categories (
    segment_topic_id INT NOT NULL,
    category_id      INT NOT NULL,
    PRIMARY KEY (segment_topic_id, category_id),
    FOREIGN KEY (segment_topic_id) REFERENCES segment_topics(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id)      REFERENCES categories(id)      ON DELETE CASCADE
);

-- 3. Thêm cột segment_topic_id vào shadowing_segments (nếu chưa có)
ALTER TABLE shadowing_segments
    ADD COLUMN IF NOT EXISTS segment_topic_id INT NULL,
    ADD CONSTRAINT fk_segment_topic
        FOREIGN KEY (segment_topic_id) REFERENCES segment_topics(id) ON DELETE SET NULL;

-- 4. Xóa bảng join cũ giữa shadowing_segments và categories
DROP TABLE IF EXISTS segment_categories;
