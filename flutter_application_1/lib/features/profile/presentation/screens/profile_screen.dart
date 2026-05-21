import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/core/config/api_config.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class _ProfileSummary {
  final int totalStarted;
  final int totalCompleted;
  final int totalXp;
  final double avgTestScore;
  final double avgShadowingScore;
  final List<_LessonResult> lessons;

  const _ProfileSummary({
    required this.totalStarted,
    required this.totalCompleted,
    required this.totalXp,
    required this.avgTestScore,
    required this.avgShadowingScore,
    required this.lessons,
  });

  factory _ProfileSummary.fromJson(Map<String, dynamic> j) => _ProfileSummary(
        totalStarted: j['total_lessons_started'] ?? 0,
        totalCompleted: j['total_lessons_completed'] ?? 0,
        totalXp: j['total_xp'] ?? 0,
        avgTestScore: (j['avg_test_score'] as num?)?.toDouble() ?? 0.0,
        avgShadowingScore: (j['avg_shadowing_score'] as num?)?.toDouble() ?? 0.0,
        lessons: (j['lessons'] as List<dynamic>? ?? [])
            .map((e) => _LessonResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class _LessonResult {
  final int lessonId;
  final String level;
  final String chapterName;
  final bool flashcardDone;
  final double? testScore;
  final bool testPassed;
  final double? shadowingScore;
  final bool shadowingPassed;
  final bool lessonCompleted;

  const _LessonResult({
    required this.lessonId,
    required this.level,
    required this.chapterName,
    required this.flashcardDone,
    this.testScore,
    required this.testPassed,
    this.shadowingScore,
    required this.shadowingPassed,
    required this.lessonCompleted,
  });

  factory _LessonResult.fromJson(Map<String, dynamic> j) => _LessonResult(
        lessonId: j['lesson_id'] ?? 0,
        level: j['level'] ?? 'N5',
        chapterName: j['chapter_name'] ?? '',
        flashcardDone: j['flashcard_done'] ?? false,
        testScore: (j['test_score'] as num?)?.toDouble(),
        testPassed: j['test_passed'] ?? false,
        shadowingScore: (j['shadowing_score'] as num?)?.toDouble(),
        shadowingPassed: j['shadowing_passed'] ?? false,
        lessonCompleted: j['lesson_completed'] ?? false,
      );
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileSummary? _summary;
  bool _isLoading = true;
  String? _error;

  static String get _base => ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final res = await http.get(
        Uri.parse('$_base/progress/summary'),
        headers: {
          'Content-Type': 'application/json',
          if (uid != null) 'X-Firebase-UID': uid,
        },
      );
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        setState(() { _summary = _ProfileSummary.fromJson(data); _isLoading = false; });
      } else {
        setState(() { _error = 'Không tải được dữ liệu (${res.statusCode})'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Lỗi kết nối: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'Học viên';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground(context),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.toriiRed,
          onRefresh: _fetchSummary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            child: Column(
              children: [
                _ProfileHeader(displayName: displayName, email: email),
                const SizedBox(height: 22),
                // XP card — real data
                _XpCard(xp: _summary?.totalXp ?? 0, isLoading: _isLoading),
                const SizedBox(height: 14),
                // Stats grid — real data
                _StatsGrid(summary: _summary, isLoading: _isLoading),
                const SizedBox(height: 18),
                // Learning history
                _LearningHistoryCard(
                  summary: _summary,
                  isLoading: _isLoading,
                  error: _error,
                ),
                const SizedBox(height: 18),
                _AccountActions(onSignOut: () => _confirmSignOut(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ quay lại màn hình đăng nhập.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.toriiRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) await AuthService().signOut();
  }
}

// ─── Profile Header (unchanged visuals) ──────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  const _ProfileHeader({required this.displayName, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 92, height: 92,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppColors.shadow(context, opacity: 0.08), blurRadius: 24, offset: const Offset(0, 12))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset('assets/images/fuji_bg.png', fit: BoxFit.cover),
                  DecoratedBox(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.78))),
                  const Center(child: Text('東京', style: TextStyle(color: AppColors.toriiRed, fontSize: 24, fontWeight: FontWeight.w900))),
                ]),
              ),
            ),
            Positioned(
              bottom: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: AppColors.toriiRed, borderRadius: BorderRadius.circular(999),
                  boxShadow: [BoxShadow(color: AppColors.toriiRed.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]),
                child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.primaryText(context), fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.school_outlined, color: AppColors.toriiRed, size: 14),
          const SizedBox(width: 5),
          const Text('JLPT Learner', style: TextStyle(color: AppColors.toriiRed, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Text(email, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.tertiaryText(context), fontSize: 12)),
      ],
    );
  }
}

// ─── XP Card (dynamic) ───────────────────────────────────────────────────────

class _XpCard extends StatelessWidget {
  final int xp;
  final bool isLoading;
  const _XpCard({required this.xp, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface(context), borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: AppColors.shadow(context, opacity: 0.06), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Row(children: [
          Container(width: 4, height: 96, color: AppColors.toriiRed),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TOTAL EXPERIENCE', style: TextStyle(color: AppColors.tertiaryText(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.9)),
                  const SizedBox(height: 7),
                  isLoading
                      ? Container(height: 28, width: 100, decoration: BoxDecoration(color: AppColors.border(context), borderRadius: BorderRadius.circular(8)))
                      : Text('${xp.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} XP',
                          style: TextStyle(color: AppColors.primaryText(context), fontSize: 24, fontWeight: FontWeight.w900)),
                ])),
                Container(width: 58, height: 58,
                  decoration: BoxDecoration(color: AppColors.lightPinkBackground, shape: BoxShape.circle),
                  child: const Icon(Icons.military_tech_rounded, color: AppColors.toriiRed, size: 28)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Stats Grid (dynamic) ────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final _ProfileSummary? summary;
  final bool isLoading;
  const _StatsGrid({required this.summary, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final completedVal = isLoading ? '–' : '${summary?.totalCompleted ?? 0}';
    final startedVal   = isLoading ? '–' : '${summary?.totalStarted ?? 0}';
    final testVal      = isLoading ? '–' : '${summary?.avgTestScore.toStringAsFixed(0) ?? 0}%';
    final shadowVal    = isLoading ? '–' : '${summary?.avgShadowingScore.toStringAsFixed(0) ?? 0}%';

    return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
      childAspectRatio: 1.45, physics: const NeverScrollableScrollPhysics(), shrinkWrap: true,
      children: [
        _StatTile(icon: Icons.check_circle_outline_rounded, label: 'BÀI HOÀN THÀNH', value: completedVal, accent: AppColors.toriiRed),
        _StatTile(icon: Icons.menu_book_outlined, label: 'BÀI ĐÃ HỌC', value: startedVal, accent: AppColors.matcha),
        _StatTile(icon: Icons.quiz_outlined, label: 'ĐTB KIỂM TRA', value: testVal, accent: AppColors.goldAccent),
        _StatTile(icon: Icons.record_voice_over_outlined, label: 'ĐTB SHADOWING', value: shadowVal, accent: AppColors.progressTeal),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  const _StatTile({required this.icon, required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context), borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [BoxShadow(color: AppColors.shadow(context, opacity: 0.04), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: accent, size: 21),
        const SizedBox(height: 10),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.tertiaryText(context), fontSize: 9, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: AppColors.primaryText(context), fontSize: 19, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

// ─── Learning History Card (new) ─────────────────────────────────────────────

class _LearningHistoryCard extends StatelessWidget {
  final _ProfileSummary? summary;
  final bool isLoading;
  final String? error;
  const _LearningHistoryCard({required this.summary, required this.isLoading, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context), borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [BoxShadow(color: AppColors.shadow(context, opacity: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.lightPinkBackground, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.history_edu_rounded, color: AppColors.toriiRed, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Lịch Sử Học Tập', style: TextStyle(color: AppColors.primaryText(context), fontSize: 18, fontWeight: FontWeight.w900)),
            Text('Kết quả từng bài trong lộ trình', style: TextStyle(color: AppColors.tertiaryText(context), fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
        ]),
        const SizedBox(height: 16),
        Divider(height: 1, color: AppColors.divider(context)),
        const SizedBox(height: 12),

        // Content
        if (isLoading)
          _buildSkeletons()
        else if (error != null)
          _buildError(error!)
        else if (summary == null || summary!.lessons.isEmpty)
          _buildEmpty(context)
        else
          ...summary!.lessons.map((l) => _LessonResultTile(lesson: l)).toList(),
      ]),
    );
  }

  Widget _buildSkeletons() {
    return Column(children: List.generate(3, (_) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(height: 72, decoration: BoxDecoration(
        color: const Color(0xFFF5E8E9), borderRadius: BorderRadius.circular(16))),
    )));
  }

  Widget _buildError(String msg) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Icon(Icons.wifi_off_rounded, color: AppColors.toriiRed, size: 36),
        const SizedBox(height: 8),
        Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.toriiRed, fontSize: 13)),
      ]),
    ));
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Text('🌸', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 8),
        Text('Chưa có bài học nào được hoàn thành.\nHãy bắt đầu lộ trình học tập nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.tertiaryText(context), fontSize: 13)),
      ]),
    ));
  }
}

class _LessonResultTile extends StatelessWidget {
  final _LessonResult lesson;
  const _LessonResultTile({required this.lesson});

  Color get _levelColor {
    switch (lesson.level) {
      case 'N5': return const Color(0xFF4CAF50);
      case 'N4': return const Color(0xFF2196F3);
      case 'N3': return const Color(0xFFFF9800);
      case 'N2': return const Color(0xFFE91E63);
      case 'N1': return const Color(0xFF9C27B0);
      default: return AppColors.toriiRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = lesson.lessonCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF0FFF4) : AppColors.scaffoldBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCompleted ? const Color(0xFFA8D5B5) : AppColors.border(context)),
      ),
      child: Row(children: [
        // Level badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: _levelColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(lesson.level, style: TextStyle(color: _levelColor, fontSize: 10, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 10),
        // Name
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lesson.chapterName.isNotEmpty ? lesson.chapterName : 'Bài ${lesson.lessonId}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.primaryText(context), fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(children: [
            _MiniChip(icon: Icons.style_outlined, label: lesson.flashcardDone ? 'Flashcard ✓' : 'Flashcard –', done: lesson.flashcardDone),
            const SizedBox(width: 6),
            _MiniChip(icon: Icons.quiz_outlined, label: lesson.testScore != null ? 'Test: ${lesson.testScore!.toStringAsFixed(0)}%' : 'Test –', done: lesson.testPassed),
            const SizedBox(width: 6),
            _MiniChip(icon: Icons.mic_outlined, label: lesson.shadowingScore != null ? 'Shadow: ${lesson.shadowingScore!.toStringAsFixed(0)}%' : 'Shadow –', done: lesson.shadowingPassed),
          ]),
        ])),
        const SizedBox(width: 8),
        // Status icon
        Icon(
          isCompleted ? Icons.verified_rounded : Icons.radio_button_unchecked_rounded,
          color: isCompleted ? const Color(0xFF4CAF50) : AppColors.tertiaryText(context),
          size: 22,
        ),
      ]),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  const _MiniChip({required this.icon, required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFE8F5E9) : AppColors.surface(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: done ? const Color(0xFF81C784) : AppColors.border(context)),
      ),
      child: Text(label, style: TextStyle(
          color: done ? const Color(0xFF388E3C) : AppColors.tertiaryText(context),
          fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Account Actions ─────────────────────────────────────────────────────────

class _AccountActions extends StatelessWidget {
  final VoidCallback onSignOut;
  const _AccountActions({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface(context), borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(children: [
        _ActionRow(icon: Icons.edit_outlined, label: 'Chỉnh sửa hồ sơ', onTap: () {}),
        Divider(height: 1, color: AppColors.divider(context)),
        _ActionRow(icon: Icons.logout_rounded, label: 'Đăng xuất', color: AppColors.toriiRed, onTap: onSignOut),
      ]),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryText(context);
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w800))),
          Icon(Icons.chevron_right_rounded, color: AppColors.tertiaryText(context)),
        ]),
      ),
    );
  }
}
