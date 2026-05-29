import 'dart:convert';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:flutter_application_1/core/config/api_config.dart';

class RoleplayService {
  static String get baseUrl => '${ApiConfig.baseUrl}/roleplay';

  // 1. Tạo hoặc lấy Scenario
  Future<int> getOrCreateScenario(String title, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scenarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['id'];
    } else {
      throw Exception('Failed to create scenario');
    }
  }

  // 2. Khởi tạo Session
  Future<int> createSession(int scenarioId, String mode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'scenario_id': scenarioId,
        'user_id': 1, // Mock user ID
        'mode': mode,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['id'];
    } else {
      throw Exception('Failed to create session');
    }
  }

  // 3. Chat với AI
  Future<Map<String, dynamic>> chatWithAI(int sessionId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': sessionId,
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to chat with AI');
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory({int userId = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/history?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load chat history');
    }
  }

  Future<Map<String, dynamic>> getChatHistoryDetail(
    int sessionId, {
    int userId = 1,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/history/$sessionId?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load chat history detail');
    }
  }
}
