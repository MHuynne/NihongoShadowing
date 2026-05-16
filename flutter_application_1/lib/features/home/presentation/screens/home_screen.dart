import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/home/models/user_model.dart';
import 'package:flutter_application_1/features/home/presentation/components/home_header.dart';
import 'package:flutter_application_1/features/home/presentation/components/mountain_progress_widget.dart';
import 'package:flutter_application_1/features/home/presentation/components/quick_access_grid.dart';
import 'package:flutter_application_1/features/roadmap/services/progress_service.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/config/api_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _completedLessons = 0;
  int _totalLessons = 25;
  String _levelLabel = 'N5';
  
  // Roadmap specific progress
  int _flashcardDone = 0;
  int _shadowingDone = 0;
  
  bool _loadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      // Get total lessons count to be accurate
      int totalLessonsCount = 25;
      try {
        String base = ApiConfig.baseUrl;
        final res = await http.get(Uri.parse('$base/lessons/?limit=200'));
        if (res.statusCode == 200) {
          final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
          if (data.isNotEmpty) {
            totalLessonsCount = data.length;
          }
        }
      } catch (_) {}

      final all = await ProgressService.getAllProgress();
      final completed = all.where((p) => p['lesson_completed'] == true).length;
      final flashcard = all.where((p) => p['flashcard_done'] == true).length;
      final shadowing = all.where((p) => p['shadowing_passed'] == true).length;

      String level = 'N5';
      if (completed >= 25) level = 'N4';
      if (completed >= 50) level = 'N3';
      if (completed >= 75) level = 'N2';

      if (mounted) {
        setState(() {
          _completedLessons = completed;
          _totalLessons = totalLessonsCount;
          _levelLabel = level;
          _flashcardDone = flashcard;
          _shadowingDone = shadowing;
          _loadingProgress = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dummyUser = UserModel(
      name: 'Minh Anh',
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
      streakDays: 12,
      balanceYen: 2450,
      activeDates: [
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
        today.subtract(const Duration(days: 4)),
        today.subtract(const Duration(days: 5)),
        today.subtract(const Duration(days: 6)),
        today.subtract(const Duration(days: 7)),
        today.subtract(const Duration(days: 8)),
        today.subtract(const Duration(days: 9)),
        today.subtract(const Duration(days: 10)),
        today.subtract(const Duration(days: 11)),
        today.subtract(const Duration(days: 12)),
        today.subtract(const Duration(days: 13)),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Light background like image
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HomeHeader(user: dummyUser),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFFF4D6D),
                onRefresh: _loadProgress,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Mountain Progress
                      _loadingProgress
                          ? const SizedBox(
                              height: 180,
                              child: Center(
                                child: CircularProgressIndicator(color: Color(0xFFFF4D6D)),
                              ),
                            )
                          : MountainProgressWidget(
                              completedLessons: _completedLessons,
                              totalLessons: _totalLessons,
                              levelLabel: _levelLabel,
                              animate: true,
                              onTap: () {
                                MainScreen.switchTab(context, 1);
                              },
                            ),

                      const SizedBox(height: 24),
                      const QuickAccessGrid(),

                      const SizedBox(height: 24),
                      _buildRoadmapProgressCard(),

                      const SizedBox(height: 24),
                      _buildDailyGoalCard(),


                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapProgressCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFFFF4D6D), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Tiến độ lộ trình',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF4D6D),
                    ),
                  ),
                ],
              ),
              const Text(
                'Tổng quan',
                style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar('Từ vựng (Flashcard)', _flashcardDone, _totalLessons),
          const SizedBox(height: 16),
          _buildProgressBar('Luyện đọc (Shadowing)', _shadowingDone, _totalLessons),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFE2E8F0), thickness: 1, height: 1),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFFFEBF0), shape: BoxShape.circle),
                child: const Text('N5', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF4D6D))),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                child: const Text('N4', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _completedLessons > 0 
                    ? '"Bạn đã hoàn thành ${_completedLessons} bài học. Tiếp tục phát huy nhé!"'
                    : '"Hãy bắt đầu bài học đầu tiên để chinh phục đỉnh núi!"',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProgressBar(String title, int current, int total) {
    final double pct = total > 0 ? current / total : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
            RichText(
              text: TextSpan(
                text: '$current',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFFF4D6D)),
                children: [
                  TextSpan(text: ' / $total bài', style: const TextStyle(color: Colors.black38)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4D6D)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFFF4D6D), size: 24),
              ),
              const Text('ĐANG HỌC', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF4D6D), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('MỤC TIÊU NGÀY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black38)),
          const Text('Hoàn thành 1 bài học', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => MainScreen.switchTab(context, 1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'HỌC NGAY',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
            ),
          ),
        ],
      ),
    );
  }



  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8)),
      ],
    );
  }
}


