-- ============================================================
-- Migration: Tạo bảng user_progress
-- Chạy lệnh: mysql -u root -p japanese_learning_db < migration_add_user_progress.sql
-- ============================================================

CREATE TABLE IF NOT EXISTS user_progress (
    id                  INT          NOT NULL AUTO_INCREMENT,
    user_firebase_id    VARCHAR(128) NOT NULL COMMENT 'Firebase UID',
    lesson_id           INT          NOT NULL,

    -- Bước 1: Flashcard
    flashcard_done      BOOLEAN      NOT NULL DEFAULT FALSE,

    -- Bước 2: Vocabulary Test
    test_score          FLOAT        NULL     COMMENT 'Điểm 0-100, NULL = chưa làm',
    test_passed         BOOLEAN      NOT NULL DEFAULT FALSE COMMENT '>= 70 điểm',

    -- Bước 3: Shadowing
    shadowing_score     FLOAT        NULL     COMMENT 'Điểm 0-100, NULL = chưa làm',
    shadowing_passed    BOOLEAN      NOT NULL DEFAULT FALSE COMMENT '>= 80 điểm',

    -- Tổng hợp
    lesson_completed    BOOLEAN      NOT NULL DEFAULT FALSE,

    updated_at          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_user_lesson (user_firebase_id, lesson_id),
    INDEX idx_user_firebase_id (user_firebase_id),
    CONSTRAINT fk_up_lesson FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
