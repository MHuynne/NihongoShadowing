import 'dart:convert';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/auth_gate.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/features/roadmap/services/progress_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _targetLevelKey = 'profile_target_level';

  final _auth = AuthService();
  Future<_ProfileData>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfileData();
  }

  Future<_ProfileData> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final targetLevel = prefs.getString(_targetLevelKey) ?? 'N3';
    final progress = await ProgressService.getAllProgress();
    return _ProfileData(
      targetLevel: targetLevel,
      stats: _ProfileStats.fromProgress(progress),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = _loadProfileData();
    });
    await _profileFuture;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SakuraNightBackground(
        child: SafeArea(
          child: FutureBuilder<_ProfileData>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? _ProfileData.empty();
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;

              return RefreshIndicator(
                color: SNJ.sakura,
                backgroundColor: SNJ.bgMid,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'HỒ SƠ CÁ NHÂN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ProfileHeader(
                        user: user,
                        targetLevel: data.targetLevel,
                        streakDays: data.stats.streakDays,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 20),
                      _ExperienceCard(stats: data.stats),
                      const SizedBox(height: 16),
                      _StatsGrid(stats: data.stats),
                      const SizedBox(height: 20),
                      _ActivityHistoryCard(stats: data.stats),
                      const SizedBox(height: 20),
                      _AccountActions(
                        user: user,
                        onEditProfile: () => _showEditProfileSheet(
                          user: user,
                        ),
                        onDeleteAccount: _confirmDeleteAccount,
                        onSignOut: () => _confirmSignOut(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileSheet({
    required User? user,
  }) async {
    final nameController = TextEditingController(
      text: user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!.trim()
          : '',
    );
    var selectedPhotoUrl = user?.photoURL ?? '';
    String? selectedPhotoName;
    var isUploadingAvatar = false;
    final email = user?.email?.trim();
    final phoneNumber = user?.phoneNumber?.trim();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SNJ.bgMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetHandle(),
                  const SizedBox(height: 18),
                  const Text(
                    'Chỉnh sửa hồ sơ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ProfileTextField(
                    controller: nameController,
                    label: 'Tên hiển thị',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  _ReadOnlyProfileInfoTile(
                    label: 'Email',
                    value: email?.isNotEmpty == true ? email! : 'Chưa có email',
                    icon: Icons.email_outlined,
                  ),
                  if (phoneNumber?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _ReadOnlyProfileInfoTile(
                      label: 'Số điện thoại',
                      value: phoneNumber!,
                      icon: Icons.phone_outlined,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _AvatarPicker(
                    photoUrl: selectedPhotoUrl,
                    fileName: selectedPhotoName,
                    isUploading: isUploadingAvatar,
                    displayName: nameController.text,
                    onPick: () async {
                      setSheetState(() => isUploadingAvatar = true);
                      try {
                        final uploadedUrl = await _pickAndUploadAvatar();
                        if (!context.mounted) return;
                        if (uploadedUrl == null) {
                          return;
                        }
                        setSheetState(() {
                          selectedPhotoUrl = uploadedUrl.url;
                          selectedPhotoName = uploadedUrl.fileName;
                        });
                      } catch (e) {
                        if (mounted) {
                          _showSnack('Không thể tải ảnh lên: $e');
                        }
                      } finally {
                        if (context.mounted) {
                          setSheetState(() => isUploadingAvatar = false);
                        }
                      }
                    },
                    onRemove: selectedPhotoUrl.trim().isEmpty
                        ? null
                        : () {
                            setSheetState(() {
                              selectedPhotoUrl = '';
                              selectedPhotoName = null;
                            });
                          },
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: SNJ.sakuraGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: SNJ.sakura.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          _showSnack('Tên hiển thị không được bỏ trống.');
                          return;
                        }

                        try {
                          await _auth.updateProfile(
                            displayName: nameController.text,
                            photoUrl: selectedPhotoUrl,
                          );
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop(true);
                          }
                        } on FirebaseAuthException catch (e) {
                          _showSnack(AuthService.getVietnameseError(e));
                        } catch (e) {
                          _showSnack('Không thể cập nhật hồ sơ: $e');
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text(
                        'Lưu thay đổi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameController.dispose();

    if (saved == true && mounted) {
      _showSnack('Hồ sơ đã được cập nhật.');
      setState(() {});
    }
  }

  Future<_UploadedAvatar?> _pickAndUploadAvatar() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final path = file.path;
    final bytes = file.bytes;
    if ((path == null || path.isEmpty) && (bytes == null || bytes.isEmpty)) {
      throw Exception('Không thể đọc hình ảnh đã chọn.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/upload/'),
    );
    if (!kIsWeb && path != null && path.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          path,
          filename: file.name,
        ),
      );
    } else {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes!,
          filename: file.name,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final payload = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = payload is Map<String, dynamic> ? payload['detail'] : null;
      throw Exception(detail ?? 'HTTP ${response.statusCode}');
    }

    final rawUrl = payload['url']?.toString();
    if (rawUrl == null || rawUrl.isEmpty) {
      throw Exception('Phản hồi tải lên không bao gồm URL hình ảnh.');
    }

    final absoluteUrl =
        rawUrl.startsWith('http') ? rawUrl : '${ApiConfig.baseUrl}$rawUrl';
    return _UploadedAvatar(url: absoluteUrl, fileName: file.name);
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SNJ.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: SNJ.border, width: 1.0),
        ),
        title: const Text(
          'Xóa tài khoản?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Hành động này sẽ xóa tài khoản Firebase của bạn khỏi thiết bị này. Bạn có thể cần đăng nhập lại gần đây trước khi Firebase cho phép xóa.',
          style: TextStyle(color: SNJ.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy', style: TextStyle(color: SNJ.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _auth.deleteAccount();
    } on FirebaseAuthException catch (e) {
      _showSnack(AuthService.getVietnameseError(e));
    } catch (e) {
      _showSnack('Không thể xóa tài khoản: $e');
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SNJ.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: SNJ.border, width: 1.0),
        ),
        title: const Text(
          'Đăng xuất?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn sẽ quay trở lại màn hình đăng nhập.',
          style: TextStyle(color: SNJ.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy', style: TextStyle(color: SNJ.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SNJ.sakura,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && context.mounted) {
      await _auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileData {
  final String targetLevel;
  final _ProfileStats stats;

  const _ProfileData({
    required this.targetLevel,
    required this.stats,
  });

  factory _ProfileData.empty() {
    return _ProfileData(
      targetLevel: 'N3',
      stats: _ProfileStats.empty(),
    );
  }
}

class _UploadedAvatar {
  final String url;
  final String fileName;

  const _UploadedAvatar({
    required this.url,
    required this.fileName,
  });
}

class _ProfileStats {
  final int totalXp;
  final int lessonsDone;
  final int flashcardsDone;
  final int studyMinutes;
  final int averageAccuracy;
  final int streakDays;
  final List<int> xpLast7Days;

  const _ProfileStats({
    required this.totalXp,
    required this.lessonsDone,
    required this.flashcardsDone,
    required this.studyMinutes,
    required this.averageAccuracy,
    required this.streakDays,
    required this.xpLast7Days,
  });

  factory _ProfileStats.empty() {
    return const _ProfileStats(
      totalXp: 0,
      lessonsDone: 0,
      flashcardsDone: 0,
      studyMinutes: 0,
      averageAccuracy: 0,
      streakDays: 0,
      xpLast7Days: [0, 0, 0, 0, 0, 0, 0],
    );
  }

  factory _ProfileStats.fromProgress(List<Map<String, dynamic>> progress) {
    if (progress.isEmpty) return _ProfileStats.empty();

    var lessonsDone = 0;
    var flashcardsDone = 0;
    var studyMinutes = 0;
    var totalXp = 0;
    final scores = <double>[];
    final xpByDay = <DateTime, int>{};
    final activeDays = <DateTime>{};

    for (final item in progress) {
      final flashcardDone = item['flashcard_done'] == true;
      final lessonCompleted = item['lesson_completed'] == true;
      final testScore = _asDouble(item['test_score']);
      final shadowingScore = _asDouble(item['shadowing_score']);
      final updatedAt = _parseDate(item['updated_at']);
      final day = updatedAt == null ? null : _dateOnly(updatedAt);

      if (flashcardDone) {
        flashcardsDone++;
        studyMinutes += 5;
        totalXp += 20;
      }
      if (testScore != null) {
        scores.add(testScore);
        studyMinutes += 8;
        totalXp += testScore.round();
      }
      if (shadowingScore != null) {
        scores.add(shadowingScore);
        studyMinutes += 10;
        totalXp += shadowingScore.round();
      }
      if (lessonCompleted) {
        lessonsDone++;
        totalXp += 120;
      }
      if (day != null &&
          (flashcardDone || testScore != null || shadowingScore != null)) {
        activeDays.add(day);
        xpByDay[day] = (xpByDay[day] ?? 0) +
            _xpForRecord(
              flashcardDone: flashcardDone,
              lessonCompleted: lessonCompleted,
              testScore: testScore,
              shadowingScore: shadowingScore,
            );
      }
    }

    final now = _dateOnly(DateTime.now());
    final xpLast7Days = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return xpByDay[day] ?? 0;
    });

    return _ProfileStats(
      totalXp: totalXp,
      lessonsDone: lessonsDone,
      flashcardsDone: flashcardsDone,
      studyMinutes: studyMinutes,
      averageAccuracy: scores.isEmpty
          ? 0
          : (scores.reduce((a, b) => a + b) / scores.length).round(),
      streakDays: _streakFromDays(activeDays),
      xpLast7Days: xpLast7Days,
    );
  }

  static int _xpForRecord({
    required bool flashcardDone,
    required bool lessonCompleted,
    required double? testScore,
    required double? shadowingScore,
  }) {
    return (flashcardDone ? 20 : 0) +
        (lessonCompleted ? 120 : 0) +
        (testScore?.round() ?? 0) +
        (shadowingScore?.round() ?? 0);
  }

  static int _streakFromDays(Set<DateTime> activeDays) {
    if (activeDays.isEmpty) return 0;
    var cursor = _dateOnly(DateTime.now());
    if (!activeDays.contains(cursor)) {
      final yesterday = cursor.subtract(const Duration(days: 1));
      if (!activeDays.contains(yesterday)) return 0;
      cursor = yesterday;
    }

    var streak = 0;
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class _ProfileHeader extends StatelessWidget {
  final User? user;
  final String targetLevel;
  final int streakDays;
  final bool isLoading;

  const _ProfileHeader({
    required this.user,
    required this.targetLevel,
    required this.streakDays,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'Learner';
    final email = user?.email ?? 'No email';
    final photoUrl = user?.photoURL;

    return GlassCard(
      neonBorder: true,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SNJ.sakuraGradient,
                  boxShadow: [
                    BoxShadow(
                      color: SNJ.sakura.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: SNJ.bgMid,
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: _Avatar(photoUrl: photoUrl, displayName: displayName),
                  ),
                ),
              ),
              Positioned(
                bottom: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: user?.emailVerified == true
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: (user?.emailVerified == true
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B))
                            .withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    user?.emailVerified == true ? 'ĐÃ XÁC MINH' : 'CHƯA XÁC MINH',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_rounded, color: SNJ.sakura, size: 16),
              const SizedBox(width: 6),
              Text(
                'Mục tiêu JLPT $targetLevel',
                style: const TextStyle(
                  color: SNJ.sakura,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SNJ.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      isLoading ? 'Đang tải...' : 'Chuỗi: $streakDays ngày',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SNJ.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;

  const _Avatar({
    required this.photoUrl,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _InitialsAvatar(displayName: displayName),
      );
    }
    return _InitialsAvatar(displayName: displayName);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String displayName;

  const _InitialsAvatar({required this.displayName});

  @override
  Widget build(BuildContext context) {
    final initials = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: SNJ.sakuraGradient,
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? 'U' : initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final _ProfileStats stats;

  const _ExperienceCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(
              decoration: const BoxDecoration(
                gradient: SNJ.sakuraGradient,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TỔNG ĐIỂM KINH NGHIỆM',
                        style: TextStyle(
                          color: SNJ.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${stats.totalXp} XP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: SNJ.sakuraSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: SNJ.borderNeon, width: 1.2),
                  ),
                  child: const Icon(
                    Icons.military_tech_rounded,
                    color: SNJ.sakura,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _ProfileStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.42,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        _StatTile(
          icon: Icons.style_rounded,
          label: 'THẺ TỪ ĐÃ THUỘC',
          value: '${stats.flashcardsDone}',
          accent: SNJ.sakura,
        ),
        _StatTile(
          icon: Icons.schedule_rounded,
          label: 'THỜI GIAN HỌC',
          value: _formatStudyTime(stats.studyMinutes),
          accent: const Color(0xFF10B981),
        ),
        _StatTile(
          icon: Icons.check_circle_outline_rounded,
          label: 'BÀI HỌC HOÀN THÀNH',
          value: '${stats.lessonsDone}',
          accent: const Color(0xFFF59E0B),
        ),
        _StatTile(
          icon: Icons.trending_up_rounded,
          label: 'ĐỘ CHÍNH XÁC',
          value: '${stats.averageAccuracy}%',
          accent: const Color(0xFF6366F1),
        ),
      ],
    );
  }

  static String _formatStudyTime(int minutes) {
    if (minutes < 60) return '${minutes}phút';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return remain == 0 ? '${hours}giờ' : '${hours}g ${remain}p';
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(0.2), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SNJ.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityHistoryCard extends StatelessWidget {
  final _ProfileStats stats;

  const _ActivityHistoryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalWeekXp = stats.xpLast7Days.fold<int>(0, (a, b) => a + b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lịch sử hoạt động',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Số điểm XP nhận được trong 7 ngày qua',
                      style: TextStyle(
                        color: SNJ.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SNJ.sakuraSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: SNJ.borderNeon, width: 0.8),
                ),
                child: Text(
                  '+$totalWeekXp XP',
                  style: const TextStyle(
                    color: SNJ.sakura,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _ActivityChartPainter(
                values: stats.xpLast7Days,
                barColor: SNJ.sakura,
                mutedColor: SNJ.sakuraSoft,
                gridColor: Colors.white.withOpacity(0.06),
                textColor: SNJ.textSecondary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChartPainter extends CustomPainter {
  final List<int> values;
  final Color barColor;
  final Color mutedColor;
  final Color gridColor;
  final Color textColor;

  const _ActivityChartPainter({
    required this.values,
    required this.barColor,
    required this.mutedColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final safeValues = values.length == 7 ? values : [0, 0, 0, 0, 0, 0, 0];
    final maxValue = safeValues.fold<int>(0, (a, b) => a > b ? a : b);
    final today = DateTime.now();
    final days = List.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      return names[day.weekday - 1];
    });
    const bottomLabelHeight = 24.0;
    final chartHeight = size.height - bottomLabelHeight;
    final slotWidth = size.width / safeValues.length;
    final barWidth = slotWidth * 0.54;
    final radius = Radius.circular(barWidth / 2);

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartHeight * (0.18 + i * 0.22);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < safeValues.length; i++) {
      final normalized = maxValue == 0 ? 0.06 : safeValues[i] / maxValue;
      final left = slotWidth * i + (slotWidth - barWidth) / 2;
      final height = chartHeight * normalized.clamp(0.06, 1.0);
      final top = chartHeight - height;
      final rect = Rect.fromLTWH(left, top, barWidth, height);
      final isPeak = safeValues[i] == maxValue && maxValue > 0;
      final paint = Paint()
        ..color = isPeak
            ? barColor
            : Color.lerp(mutedColor, barColor, normalized * 0.35)!
                .withValues(alpha: maxValue == 0 ? 0.28 : 0.58);

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: radius,
          topRight: radius,
          bottomLeft: const Radius.circular(6),
          bottomRight: const Radius.circular(6),
        ),
        paint,
      );

      final dayPainter = TextPainter(
        text: TextSpan(
          text: days[i],
          style: TextStyle(
            color: isPeak ? barColor : textColor,
            fontSize: 10,
            fontWeight: isPeak ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      dayPainter.paint(
        canvas,
        Offset(
          slotWidth * i + (slotWidth - dayPainter.width) / 2,
          chartHeight + 10,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.barColor != barColor ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}

class _AccountActions extends StatelessWidget {
  final User? user;
  final VoidCallback onEditProfile;
  final VoidCallback onDeleteAccount;
  final VoidCallback onSignOut;

  const _AccountActions({
    required this.user,
    required this.onEditProfile,
    required this.onDeleteAccount,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.edit_outlined,
            label: 'Chỉnh sửa thông tin cá nhân',
            onTap: onEditProfile,
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.06)),
          _ActionRow(
            icon: Icons.delete_outline_rounded,
            label: 'Xóa tài khoản',
            color: const Color(0xFFEF4444),
            onTap: onDeleteAccount,
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.06)),
          _ActionRow(
            icon: Icons.logout_rounded,
            label: 'Đăng xuất',
            color: SNJ.sakura,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: effectiveColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: SNJ.textSecondary),
        prefixIcon: Icon(icon, color: SNJ.sakura),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SNJ.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SNJ.sakura),
        ),
      ),
    );
  }
}

class _ReadOnlyProfileInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyProfileInfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SNJ.border, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, color: SNJ.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: SNJ.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            color: SNJ.textMuted,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final String photoUrl;
  final String? fileName;
  final bool isUploading;
  final String displayName;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const _AvatarPicker({
    required this.photoUrl,
    required this.fileName,
    required this.isUploading,
    required this.displayName,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SNJ.border, width: 0.8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 58,
              height: 58,
              child: _Avatar(
                photoUrl: hasPhoto ? photoUrl : null,
                displayName:
                    displayName.trim().isEmpty ? 'Learner' : displayName.trim(),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName ??
                      (hasPhoto ? 'Ảnh đại diện hiện tại' : 'Chưa chọn ảnh'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'JPG, PNG, hoặc WebP',
                  style: TextStyle(
                    color: SNJ.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isUploading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: SNJ.sakura),
            )
          else ...[
            IconButton(
              tooltip: 'Chọn ảnh',
              onPressed: onPick,
              icon: const Icon(Icons.photo_library_outlined, color: SNJ.sakura),
            ),
            if (hasPhoto)
              IconButton(
                tooltip: 'Xóa ảnh',
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
          ],
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}