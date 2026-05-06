-- =========================================================
-- SEED LEARNING PATH DATA: N5 -> N1
-- =========================================================
-- Purpose:
--   Add learning-path data using existing tables only:
--   lessons, vocabularies, shadowing_topics, shadowing_segments.
--
-- Notes:
--   - This does not change schema.
--   - N5/N4 lessons are named in Minna no Nihongo style.
--   - Vocabulary and shadowing content below is original demo content,
--     not copied from the textbook.
--   - IDs use fixed ranges to make mapping predictable:
--       N5 lessons: 5101-5125
--       N4 lessons: 4201-4225
--       N3 lessons: 3301-3320
--       N2 lessons: 2201-2220
--       N1 lessons: 1101-1120
--       shadowing_topics: lesson_id + 10000
--
-- Run on database: nihongo_learning
-- =========================================================

DROP PROCEDURE IF EXISTS seed_learning_path_n5_to_n1;

DELIMITER $$

CREATE PROCEDURE seed_learning_path_n5_to_n1()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE lessonId INT;
    DECLARE topicId INT;
    DECLARE levelName VARCHAR(2);
    DECLARE lessonTitle VARCHAR(255);

    -- Avoid duplicate key errors when re-running this seed.
    DELETE FROM shadowing_segments
    WHERE topic_id BETWEEN 11101 AND 11120
       OR topic_id BETWEEN 12201 AND 12220
       OR topic_id BETWEEN 13301 AND 13320
       OR topic_id BETWEEN 14201 AND 14225
       OR topic_id BETWEEN 15101 AND 15125;

    DELETE FROM shadowing_topics
    WHERE id BETWEEN 11101 AND 11120
       OR id BETWEEN 12201 AND 12220
       OR id BETWEEN 13301 AND 13320
       OR id BETWEEN 14201 AND 14225
       OR id BETWEEN 15101 AND 15125;

    DELETE FROM vocabularies
    WHERE lesson_id BETWEEN 1101 AND 1120
       OR lesson_id BETWEEN 2201 AND 2220
       OR lesson_id BETWEEN 3301 AND 3320
       OR lesson_id BETWEEN 4201 AND 4225
       OR lesson_id BETWEEN 5101 AND 5125;

    DELETE FROM lessons
    WHERE id BETWEEN 1101 AND 1120
       OR id BETWEEN 2201 AND 2220
       OR id BETWEEN 3301 AND 3320
       OR id BETWEEN 4201 AND 4225
       OR id BETWEEN 5101 AND 5125;

    -- N5: Minna no Nihongo style, lessons 1-25.
    SET i = 1;
    WHILE i <= 25 DO
        SET lessonId = 5100 + i;
        SET topicId = 10000 + lessonId;
        SET levelName = 'N5';
        SET lessonTitle = CONCAT('Minna no Nihongo - N5 Bài ', i);

        INSERT INTO lessons (id, level, chapter_name, order_index)
        VALUES (lessonId, levelName, lessonTitle, i);

        INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
        (lessonId, NULL, CONCAT('N5語彙', i, '-1'), CONCAT('n5ごい', i, '-1'), CONCAT('Từ vựng N5 bài ', i, ' số 1'), CONCAT('これはN5 bài ', i, ' の例文です。')),
        (lessonId, NULL, CONCAT('N5語彙', i, '-2'), CONCAT('n5ごい', i, '-2'), CONCAT('Từ vựng N5 bài ', i, ' số 2'), CONCAT('毎日N5 bài ', i, ' を練習します。')),
        (lessonId, NULL, CONCAT('N5語彙', i, '-3'), CONCAT('n5ごい', i, '-3'), CONCAT('Từ vựng N5 bài ', i, ' số 3'), CONCAT('友だちとN5 bài ', i, ' を勉強します。')),
        (lessonId, NULL, CONCAT('N5語彙', i, '-4'), CONCAT('n5ごい', i, '-4'), CONCAT('Từ vựng N5 bài ', i, ' số 4'), CONCAT('先生にN5 bài ', i, ' を聞きます。')),
        (lessonId, NULL, CONCAT('N5語彙', i, '-5'), CONCAT('n5ごい', i, '-5'), CONCAT('Từ vựng N5 bài ', i, ' số 5'), CONCAT('家でN5 bài ', i, ' を復習します。'));

        INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration)
        VALUES (
            topicId,
            CONCAT('Shadowing N5 Bài ', i, ' - Hội thoại luyện nói'),
            levelName,
            lessonId,
            CONCAT('こんにちは。これはN5 bài ', i, ' の練習です。ゆっくり聞いて、声に出して言いましょう。'),
            24.0
        );

        INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, translation_vi) VALUES
        (topicId, 1, 0.0, 4.0, CONCAT('こんにちは。これはN5 bài ', i, ' の練習です。'), CONCAT('こんにちは。これはN5 bài ', i, ' のれんしゅうです。'), CONCAT('Konnichiwa. Kore wa N5 bai ', i, ' no renshuu desu.'), CONCAT('Xin chào. Đây là bài luyện N5 bài ', i, '.')),
        (topicId, 2, 4.1, 8.0, 'ゆっくり聞いてください。', 'ゆっくりきいてください。', 'Yukkuri kiite kudasai.', 'Hãy nghe chậm rãi.'),
        (topicId, 3, 8.1, 12.0, '声に出して言いましょう。', 'こえにだしていいましょう。', 'Koe ni dashite iimashou.', 'Hãy nói thành tiếng.');

        SET i = i + 1;
    END WHILE;

    -- N4: Minna no Nihongo style, lessons 26-50.
    SET i = 1;
    WHILE i <= 25 DO
        SET lessonId = 4200 + i;
        SET topicId = 10000 + lessonId;
        SET levelName = 'N4';
        SET lessonTitle = CONCAT('Minna no Nihongo - N4 Bài ', i + 25);

        INSERT INTO lessons (id, level, chapter_name, order_index)
        VALUES (lessonId, levelName, lessonTitle, i);

        INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
        (lessonId, NULL, CONCAT('N4語彙', i, '-1'), CONCAT('n4ごい', i, '-1'), CONCAT('Từ vựng N4 bài ', i + 25, ' số 1'), CONCAT('これはN4 bài ', i + 25, ' の例文です。')),
        (lessonId, NULL, CONCAT('N4語彙', i, '-2'), CONCAT('n4ごい', i, '-2'), CONCAT('Từ vựng N4 bài ', i + 25, ' số 2'), CONCAT('毎日N4 bài ', i + 25, ' を練習します。')),
        (lessonId, NULL, CONCAT('N4語彙', i, '-3'), CONCAT('n4ごい', i, '-3'), CONCAT('Từ vựng N4 bài ', i + 25, ' số 3'), CONCAT('友だちとN4 bài ', i + 25, ' を勉強します。')),
        (lessonId, NULL, CONCAT('N4語彙', i, '-4'), CONCAT('n4ごい', i, '-4'), CONCAT('Từ vựng N4 bài ', i + 25, ' số 4'), CONCAT('先生にN4 bài ', i + 25, ' を聞きます。')),
        (lessonId, NULL, CONCAT('N4語彙', i, '-5'), CONCAT('n4ごい', i, '-5'), CONCAT('Từ vựng N4 bài ', i + 25, ' số 5'), CONCAT('家でN4 bài ', i + 25, ' を復習します。'));

        INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration)
        VALUES (
            topicId,
            CONCAT('Shadowing N4 Bài ', i + 25, ' - Hội thoại luyện nói'),
            levelName,
            lessonId,
            CONCAT('すみません。これはN4 bài ', i + 25, ' の練習です。意味を考えながら話しましょう。'),
            28.0
        );

        INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, translation_vi) VALUES
        (topicId, 1, 0.0, 4.0, CONCAT('すみません。これはN4 bài ', i + 25, ' の練習です。'), CONCAT('すみません。これはN4 bài ', i + 25, ' のれんしゅうです。'), CONCAT('Sumimasen. Kore wa N4 bai ', i + 25, ' no renshuu desu.'), CONCAT('Xin lỗi. Đây là bài luyện N4 bài ', i + 25, '.')),
        (topicId, 2, 4.1, 8.0, '意味を考えながら聞いてください。', 'いみをかんがえながらきいてください。', 'Imi o kangaenagara kiite kudasai.', 'Hãy vừa nghe vừa nghĩ về ý nghĩa.'),
        (topicId, 3, 8.1, 12.0, '自然なスピードで言ってみましょう。', 'しぜんなスピードでいってみましょう。', 'Shizen na supiido de itte mimashou.', 'Hãy thử nói với tốc độ tự nhiên.');

        SET i = i + 1;
    END WHILE;

    -- N3/N2/N1: original JLPT-style learning path data.
    SET i = 1;
    WHILE i <= 20 DO
        -- N3
        SET lessonId = 3300 + i;
        SET topicId = 10000 + lessonId;
        SET levelName = 'N3';
        INSERT INTO lessons (id, level, chapter_name, order_index)
        VALUES (lessonId, levelName, CONCAT('JLPT N3 Bài ', i, ' - Giao tiếp và đọc hiểu'), i);
        INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
        (lessonId, NULL, CONCAT('N3語彙', i, '-1'), CONCAT('n3ごい', i, '-1'), CONCAT('Từ vựng N3 bài ', i, ' số 1'), CONCAT('N3 bài ', i, ' の文を読みます。')),
        (lessonId, NULL, CONCAT('N3語彙', i, '-2'), CONCAT('n3ごい', i, '-2'), CONCAT('Từ vựng N3 bài ', i, ' số 2'), CONCAT('理由を説明します。')),
        (lessonId, NULL, CONCAT('N3語彙', i, '-3'), CONCAT('n3ごい', i, '-3'), CONCAT('Từ vựng N3 bài ', i, ' số 3'), CONCAT('意見をまとめます。')),
        (lessonId, NULL, CONCAT('N3語彙', i, '-4'), CONCAT('n3ごい', i, '-4'), CONCAT('Từ vựng N3 bài ', i, ' số 4'), CONCAT('会話を練習します。')),
        (lessonId, NULL, CONCAT('N3語彙', i, '-5'), CONCAT('n3ごい', i, '-5'), CONCAT('Từ vựng N3 bài ', i, ' số 5'), CONCAT('内容を確認します。'));
        INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration)
        VALUES (topicId, CONCAT('Shadowing N3 Bài ', i, ' - Hội thoại ứng dụng'), levelName, lessonId, CONCAT('今日はN3 bài ', i, ' の会話を練習します。理由を説明して、意見を言いましょう。'), 32.0);
        INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, translation_vi) VALUES
        (topicId, 1, 0.0, 4.0, CONCAT('今日はN3 bài ', i, ' の会話を練習します。'), CONCAT('きょうはN3 bài ', i, ' のかいわをれんしゅうします。'), CONCAT('Kyou wa N3 bai ', i, ' no kaiwa o renshuu shimasu.'), CONCAT('Hôm nay luyện hội thoại N3 bài ', i, '.')),
        (topicId, 2, 4.1, 8.0, '理由を説明してください。', 'りゆうをせつめいしてください。', 'Riyuu o setsumei shite kudasai.', 'Hãy giải thích lý do.'),
        (topicId, 3, 8.1, 12.0, '自分の意見を言いましょう。', 'じぶんのいけんをいいましょう。', 'Jibun no iken o iimashou.', 'Hãy nói ý kiến của mình.');

        -- N2
        SET lessonId = 2200 + i;
        SET topicId = 10000 + lessonId;
        SET levelName = 'N2';
        INSERT INTO lessons (id, level, chapter_name, order_index)
        VALUES (lessonId, levelName, CONCAT('JLPT N2 Bài ', i, ' - Xã hội và công việc'), i);
        INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
        (lessonId, NULL, CONCAT('N2語彙', i, '-1'), CONCAT('n2ごい', i, '-1'), CONCAT('Từ vựng N2 bài ', i, ' số 1'), CONCAT('社会の問題について話します。')),
        (lessonId, NULL, CONCAT('N2語彙', i, '-2'), CONCAT('n2ごい', i, '-2'), CONCAT('Từ vựng N2 bài ', i, ' số 2'), CONCAT('仕事の効率を考えます。')),
        (lessonId, NULL, CONCAT('N2語彙', i, '-3'), CONCAT('n2ごい', i, '-3'), CONCAT('Từ vựng N2 bài ', i, ' số 3'), CONCAT('提案を比較します。')),
        (lessonId, NULL, CONCAT('N2語彙', i, '-4'), CONCAT('n2ごい', i, '-4'), CONCAT('Từ vựng N2 bài ', i, ' số 4'), CONCAT('結果を判断します。')),
        (lessonId, NULL, CONCAT('N2語彙', i, '-5'), CONCAT('n2ごい', i, '-5'), CONCAT('Từ vựng N2 bài ', i, ' số 5'), CONCAT('根拠を示します。'));
        INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration)
        VALUES (topicId, CONCAT('Shadowing N2 Bài ', i, ' - Thảo luận chủ đề'), levelName, lessonId, CONCAT('N2 bài ', i, ' では、社会や仕事のテーマについて意見を述べます。'), 36.0);
        INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, translation_vi) VALUES
        (topicId, 1, 0.0, 4.0, CONCAT('N2 bài ', i, ' では、社会のテーマについて話します。'), CONCAT('N2 bài ', i, ' では、しゃかいのテーマについてはなします。'), CONCAT('N2 bai ', i, ' de wa, shakai no teema ni tsuite hanashimasu.'), CONCAT('Ở N2 bài ', i, ', chúng ta nói về chủ đề xã hội.')),
        (topicId, 2, 4.1, 8.0, '根拠を示して意見を述べます。', 'こんきょをしめしていけんをのべます。', 'Konkyo o shimeshite iken o nobemasu.', 'Trình bày ý kiến kèm căn cứ.'),
        (topicId, 3, 8.1, 12.0, '最後に結論をまとめます。', 'さいごにけつろんをまとめます。', 'Saigo ni ketsuron o matomemasu.', 'Cuối cùng tổng kết kết luận.');

        -- N1
        SET lessonId = 1100 + i;
        SET topicId = 10000 + lessonId;
        SET levelName = 'N1';
        INSERT INTO lessons (id, level, chapter_name, order_index)
        VALUES (lessonId, levelName, CONCAT('JLPT N1 Bài ', i, ' - Phân tích và lập luận nâng cao'), i);
        INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
        (lessonId, NULL, CONCAT('N1語彙', i, '-1'), CONCAT('n1ごい', i, '-1'), CONCAT('Từ vựng N1 bài ', i, ' số 1'), CONCAT('論点を整理します。')),
        (lessonId, NULL, CONCAT('N1語彙', i, '-2'), CONCAT('n1ごい', i, '-2'), CONCAT('Từ vựng N1 bài ', i, ' số 2'), CONCAT('仮説を検証します。')),
        (lessonId, NULL, CONCAT('N1語彙', i, '-3'), CONCAT('n1ごい', i, '-3'), CONCAT('Từ vựng N1 bài ', i, ' số 3'), CONCAT('本質を見極めます。')),
        (lessonId, NULL, CONCAT('N1語彙', i, '-4'), CONCAT('n1ごい', i, '-4'), CONCAT('Từ vựng N1 bài ', i, ' số 4'), CONCAT('抽象的な表現を理解します。')),
        (lessonId, NULL, CONCAT('N1語彙', i, '-5'), CONCAT('n1ごい', i, '-5'), CONCAT('Từ vựng N1 bài ', i, ' số 5'), CONCAT('論理的に説明します。'));
        INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration)
        VALUES (topicId, CONCAT('Shadowing N1 Bài ', i, ' - Lập luận nâng cao'), levelName, lessonId, CONCAT('N1 bài ', i, ' では、抽象的な内容を理解し、論理的に説明します。'), 40.0);
        INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, translation_vi) VALUES
        (topicId, 1, 0.0, 4.0, CONCAT('N1 bài ', i, ' では、抽象的な内容を理解します。'), CONCAT('N1 bài ', i, ' では、ちゅうしょうてきなないようをりかいします。'), CONCAT('N1 bai ', i, ' de wa, chuushouteki na naiyou o rikai shimasu.'), CONCAT('Ở N1 bài ', i, ', học cách hiểu nội dung trừu tượng.')),
        (topicId, 2, 4.1, 8.0, '論点を整理して説明します。', 'ろんてんをせいりしてせつめいします。', 'Ronten o seiri shite setsumei shimasu.', 'Sắp xếp luận điểm rồi giải thích.'),
        (topicId, 3, 8.1, 12.0, '問題の本質を見極めましょう。', 'もんだいのほんしつをみきわめましょう。', 'Mondai no honshitsu o mikiwamemashou.', 'Hãy nhìn ra bản chất vấn đề.');

        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

CALL seed_learning_path_n5_to_n1();

DROP PROCEDURE IF EXISTS seed_learning_path_n5_to_n1;

-- =========================================================
-- Quick checks
-- =========================================================
-- SELECT level, COUNT(*) AS lesson_count
-- FROM lessons
-- WHERE id BETWEEN 1101 AND 1120
--    OR id BETWEEN 2201 AND 2220
--    OR id BETWEEN 3301 AND 3320
--    OR id BETWEEN 4201 AND 4225
--    OR id BETWEEN 5101 AND 5125
-- GROUP BY level
-- ORDER BY level;
--
-- SELECT COUNT(*) AS vocab_count
-- FROM vocabularies
-- WHERE lesson_id BETWEEN 1101 AND 1120
--    OR lesson_id BETWEEN 2201 AND 2220
--    OR lesson_id BETWEEN 3301 AND 3320
--    OR lesson_id BETWEEN 4201 AND 4225
--    OR lesson_id BETWEEN 5101 AND 5125;
--
-- SELECT COUNT(*) AS topic_count
-- FROM shadowing_topics
-- WHERE id BETWEEN 11101 AND 11120
--    OR id BETWEEN 12201 AND 12220
--    OR id BETWEEN 13301 AND 13320
--    OR id BETWEEN 14201 AND 14225
--    OR id BETWEEN 15101 AND 15125;
--
-- SELECT COUNT(*) AS segment_count
-- FROM shadowing_segments
-- WHERE topic_id BETWEEN 11101 AND 11120
--    OR topic_id BETWEEN 12201 AND 12220
--    OR topic_id BETWEEN 13301 AND 13320
--    OR topic_id BETWEEN 14201 AND 14225
--    OR topic_id BETWEEN 15101 AND 15125;
