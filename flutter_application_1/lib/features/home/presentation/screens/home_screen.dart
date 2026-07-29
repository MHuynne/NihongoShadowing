import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';
import 'package:flutter_application_1/features/home/models/user_model.dart';
import 'package:flutter_application_1/features/home/presentation/components/home_header.dart';
import 'package:flutter_application_1/features/home/presentation/components/mountain_progress_widget.dart';
import 'package:flutter_application_1/features/home/presentation/components/quick_access_grid.dart';
import 'package:flutter_application_1/features/roadmap/services/progress_service.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:flutter_application_1/core/services/user_prefs_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:async';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _completedLessons = 0;
  int _totalLessons     = 25;
  String _levelLabel    = 'N5';
  int _flashcardDone    = 0;
  int _shadowingDone    = 0;
  bool _loadingProgress = true;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _authSub?.cancel();
        _authSub = null;
        _loadProgress();
      } else {
        if (mounted) setState(() => _loadingProgress = false);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      List<dynamic> allLessons = [];
      try {
        final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/lessons/?limit=200'));
        if (res.statusCode == 200) {
          final data = json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
          if (data.isNotEmpty) allLessons = data;
        }
      } catch (_) {}

      final all = await ProgressService.getAllProgress();
      final totalCompleted = all.where((p) => p['lesson_completed'] == true).length;

      String level = 'N5';
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final saved = await UserPrefsService().getLevel(uid);
        if (saved != null && saved.isNotEmpty) {
          level = saved;
        } else {
          if (totalCompleted >= 25) level = 'N4';
          if (totalCompleted >= 50) level = 'N3';
          if (totalCompleted >= 75) level = 'N2';
        }
      }

      final levelLessons = allLessons.where((l) => l['level'] == level).toList();
      final levelTotal   = levelLessons.isNotEmpty ? levelLessons.length : 12;
      final levelIds     = levelLessons.map((l) => l['id'] as int).toSet();
      final levelDone    = all.where((p) => levelIds.contains(p['lesson_id'] as int) && p['lesson_completed'] == true).length;
      final flashDone    = all.where((p) => levelIds.contains(p['lesson_id'] as int) && p['flashcard_done'] == true).length;
      final shadowDone   = all.where((p) => levelIds.contains(p['lesson_id'] as int) && p['shadowing_passed'] == true).length;

      if (mounted) {
        setState(() {
          _completedLessons = levelDone;
          _totalLessons     = levelTotal;
          _levelLabel       = level;
          _flashcardDone    = flashDone;
          _shadowingDone    = shadowDone;
          _loadingProgress  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser  = FirebaseAuth.instance.currentUser;
    final today         = DateTime.now();
    final dummyUser = UserModel(
      name: firebaseUser?.displayName ?? 'Minh Anh',
      avatarUrl: firebaseUser?.photoURL ?? '',
      streakDays: 12,
      balanceYen: 2450,
      activeDates: List.generate(12, (i) => today.subtract(Duration(days: i + 1))),
    );

    return Scaffold(
      // Nền trong suốt để SakuraNightBackground hiển thị
      backgroundColor: Colors.transparent,
      body: SakuraNightBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HomeHeader(user: dummyUser),
              Expanded(
                child: RefreshIndicator(
                  color: SNJ.sakura,
                  backgroundColor: const Color(0xFF1E0F38),
                  onRefresh: _loadProgress,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 110),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ── Mountain Progress Card ──────────────────────────
                        _loadingProgress
                            ? SizedBox(
                                height: 180,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: SNJ.sakura,
                                    backgroundColor: SNJ.sakuraSoft,
                                  ),
                                ),
                              )
                            : MountainProgressWidget(
                                completedLessons: _completedLessons,
                                totalLessons:     _totalLessons,
                                levelLabel:       _levelLabel,
                                animate:          true,
                                onTap: () => MainScreen.switchTab(context, 1),
                              ),

                        const SizedBox(height: 22),

                        // ── Quick Access Grid ───────────────────────────────
                        const QuickAccessGrid(),

                        const SizedBox(height: 22),

                        // ── Roadmap Progress Card ───────────────────────────
                        _buildRoadmapProgressCard(),

                        const SizedBox(height: 20),

                        // ── Daily Goal Card ─────────────────────────────────
                        _buildDailyGoalCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Roadmap Progress Card ──────────────────────────────────────────────────
  Widget _buildRoadmapProgressCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        neonBorder: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: SNJ.sakuraSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: SNJ.sakura, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Tiến độ lộ trình',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: SNJ.sakura,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Tổng quan',
                  style: TextStyle(
                    fontSize: 11,
                    color: SNJ.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildProgressBar('Từ vựng (Flashcard)', _flashcardDone, _totalLessons,
                const Color(0xFF4F46E5)),
            const SizedBox(height: 14),
            _buildProgressBar('Luyện đọc (Shadowing)', _shadowingDone, _totalLessons,
                SNJ.sakura),
            const SizedBox(height: 16),
            Divider(color: SNJ.border, thickness: 0.8),
            const SizedBox(height: 10),
            Row(
              children: [
                _levelChip(_levelLabel, true),
                const SizedBox(width: 8),
                _levelChip(_nextLevel(_levelLabel), false),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _completedLessons > 0
                        ? '"Bạn đã hoàn thành $_completedLessons bài. Tiếp tục phát huy!"'
                        : '"Hãy bắt đầu bài học đầu tiên để chinh phục đỉnh núi!"',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: SNJ.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String title, int current, int total, Color color) {
    final double pct = total > 0 ? current / total : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: SNJ.textPrimary)),
            RichText(
              text: TextSpan(
                text: '$current',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color),
                children: [
                  TextSpan(
                    text: ' / $total bài',
                    style: TextStyle(color: SNJ.textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Track
            Container(
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Fill
            FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _levelChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? SNJ.sakuraSoft : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? SNJ.borderNeon : SNJ.border,
          width: active ? 1.2 : 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: active ? SNJ.sakura : SNJ.textMuted,
        ),
      ),
    );
  }

  String _nextLevel(String current) {
    const levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
    final idx = levels.indexOf(current);
    return idx >= 0 && idx < levels.length - 1 ? levels[idx + 1] : 'N1';
  }

  // ── Daily Goal Card ────────────────────────────────────────────────────────
  Widget _buildDailyGoalCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: SNJ.sakuraGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: SNJ.sakuraGlow, blurRadius: 12)],
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SNJ.sakuraSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SNJ.borderNeon, width: 1),
                  ),
                  child: const Text(
                    'ĐANG HỌC',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: SNJ.sakura,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'MỤC TIÊU NGÀY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: SNJ.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hoàn thành 1 bài học',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: SNJ.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => MainScreen.switchTab(context, 1),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: SNJ.sakuraGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: SNJ.sakura.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'HỌC NGAY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
