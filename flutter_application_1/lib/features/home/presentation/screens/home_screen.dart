import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/home/models/user_model.dart';
import 'package:flutter_application_1/features/home/presentation/components/home_header.dart';
import 'package:flutter_application_1/features/home/presentation/components/mountain_progress_widget.dart';
import 'package:flutter_application_1/features/home/presentation/components/quick_access_grid.dart';
import 'package:flutter_application_1/features/roadmap/services/progress_service.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

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
        String base = 'http://localhost:8000';
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          base = 'http://10.0.2.2:8000';
        }
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
      backgroundColor: const Color(0xFFF4F6F9), // Light background like image
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HomeHeader(user: dummyUser),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFFF5238),
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
                                child: CircularProgressIndicator(color: Color(0xFFFF5238)),
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

                      const SizedBox(height: 24),
                      _buildConsistencyCard(dummyUser),
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
                  const Icon(Icons.menu_book_rounded, color: Color(0xFFFF5238), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Tiến độ lộ trình',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF5238),
                    ),
                  ),
                ],
              ),
              const Text(
                'Overall Progress',
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
                decoration: const BoxDecoration(color: Color(0xFFFFE4E1), shape: BoxShape.circle),
                child: const Text('N5', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5238))),
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
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFFF5238)),
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
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5238)),
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
                child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFFF5238), size: 24),
              ),
              const Text('IN PROGRESS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF5238), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('DAILY GOAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black38)),
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

  Widget _buildConsistencyCard(UserModel user) {
    int streakDays = user.streakDays;
    int nextMilestone = ((streakDays ~/ 14) + 1) * 14;

    // Lấy mốc ngày hôm nay (loại bỏ giờ/phút/giây)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Sinh ra danh sách 14 ngày (từ 13 ngày trước -> hôm nay)
    List<DateTime> last14Days = List.generate(14, (i) => today.subtract(Duration(days: 13 - i)));
    
    // Tạo Set các ngày user đã học để tra cứu nhanh O(1)
    final activeSet = user.activeDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();

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
              const Text('CONSISTENCY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black45)),
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Color(0xFFFFB300), size: 14),
                  const SizedBox(width: 4),
                  Text('${streakDays}d', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1E293B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Top row (days 13 days ago -> 7 days ago)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) => _buildStreakSquare(last14Days[i], activeSet, today)),
          ),
          const SizedBox(height: 16),
          // Bottom row (days 6 days ago -> today)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) => _buildStreakSquare(last14Days[i + 7], activeSet, today)),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'NEXT MILESTONE: $nextMilestone DAYS',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black38),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStreakSquare(DateTime date, Set<DateTime> activeSet, DateTime today) {
    bool isActive = activeSet.contains(date);
    bool isToday = date == today;

    Color color;
    BoxBorder? border;

    if (isActive) {
      // Đã điểm danh (Học)
      color = const Color(0xFFFF5238);
    } else if (isToday) {
      // Hôm nay chưa học (Nhưng có thể học)
      color = Colors.white;
      border = Border.all(color: const Color(0xFFE2E8F0));
    } else {
      // Quá khứ bỏ lỡ
      color = const Color(0xFFFFEBEE); // Màu hồng nhạt / xám
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        border: border,
        borderRadius: BorderRadius.circular(8),
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


