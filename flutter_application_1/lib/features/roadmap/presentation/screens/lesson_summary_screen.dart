import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/home/presentation/components/mountain_progress_widget.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';
import 'package:flutter_application_1/features/roadmap/services/progress_service.dart';

class LessonSummaryScreen extends StatefulWidget {
  final int testErrors;
  final int shadowingErrors;
  final int lessonId;
  final double shadowingScore;

  const LessonSummaryScreen({
    super.key,
    required this.testErrors,
    required this.shadowingErrors,
    required this.lessonId,
    this.shadowingScore = 0,
  });

  @override
  State<LessonSummaryScreen> createState() => _LessonSummaryScreenState();
}

class _LessonSummaryScreenState extends State<LessonSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Mountain progress state
  int _completedLessons = 0;
  int _totalLessons     = 25; // default N5
  String _levelLabel    = 'N5';
  bool _loadingProgress = true;

  // XP gained
  int _xpGained = 0;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnim = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
    _fadeAnim = CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn));
    _mainCtrl.forward();

    // Tính XP
    final totalErrors = widget.testErrors + widget.shadowingErrors;
    _xpGained = _calcXp(totalErrors, widget.shadowingScore);

    _loadProgress();
  }

  int _calcXp(int errors, double shadowScore) {
    int base = 100;
    base -= (errors * 5).clamp(0, 40);
    base += ((shadowScore - 80) / 20 * 30).round().clamp(0, 30);
    return base.clamp(30, 150);
  }

  Future<void> _loadProgress() async {
    try {
      final all = await ProgressService.getAllProgress();
      final completed = all.where((p) => p['lesson_completed'] == true).length;
      final total     = all.isNotEmpty ? all.length : 25;

      // Xác định level từ lessonId
      String level = 'N5';
      if (widget.lessonId >= 26) level = 'N4';
      if (widget.lessonId >= 51) level = 'N3';
      if (widget.lessonId >= 76) level = 'N2';

      if (mounted) {
        setState(() {
          _completedLessons = completed;
          _totalLessons     = total;
          _levelLabel       = level;
          _loadingProgress  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProgress = false);
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalErrors = widget.testErrors + widget.shadowingErrors;
    final bool isPerfect  = totalErrors == 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF5E8E9),
              Color(0xFFEEDFE1),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.toriiRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flag_rounded,
                                color: AppColors.toriiRed, size: 14),
                            const SizedBox(width: 6),
                            const Text(
                              'TỔNG KẾT BÀI HỌC',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppColors.toriiRed,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Trophy icon + XP ─────────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isPerfect
                                      ? AppColors.goldAccent
                                      : AppColors.toriiRed)
                                  .withValues(alpha: 0.25),
                              blurRadius: 40,
                              spreadRadius: 10,
                            )
                          ],
                        ),
                        child: Icon(
                          isPerfect
                              ? Icons.emoji_events_rounded
                              : Icons.star_rounded,
                          size: 80,
                          color: isPerfect
                              ? AppColors.goldAccent
                              : AppColors.toriiRed,
                        ),
                      ),
                      // XP badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.toriiRed,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            '+$_xpGained XP',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Title ────────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        isPerfect ? 'Hoàn Hảo! 🎌' : 'Rất Tốt! 🌸',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isPerfect
                              ? AppColors.goldAccent
                              : AppColors.toriiRed,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          isPerfect
                              ? 'Xuất sắc! Không mắc lỗi nào cả.'
                              : 'Cố lên một chút nữa để đạt điểm tối đa nhé.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.slate500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Stats row ────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.edit_note_rounded,
                            label: 'Lỗi Test',
                            value: widget.testErrors.toString(),
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.record_voice_over_rounded,
                            label: 'Shadowing',
                            value:
                                '${widget.shadowingScore.toStringAsFixed(0)}%',
                            color: AppColors.toriiRed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.bolt_rounded,
                            label: 'XP nhận',
                            value: '+$_xpGained',
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Mountain Progress ─────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 24, bottom: 12),
                        child: Row(
                          children: const [
                            Text(
                              '⛰️  Tiến độ leo núi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _loadingProgress
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(
                                  color: AppColors.toriiRed,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : MountainProgressWidget(
                              completedLessons: _completedLessons,
                              totalLessons: _totalLessons,
                              levelLabel: _levelLabel,
                              animate: true,
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── CTA Button ────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        // Force refresh roadmap TRƯỚC khi pop
                        MainScreen.refreshRoadmap(context);
                        Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.toriiRed,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        elevation: 6,
                        shadowColor:
                            AppColors.toriiRed.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'TIẾP TỤC LỘ TRÌNH',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
