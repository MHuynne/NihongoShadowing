import 'dart:convert';

import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class AdminApiService {
  final String _baseUrl = ApiConfig.baseUrl;

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
}
