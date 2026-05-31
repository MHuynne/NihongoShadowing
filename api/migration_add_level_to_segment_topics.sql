-- Migration: Thêm cột level vào bảng segment_topics
-- Chạy lệnh này trong PostgreSQL để cập nhật schema

-- 1. Tạo enum type nếu chưa có (bỏ qua lỗi nếu đã tồn tại)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'levelenum') THEN
        CREATE TYPE levelenum AS ENUM ('N5', 'N4', 'N3', 'N2', 'N1');
    END IF;
END $$;

-- 2. Thêm cột level vào bảng segment_topics
ALTER TABLE segment_topics
    ADD COLUMN IF NOT EXISTS level levelenum DEFAULT NULL;

-- 3. (Tuỳ chọn) Đặt level mặc định cho các record hiện có là N5
-- UPDATE segment_topics SET level = 'N5' WHERE level IS NULL;
