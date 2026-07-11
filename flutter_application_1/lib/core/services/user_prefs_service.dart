import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:flutter/foundation.dart';



class UserPrefsService {
  static const String _levelKeyPrefix = 'jlpt_level_';
  static String get _base => ApiConfig.baseUrl;


  static final UserPrefsService _instance = UserPrefsService._internal();
  factory UserPrefsService() => _instance;
  UserPrefsService._internal();


  Map<String, String> _headers(String uid) {
    return {
      'Content-Type': 'application/json',
      'X-Firebase-UID': uid,
    };
  }


  Future<String?> getLevel(String uid) async {

    try {
      final res = await http.get(
        Uri.parse('$_base/profile/'),
        headers: _headers(uid),
      );
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(res.bodyBytes));
        final apiLevel = data['jlpt_level'] as String?;
        if (apiLevel != null && apiLevel.isNotEmpty) {

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('$_levelKeyPrefix$uid', apiLevel);
          return apiLevel;
        }
      }
    } catch (e) {
      debugPrint('[UserPrefsService] Failed to fetch level from API: $e');
    }


    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_levelKeyPrefix$uid');
  }


  Future<bool> hasSelectedLevel(String uid) async {
    final level = await getLevel(uid);
    return level != null && level.isNotEmpty;
  }


  Future<void> saveLevel(String uid, String level) async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_levelKeyPrefix$uid', level);


    try {
      final res = await http.put(
        Uri.parse('$_base/profile/level'),
        headers: _headers(uid),
        body: json.encode({'jlpt_level': level}),
      );
      if (res.statusCode != 200) {
        debugPrint('[UserPrefsService] Save level to API failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('[UserPrefsService] Failed to save level to API: $e');
    }
  }


  Future<void> clearLevel(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_levelKeyPrefix$uid');
  }
}