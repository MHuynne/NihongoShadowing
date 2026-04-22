import 'dart:convert';
import 'package:http/http.dart' as http;

class RoleplayService {
  // Đối với Android Emulator, 10.0.2.2 trỏ về localhost của máy tính
  static const String baseUrl = 'http://127.0.0.1:8000/roleplay';

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
}
