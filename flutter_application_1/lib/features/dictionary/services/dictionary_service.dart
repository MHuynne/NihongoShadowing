import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/features/dictionary/models/dictionary_models.dart';

class DictionaryService {
  static String get _baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// Tìm kiếm từ điển — trả về danh sách entry.
  static Future<DictionarySearchResult> search(String keyword,
      {int page = 1}) async {
    final uri = Uri.parse(
        '$_baseUrl/dictionary/search?q=${Uri.encodeComponent(keyword)}&page=$page');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return DictionarySearchResult.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Search failed: HTTP ${response.statusCode}');
  }

  /// Tra chi tiết 1 chữ Kanji
  static Future<KanjiDetail> fetchKanjiDetail(String character) async {
    final uri =
        Uri.parse('$_baseUrl/dictionary/kanji/${Uri.encodeComponent(character)}');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return KanjiDetail.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Kanji detail failed: HTTP ${response.statusCode}');
  }
}
