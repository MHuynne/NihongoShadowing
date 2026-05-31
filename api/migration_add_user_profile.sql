-- ============================================================
-- Migration: Tạo bảng user_profiles để lưu trữ thông tin cấp độ của user
-- Chạy lệnh: mysql -u root -p nihongo_learning < migration_add_user_profile.sql
-- ============================================================

CREATE TABLE IF NOT EXISTS user_profiles (
    user_firebase_id    VARCHAR(128) NOT NULL COMMENT 'Firebase UID',
    jlpt_level          VARCHAR(10)  NULL     COMMENT 'Cấp độ JLPT (N5, N4, N3, etc.)',
    updated_at          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (user_firebase_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
