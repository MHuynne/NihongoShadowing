import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Service gọi API /progress — lưu tiến độ học của user theo từng lesson.
class ProgressService {
  // ── Base URL (tự chọn theo platform) ─────────────────────────────────
  static String get _base {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  // ── Lấy Firebase UID hiện tại ─────────────────────────────────────────
  static Future<String?> _getUid() async {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // ── Headers chung (kèm X-Firebase-UID) ───────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final uid = await _getUid();
    return {
      'Content-Type': 'application/json',
      if (uid != null) 'X-Firebase-UID': uid,
    };
  }

  // ── Lấy tiến độ của 1 lesson ─────────────────────────────────────────
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

  /// Lấy tiến độ của TẤT CẢ lesson (dùng cho Roadmap Screen).
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

  // ── Cập nhật sau khi xem xong Flashcard ──────────────────────────────
  static Future<void> markFlashcardDone(int lessonId) async {
    await _patch(lessonId, {'flashcard_done': true});
  }

  // ── Cập nhật sau khi hoàn thành Vocabulary Test ───────────────────────
  /// [score] là điểm phần trăm (0–100).
  static Future<void> saveTestResult(int lessonId, double score) async {
    final passed = score >= 70.0;
    await _patch(lessonId, {
      'test_score': score,
      'test_passed': passed,
    });
  }

  // ── Cập nhật sau khi hoàn thành Shadowing ────────────────────────────
  /// [score] là điểm phần trăm (0–100).
  static Future<void> saveShadowingResult(int lessonId, double score) async {
    final passed = score >= 80.0;
    await _patch(lessonId, {
      'shadowing_score': score,
      'shadowing_passed': passed,
    });
  }

  // ── Đánh dấu hoàn thành lesson (mở khoá bài kế tiếp) ─────────────────
  /// Gọi sau khi user hoàn thành bước Shadowing — dù điểm cao hay thấp.
  static Future<void> markLessonCompleted(int lessonId) async {
    await _patch(lessonId, {'lesson_completed': true});
  }

  // ── Gửi PATCH request ─────────────────────────────────────────────────
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
