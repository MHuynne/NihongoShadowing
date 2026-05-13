-- ============================================================
-- Migration: Tạo bảng categories và segment_categories
-- Chạy file này trong Laragon / MySQL Workbench
-- ============================================================

-- 1. Bảng categories (Giao tiếp, Du lịch, Công việc, ...)
CREATE TABLE IF NOT EXISTS categories (
    id          INT          NOT NULL AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Bảng join nhiều-nhiều giữa shadowing_segments và categories
CREATE TABLE IF NOT EXISTS segment_categories (
    segment_id  INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (segment_id, category_id),
    CONSTRAINT fk_segcat_segment
        FOREIGN KEY (segment_id)  REFERENCES shadowing_segments (id) ON DELETE CASCADE,
    CONSTRAINT fk_segcat_category
        FOREIGN KEY (category_id) REFERENCES categories           (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Seed dữ liệu mẫu cho categories
INSERT IGNORE INTO categories (name, description) VALUES
    ('Giao tiếp',   'Các câu hội thoại thông dụng trong giao tiếp hàng ngày'),
    ('Du lịch',     'Ngôn ngữ dùng khi đi du lịch, di chuyển, đặt phòng'),
    ('Công việc',   'Giao tiếp chuyên nghiệp trong môi trường làm việc'),
    ('Mua sắm',     'Hội thoại tại cửa hàng, siêu thị, chợ'),
    ('Nhà hàng',    'Gọi món, thanh toán, phục vụ tại nhà hàng'),
    ('Khẩn cấp',    'Tình huống cần giúp đỡ, bệnh viện, cảnh sát'),
    ('Giáo dục',    'Học tập, trường lớp, hỏi thăm bài học');

-- 4. Thêm cột title vào shadowing_segments (nếu chưa có)
ALTER TABLE shadowing_segments
    ADD COLUMN IF NOT EXISTS title VARCHAR(255) NULL
        COMMENT 'Tiêu đề hiển thị của segment'
        AFTER topic_id;


