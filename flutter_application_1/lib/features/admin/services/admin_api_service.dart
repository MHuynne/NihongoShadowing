import 'dart:convert';

import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class AdminApiService {
  final String _baseUrl = ApiConfig.baseUrl;

  String get baseUrl => _baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  Future<dynamic> _decodeResponse(http.Response response) async {
    if (response.bodyBytes.isEmpty) {
      return null;
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _uri(path, queryParameters);
    late http.Response response;

    switch (method) {
      case 'GET':
        response = await http.get(uri);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body ?? {}),
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body ?? {}),
        );
        break;
      case 'DELETE':
        response = await http.delete(uri);
        break;
      default:
        throw Exception('Unsupported method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response);
    }

    final payload = await _decodeResponse(response);
    final detail = payload is Map<String, dynamic> ? payload['detail'] : null;
    throw Exception(detail ?? 'HTTP ${response.statusCode}');
  }

  Future<String> uploadFile(List<int> bytes, String filename) async {
    final uri = _uri('/upload/');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = await _decodeResponse(response);
      return data['url'] as String;
    }
    final payload = await _decodeResponse(response);
    final detail = payload is Map<String, dynamic> ? payload['detail'] : null;
    throw Exception(detail ?? 'HTTP ${response.statusCode}');
  }

  Future<Map<String, dynamic>> fetchOverview() async {
    final data = await _request('GET', '/admin/overview');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> fetchLessons() async {
    final data = await _request('GET', '/lessons/');
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createLesson(Map<String, dynamic> lesson) async {
    final data = await _request('POST', '/lessons/', body: lesson);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> updateLesson(
    int lessonId,
    Map<String, dynamic> lesson,
  ) async {
    final data = await _request('PUT', '/lessons/$lessonId', body: lesson);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> deleteLesson(int lessonId) async {
    await _request('DELETE', '/lessons/$lessonId');
  }

  Future<List<Map<String, dynamic>>> fetchVocabularies({
    int? lessonId,
    int? topicId,
  }) async {
    final data = await _request(
      'GET',
      '/vocabularies/',
      queryParameters: {
        if (lessonId != null) 'lesson_id': lessonId,
        if (topicId != null) 'topic_id': topicId,
      },
    );
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createVocabulary(
    Map<String, dynamic> vocabulary,
  ) async {
    final data = await _request('POST', '/vocabularies/', body: vocabulary);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> updateVocabulary(
    int vocabularyId,
    Map<String, dynamic> vocabulary,
  ) async {
    final data = await _request(
      'PUT',
      '/vocabularies/$vocabularyId',
      body: vocabulary,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> deleteVocabulary(int vocabularyId) async {
    await _request('DELETE', '/vocabularies/$vocabularyId');
  }

  Future<String> generateShadowingAudio({
    required String script,
    double speed = 0.85,
    String voiceGender = 'female',
  }) async {
    final data = await _request(
      'POST',
      '/tts/generate-shadowing-audio',
      body: {
        'script': script,
        'speed': speed,
        'voice_gender': voiceGender,
      },
    );
    return data['url'] as String;
  }

  Future<List<Map<String, dynamic>>> fetchTopics() async {
    final data = await _request('GET', '/shadowing/topics/');
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createTopic(Map<String, dynamic> topic) async {
    final data = await _request('POST', '/shadowing/topics/', body: topic);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> updateTopic(
    int topicId,
    Map<String, dynamic> topic,
  ) async {
    final data =
        await _request('PUT', '/shadowing/topics/$topicId', body: topic);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> deleteTopic(int topicId) async {
    await _request('DELETE', '/shadowing/topics/$topicId');
  }

  Future<List<Map<String, dynamic>>> fetchScenarios() async {
    final data = await _request('GET', '/roleplay/scenarios');
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createScenario(
    Map<String, dynamic> scenario,
  ) async {
    final data = await _request('POST', '/roleplay/scenarios', body: scenario);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> updateScenario(
    int scenarioId,
    Map<String, dynamic> scenario,
  ) async {
    final data = await _request(
      'PUT',
      '/roleplay/scenarios/$scenarioId',
      body: scenario,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> deleteScenario(int scenarioId) async {
    await _request('DELETE', '/roleplay/scenarios/$scenarioId');
  }

  // ─── Shadowing Segments (độc lập) ────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAllSegments() async {
    final data = await _request('GET', '/shadowing/segments/all');
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createSegment(
    Map<String, dynamic> segment,
  ) async {
    final data = await _request(
      'POST',
      '/shadowing/segments/standalone',
      body: {...segment, 'topic_id': null},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> updateSegment(
    int segmentId,
    Map<String, dynamic> segment,
  ) async {
    final data = await _request(
      'PUT',
      '/shadowing/segments/$segmentId',
      body: {...segment, 'topic_id': null},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> deleteSegment(int segmentId) async {
    await _request('DELETE', '/shadowing/segments/$segmentId');
  }

  // ─── Categories ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final data = await _request('GET', '/categories/');
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createCategory(
      Map<String, dynamic> category) async {
    final data = await _request('POST', '/categories/', body: category);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> updateCategory(
    int categoryId,
    Map<String, dynamic> category,
  ) async {
    final data =
        await _request('PUT', '/categories/$categoryId', body: category);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> deleteCategory(int categoryId) async {
    await _request('DELETE', '/categories/$categoryId');
  }

  // ─── Gán categories vào segment ──────────────────────────────────────────

  Future<void> setSegmentCategories(
      int segmentId, List<int> categoryIds) async {
    // Gửi JSON array trực tiếp (không dùng _request vì body là List, không phải Map)
    final uri = _uri('/categories/segment/$segmentId/set-categories');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(categoryIds),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final payload = await _decodeResponse(response);
      final detail =
          payload is Map<String, dynamic> ? payload['detail'] : null;
      throw Exception(detail ?? 'HTTP ${response.statusCode}');
    }
  }
}
