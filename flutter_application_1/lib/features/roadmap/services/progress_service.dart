import 'dart:convert';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:flutter/foundation.dart';


class ProgressService {
  static String get _base => ApiConfig.baseUrl;


  static Future<String> _getUid() async {
    return FirebaseAuth.instance.currentUser?.uid ?? 'mock_user_id';
  }


  static Future<Map<String, String>> _headers() async {
    final uid = await _getUid();
    return {
      'Content-Type': 'application/json',
      'X-Firebase-UID': uid,
    };
  }


  static Future<Map<String, dynamic>?> getProgress(int lessonId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/progress/$lessonId'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return json.decode(utf8.decode(res.bodyBytes));
      }
    } catch (e) {
      debugPrint('[ProgressService] getProgress error: $e');
    }
    return null;
  }


  static Future<List<Map<String, dynamic>>> getAllProgress() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/progress/'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('[ProgressService] getAllProgress error: $e');
    }
    return [];
  }


  static Future<void> markFlashcardDone(int lessonId) async {
    await _patch(lessonId, {'flashcard_done': true});
  }



  static Future<void> saveTestResult(int lessonId, double score) async {
    final passed = score >= 70.0;
    await _patch(lessonId, {
      'test_score': score,
      'test_passed': passed,
    });
  }



  static Future<void> saveShadowingResult(int lessonId, double score) async {
    final passed = score >= 80.0;
    await _patch(lessonId, {
      'shadowing_score': score,
      'shadowing_passed': passed,
    });
  }



  static Future<void> markLessonCompleted(int lessonId) async {
    await _patch(lessonId, {'lesson_completed': true});
  }


  static Future<void> _patch(int lessonId, Map<String, dynamic> body) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base/progress/$lessonId'),
        headers: await _headers(),
        body: json.encode(body),
      );
      if (res.statusCode != 200) {
        debugPrint('[ProgressService] PATCH failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('[ProgressService] _patch error: $e');
    }
  }
}