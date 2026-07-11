import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:flutter_application_1/core/config/api_config.dart';
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


  int _completedLessons = 0;
  int _totalLessons     = 25;
  String _levelLabel    = 'N5';
  bool _loadingProgress = true;


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
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/lessons/?limit=200')),
        ProgressService.getAllProgress(),
      ]);

      final lessonsResp = results[0] as http.Response;
      final progressList = results[1] as List<Map<String, dynamic>>;

      if (lessonsResp.statusCode == 200) {
        final List<dynamic> allLessons = json.decode(utf8.decode(lessonsResp.bodyBytes));


        String currentLevel = 'N5';
        final currentLesson = allLessons.firstWhere(
          (l) => l['id'] == widget.lessonId,
          orElse: () => null
        );
        if (currentLesson != null) {
          currentLevel = currentLesson['level'] ?? 'N5';
        } else {

          final id = widget.lessonId;
          if (id >= 1101 && id <= 1120) currentLevel = 'N1';
          else if (id >= 2201 && id <= 2220) currentLevel = 'N2';
          else if (id >= 3301 && id <= 3320) currentLevel = 'N3';
          else if (id >= 4201 && id <= 4225) currentLevel = 'N4';
          else if (id >= 5101 && id <= 5125) currentLevel = 'N5';
          else if (id >= 6101 && id <= 6112) currentLevel = 'N5';
        }


        final levelLessons = allLessons.where((l) => l['level'] == currentLevel).toList();
        final total = levelLessons.length;


        final levelLessonIds = levelLessons.map((l) => l['id'] as int).toSet();
        final completed = progressList.where((p) {
          final lid = p['lesson_id'] as int;
          return levelLessonIds.contains(lid) && p['lesson_completed'] == true;
        }).length;

        if (mounted) {
          setState(() {
            _completedLessons = completed;
            _totalLessons     = total > 0 ? total : 12;
            _levelLabel       = currentLevel;
            _loadingProgress  = false;
          });
        }
      } else {
        throw Exception('Lessons API failed');
      }
    } catch (_) {
      if (mounted) {

        String level = 'N5';
        final id = widget.lessonId;
        if (id >= 1101 && id <= 1120) level = 'N1';
        else if (id >= 2201 && id <= 2220) level = 'N2';
        else if (id >= 3301 && id <= 3320) level = 'N3';
        else if (id >= 4201 && id <= 4225) level = 'N4';
        else if (id >= 5101 && id <= 5125) level = 'N5';
        else if (id >= 6101 && id <= 6112) level = 'N5';

        setState(() {
          _completedLessons = 1;
          _totalLessons     = 12;
          _levelLabel       = level;
          _loadingProgress  = false;
        });
      }
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


                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: ElevatedButton(
                      onPressed: () {

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