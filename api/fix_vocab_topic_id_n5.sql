-- =============================================================
-- FIX: Gán topic_id cho vocabularies N5 bài 1-15
-- Chạy file này sau khi đã chạy 3 file seed chính
-- =============================================================
SET NAMES utf8mb4;

-- Bài 1 (lesson 6001) → topic 7001 (4 từ đầu), 7002 (4 từ sau)
UPDATE vocabularies SET topic_id=7001 WHERE lesson_id=6001 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7002 WHERE lesson_id=6001 AND topic_id IS NULL LIMIT 4;
-- Bài 2 (lesson 6002) → topic 7003, 7004
UPDATE vocabularies SET topic_id=7003 WHERE lesson_id=6002 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7004 WHERE lesson_id=6002 AND topic_id IS NULL LIMIT 4;
-- Bài 3 (lesson 6003) → topic 7005, 7006
UPDATE vocabularies SET topic_id=7005 WHERE lesson_id=6003 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7006 WHERE lesson_id=6003 AND topic_id IS NULL LIMIT 4;
-- Bài 4 (lesson 6004) → topic 7007, 7008
UPDATE vocabularies SET topic_id=7007 WHERE lesson_id=6004 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7008 WHERE lesson_id=6004 AND topic_id IS NULL LIMIT 4;
-- Bài 5 (lesson 6005) → topic 7009, 7010
UPDATE vocabularies SET topic_id=7009 WHERE lesson_id=6005 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7010 WHERE lesson_id=6005 AND topic_id IS NULL LIMIT 4;
-- Bài 6 → topic 7011, 7012
UPDATE vocabularies SET topic_id=7011 WHERE lesson_id=6006 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7012 WHERE lesson_id=6006 AND topic_id IS NULL LIMIT 4;
-- Bài 7 → topic 7013, 7014
UPDATE vocabularies SET topic_id=7013 WHERE lesson_id=6007 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7014 WHERE lesson_id=6007 AND topic_id IS NULL LIMIT 4;
-- Bài 8 → topic 7015, 7016
UPDATE vocabularies SET topic_id=7015 WHERE lesson_id=6008 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7016 WHERE lesson_id=6008 AND topic_id IS NULL LIMIT 4;
-- Bài 9 → topic 7017, 7018
UPDATE vocabularies SET topic_id=7017 WHERE lesson_id=6009 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7018 WHERE lesson_id=6009 AND topic_id IS NULL LIMIT 4;
-- Bài 10 → topic 7019, 7020
UPDATE vocabularies SET topic_id=7019 WHERE lesson_id=6010 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7020 WHERE lesson_id=6010 AND topic_id IS NULL LIMIT 4;
-- Bài 11 → topic 7021, 7022
UPDATE vocabularies SET topic_id=7021 WHERE lesson_id=6011 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7022 WHERE lesson_id=6011 AND topic_id IS NULL LIMIT 4;
-- Bài 12 → topic 7023, 7024
UPDATE vocabularies SET topic_id=7023 WHERE lesson_id=6012 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7024 WHERE lesson_id=6012 AND topic_id IS NULL LIMIT 4;
-- Bài 13 → topic 7025, 7026
UPDATE vocabularies SET topic_id=7025 WHERE lesson_id=6013 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7026 WHERE lesson_id=6013 AND topic_id IS NULL LIMIT 4;
-- Bài 14 → topic 7027, 7028
UPDATE vocabularies SET topic_id=7027 WHERE lesson_id=6014 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7028 WHERE lesson_id=6014 AND topic_id IS NULL LIMIT 4;
-- Bài 15 → topic 7029, 7030
UPDATE vocabularies SET topic_id=7029 WHERE lesson_id=6015 AND topic_id IS NULL LIMIT 4;
UPDATE vocabularies SET topic_id=7030 WHERE lesson_id=6015 AND topic_id IS NULL LIMIT 4;

-- Kiểm tra
SELECT t.id as topic_id, COUNT(v.id) as vocab_count
FROM shadowing_topics t
LEFT JOIN vocabularies v ON v.topic_id = t.id
WHERE t.id BETWEEN 7001 AND 7030
GROUP BY t.id ORDER BY t.id;
