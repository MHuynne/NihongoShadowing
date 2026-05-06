SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

DELETE FROM shadowing_segments WHERE topic_id BETWEEN 7021 AND 7030;
DELETE FROM shadowing_topics   WHERE id        BETWEEN 7021 AND 7030;
DELETE FROM vocabularies       WHERE lesson_id  BETWEEN 6011 AND 6015;
DELETE FROM lessons            WHERE id         BETWEEN 6011 AND 6015;

-- BÀI 11: Sở thích và hoạt động
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6011, 'N5', N'Bài 11 – Sở thích (しゅみはなんですか)', 11);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6011, NULL, 'しゅみ', 'しゅみ', N'Sở thích', 'しゅみはなんですか。'),
(6011, NULL, 'おんがく', 'おんがく', N'Âm nhạc', 'おんがくをきくのがすきです。'),
(6011, NULL, 'えいが', 'えいが', N'Phim', 'えいがをみます。'),
(6011, NULL, 'スポーツ', 'スポーツ', N'Thể thao', 'スポーツがすきです。'),
(6011, NULL, 'よむ', 'よむ', N'Đọc', 'ほんをよみます。'),
(6011, NULL, 'すき', 'すき', N'Thích', 'りょうりがすきです。'),
(6011, NULL, 'きらい', 'きらい', N'Ghét / Không thích', 'さかなはきらいです。'),
(6011, NULL, 'とくい', 'とくい', N'Giỏi / Sở trường', 'えいごがとくいです。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7021, N'Hỏi sở thích – しゅみは何ですか', 'N5', 6011,
 'しゅみはなんですか。おんがくをきくのがすきです。どんなおんがくですか。Jポップがすきです。', 23.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7021, 1,  0.0,  7.0, 'しゅみはなんですか。おんがくをきくのがすきです。', 'しゅみはなんですか。おんがくをきくのがすきです。', 'Shumi wa nan desuka. Ongaku o kiku no ga suki desu.', N'Sở thích là gì? Thích nghe nhạc.', N'Sở thích của bạn là gì? Tôi thích nghe nhạc.'),
(7021, 2,  7.5, 14.0, 'どんなおんがくですか。', 'どんなおんがくですか。', 'Donna ongaku desuka.', N'Nhạc loại gì?', N'Bạn thích nhạc gì?'),
(7021, 3, 14.5, 22.0, 'Jポップがすきです。', 'Jポップがすきです。', 'Jei poppu ga suki desu.', N'Thích nhạc J-Pop.', N'Tôi thích nhạc J-Pop.');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7022, N'Rủ đi xem phim – 映画に行きませんか', 'N5', 6011,
 'えいがをみませんか。いいですね。なんのえいがですか。アクションえいがです。たのしそうですね。', 23.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7022, 1,  0.0,  6.0, 'えいがをみませんか。いいですね。', 'えいがをみませんか。いいですね。', 'Eiga o mimasenka. Ii desune.', N'Đi xem phim không? Hay đấy.', N'Chúng ta đi xem phim không? Hay đấy nhỉ.'),
(7022, 2,  6.5, 13.0, 'なんのえいがですか。アクションえいがです。', 'なんのえいがですか。アクションえいがです。', 'Nan no eiga desuka. Akushon eiga desu.', N'Phim gì? Phim hành động.', N'Phim gì vậy? Là phim hành động.'),
(7022, 3, 13.5, 22.0, 'たのしそうですね。', 'たのしそうですね。', 'Tanoshisou desune.', N'Có vẻ vui nhỉ.', N'Có vẻ vui lắm nhỉ!');

-- BÀI 12: Thời tiết
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6012, 'N5', N'Bài 12 – Thời tiết (てんき)', 12);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6012, NULL, 'てんき', 'てんき', N'Thời tiết', 'きょうのてんきはいいです。'),
(6012, NULL, 'はれ', 'はれ', N'Trời nắng / Quang đãng', 'きょうははれです。'),
(6012, NULL, 'くもり', 'くもり', N'Trời mây / Âm u', 'あしたはくもりです。'),
(6012, NULL, 'あめ', 'あめ', N'Mưa', 'あめがふっています。'),
(6012, NULL, 'さむい', 'さむい', N'Lạnh', 'きょうはさむいですね。'),
(6012, NULL, 'あつい', 'あつい', N'Nóng', 'なつはあついです。'),
(6012, NULL, 'かぜ', 'かぜ', N'Gió', 'かぜがつよいです。'),
(6012, NULL, 'きせつ', 'きせつ', N'Mùa', 'すきなきせつはなんですか。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7023, N'Nói về thời tiết – 天気の話', 'N5', 6012,
 'きょうのてんきはどうですか。はれています。でもかぜがつよいですね。そうですね、さむいです。', 22.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7023, 1,  0.0,  6.0, 'きょうのてんきはどうですか。はれています。', 'きょうのてんきはどうですか。はれています。', 'Kyou no tenki wa dou desuka. Harete imasu.', N'Thời tiết hôm nay thế nào? Đang nắng.', N'Thời tiết hôm nay thế nào? Trời đang nắng.'),
(7023, 2,  6.5, 13.0, 'でもかぜがつよいですね。', 'でもかぜがつよいですね。', 'Demo kaze ga tsuyoi desune.', N'Nhưng gió mạnh nhỉ.', N'Nhưng gió khá mạnh nhỉ.'),
(7023, 3, 13.5, 21.0, 'そうですね、さむいです。', 'そうですね、さむいです。', 'Sou desune, samui desu.', N'Đúng rồi, lạnh quá.', N'Đúng nhỉ, lạnh thật.');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7024, N'Dự báo thời tiết – 天気予報', 'N5', 6012,
 'あしたのてんきはなんですか。あめです。かさをもっていきましょう。わかりました。きをつけてください。', 22.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7024, 1,  0.0,  6.5, 'あしたのてんきはなんですか。あめです。', 'あしたのてんきはなんですか。あめです。', 'Ashita no tenki wa nan desuka. Ame desu.', N'Thời tiết ngày mai? Mưa.', N'Thời tiết ngày mai thế nào? Là mưa.'),
(7024, 2,  7.0, 13.0, 'かさをもっていきましょう。わかりました。', 'かさをもっていきましょう。わかりました。', 'Kasa o motte ikimashou. Wakarimashita.', N'Mang ô đi. Hiểu rồi.', N'Hãy mang ô theo nhé. Vâng, tôi hiểu rồi.'),
(7024, 3, 13.5, 21.0, 'きをつけてください。', 'きをつけてください。', 'Ki o tsukete kudasai.', N'Hãy cẩn thận.', N'Hãy cẩn thận nhé!');

-- BÀI 13: Trong nhà – Đồ đạc
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6013, 'N5', N'Bài 13 – Trong nhà (うちのなか)', 13);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6013, NULL, 'へや', 'へや', N'Phòng', 'わたしのへやはひろいです。'),
(6013, NULL, 'テーブル', 'テーブル', N'Bàn', 'テーブルのうえにほんがあります。'),
(6013, NULL, 'いす', 'いす', N'Ghế', 'いすにすわります。'),
(6013, NULL, 'テレビ', 'テレビ', N'Ti vi', 'テレビをみます。'),
(6013, NULL, 'れいぞうこ', 'れいぞうこ', N'Tủ lạnh', 'れいぞうこのなかにたまごがあります。'),
(6013, NULL, 'うえ', 'うえ', N'Trên / Ở trên', 'テーブルのうえにあります。'),
(6013, NULL, 'した', 'した', N'Dưới / Ở dưới', 'いすのしたにあります。'),
(6013, NULL, 'となり', 'となり', N'Bên cạnh', 'テレビのとなりにあります。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7025, N'Tìm đồ vật trong nhà – どこにありますか', 'N5', 6013,
 'ねこはどこにいますか。テーブルのしたにいます。ほんはどこにありますか。いすのうえにあります。', 22.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7025, 1,  0.0,  6.5, 'ねこはどこにいますか。テーブルのしたにいます。', 'ねこはどこにいますか。テーブルのしたにいます。', 'Neko wa doko ni imasuka. Teburu no shita ni imasu.', N'Con mèo ở đâu? Dưới bàn.', N'Con mèo đang ở đâu? Đang ở dưới bàn.'),
(7025, 2,  7.0, 13.0, 'ほんはどこにありますか。', 'ほんはどこにありますか。', 'Hon wa doko ni arimasuka.', N'Quyển sách ở đâu?', N'Quyển sách ở đâu vậy?'),
(7025, 3, 13.5, 21.0, 'いすのうえにあります。', 'いすのうえにあります。', 'Isu no ue ni arimasu.', N'Trên ghế.', N'Ở trên ghế.');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7026, N'Mô tả căn phòng – 部屋の説明', 'N5', 6013,
 'わたしのへやにはテレビとテーブルといすがあります。テレビはかべのとなりにあります。とてもひろいです。', 23.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7026, 1,  0.0,  8.0, 'わたしのへやにはテレビとテーブルといすがあります。', 'わたしのへやにはテレビとテーブルといすがあります。', 'Watashi no heya ni wa terebi to teburu to isu ga arimasu.', N'Phòng tôi có ti vi, bàn và ghế.', N'Trong phòng tôi có ti vi, bàn và ghế.'),
(7026, 2,  8.5, 15.0, 'テレビはかべのとなりにあります。', 'テレビはかべのとなりにあります。', 'Terebi wa kabe no tonari ni arimasu.', N'Ti vi ở cạnh tường.', N'Ti vi đặt cạnh bức tường.'),
(7026, 3, 15.5, 22.0, 'とてもひろいです。', 'とてもひろいです。', 'Totemo hiroi desu.', N'Rộng lắm.', N'Rộng lắm!');

-- BÀI 14: Điện thoại và liên lạc
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6014, 'N5', N'Bài 14 – Gọi điện (でんわ)', 14);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6014, NULL, 'でんわ', 'でんわ', N'Điện thoại', 'でんわをします。'),
(6014, NULL, 'もしもし', 'もしもし', N'A lô', 'もしもし、たなかさんですか。'),
(6014, NULL, 'しょうしょうまってください', 'しょうしょうまってください', N'Vui lòng chờ một chút', 'しょうしょうおまちください。'),
(6014, NULL, 'でんわばんごう', 'でんわばんごう', N'Số điện thoại', 'でんわばんごうはなんですか。'),
(6014, NULL, 'かける', 'かける', N'Gọi (điện thoại)', 'でんわをかけます。'),
(6014, NULL, 'でる', 'でる', N'Nghe máy / Ra', 'でんわにでます。'),
(6014, NULL, 'また', 'また', N'Lại / Lần nữa', 'またでんわします。'),
(6014, NULL, 'メッセージ', 'メッセージ', N'Tin nhắn', 'メッセージをおくります。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7027, N'Gọi điện thoại – 電話をかける', 'N5', 6014,
 'もしもし、たなかさんですか。はい、たなかです。やまださんですか。そうです。いまいいですか。はい、どうぞ。', 25.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7027, 1,  0.0,  7.0, 'もしもし、たなかさんですか。はい、たなかです。', 'もしもし、たなかさんですか。はい、たなかです。', 'Moshimoshi, Tanaka-san desuka. Hai, Tanaka desu.', N'A lô, có phải anh Tanaka? Vâng tôi là Tanaka.', N'A lô, có phải anh Tanaka không? Vâng, tôi là Tanaka.'),
(7027, 2,  7.5, 15.0, 'やまださんですか。そうです。', 'やまださんですか。そうです。', 'Yamada-san desuka. Sou desu.', N'Có phải anh Yamada? Đúng vậy.', N'Có phải anh Yamada không? Đúng vậy.'),
(7027, 3, 15.5, 24.0, 'いまいいですか。はい、どうぞ。', 'いまいいですか。はい、どうぞ。', 'Ima ii desuka. Hai, douzo.', N'Bây giờ có tiện không? Vâng, mời.', N'Bây giờ có tiện không? Vâng, mời nói.');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7028, N'Nhắn tin – メッセージを送る', 'N5', 6014,
 'でんわばんごうはなんですか。ぜろさんのよんにのごろくです。わかりました。メッセージをおくります。ありがとうございます。', 24.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7028, 1,  0.0,  7.0, 'でんわばんごうはなんですか。', 'でんわばんごうはなんですか。', 'Denwa bangou wa nan desuka.', N'Số điện thoại là bao nhiêu?', N'Số điện thoại của bạn là bao nhiêu?'),
(7028, 2,  7.5, 15.0, 'ぜろさんのよんにのごろくです。わかりました。', 'ぜろさんのよんにのごろくです。わかりました。', 'Zero san no yonni no goroku desu. Wakarimashita.', N'03-42-56. Hiểu rồi.', N'Là 03-42-56. Tôi hiểu rồi.'),
(7028, 3, 15.5, 23.0, 'メッセージをおくります。ありがとうございます。', 'メッセージをおくります。ありがとうございます。', 'Messeeji o okurimasu. Arigatou gozaimasu.', N'Sẽ nhắn tin. Cảm ơn.', N'Tôi sẽ nhắn tin cho bạn. Cảm ơn nhé.');

-- BÀI 15: Sức khỏe – Khám bệnh
INSERT INTO lessons (id, level, chapter_name, order_index) VALUES
(6015, 'N5', N'Bài 15 – Sức khoẻ (からだ・びょうき)', 15);

INSERT INTO vocabularies (lesson_id, topic_id, word, reading, meaning, example) VALUES
(6015, NULL, 'からだ', 'からだ', N'Cơ thể / Sức khoẻ', 'からだのぐあいはどうですか。'),
(6015, NULL, 'あたま', 'あたま', N'Đầu', 'あたまがいたいです。'),
(6015, NULL, 'おなか', 'おなか', N'Bụng', 'おなかがいたいです。'),
(6015, NULL, 'ねつ', 'ねつ', N'Sốt', 'ねつがあります。'),
(6015, NULL, 'くすり', 'くすり', N'Thuốc', 'くすりをのみます。'),
(6015, NULL, 'びょういん', 'びょういん', N'Bệnh viện', 'びょういんへいきます。'),
(6015, NULL, 'いたい', 'いたい', N'Đau', 'あしがいたいです。'),
(6015, NULL, 'だいじょうぶ', 'だいじょうぶ', N'Không sao / Ổn', 'だいじょうぶですか。');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7029, N'Khám bệnh – 病院で', 'N5', 6015,
 'どうしましたか。あたまがいたいです。ねつはありますか。はい、すこしあります。くすりをのんでください。', 24.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7029, 1,  0.0,  6.0, 'どうしましたか。あたまがいたいです。', 'どうしましたか。あたまがいたいです。', 'Doushimashitaka. Atama ga itai desu.', N'Bạn bị sao vậy? Đau đầu.', N'Bạn bị làm sao vậy? Tôi bị đau đầu.'),
(7029, 2,  6.5, 14.0, 'ねつはありますか。はい、すこしあります。', 'ねつはありますか。はい、すこしあります。', 'Netsu wa arimasuka. Hai, sukoshi arimasu.', N'Có sốt không? Có một chút.', N'Bạn có bị sốt không? Vâng, hơi sốt một chút.'),
(7029, 3, 14.5, 23.0, 'くすりをのんでください。', 'くすりをのんでください。', 'Kusuri o nonde kudasai.', N'Hãy uống thuốc.', N'Hãy uống thuốc nhé.');

INSERT INTO shadowing_topics (id, title, level, lesson_id, full_script_ja, total_duration) VALUES
(7030, N'Hỏi thăm sức khoẻ – お体の具合は?', 'N5', 6015,
 'おからだのぐあいはいかがですか。おなかがいたいです。びょういんへいきましたか。いいえ、まだです。はやくいってください。', 25.0);

INSERT INTO shadowing_segments (topic_id, order_index, start_time, end_time, kanji_content, furigana, romaji, sino_vietnamese, translation_vi) VALUES
(7030, 1,  0.0,  7.0, 'おからだのぐあいはいかがですか。おなかがいたいです。', 'おからだのぐあいはいかがですか。おなかがいたいです。', 'Okarada no guai wa ikaga desuka. Onaka ga itai desu.', N'Sức khoẻ thế nào? Đau bụng.', N'Sức khoẻ của bạn thế nào? Tôi bị đau bụng.'),
(7030, 2,  7.5, 15.0, 'びょういんへいきましたか。いいえ、まだです。', 'びょういんへいきましたか。いいえ、まだです。', 'Byouin e ikimashitaka. Iie, mada desu.', N'Đi bệnh viện chưa? Chưa.', N'Bạn đã đến bệnh viện chưa? Chưa, chưa đi.'),
(7030, 3, 15.5, 24.0, 'はやくいってください。', 'はやくいってください。', 'Hayaku itte kudasai.', N'Hãy đi sớm đi.', N'Hãy đến bệnh viện sớm nhé!');
