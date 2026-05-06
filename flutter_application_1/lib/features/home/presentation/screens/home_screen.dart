import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/home/models/leaderboard_user.dart';
import 'package:flutter_application_1/features/home/models/user_model.dart';
import 'package:flutter_application_1/features/home/presentation/components/home_header.dart';
import 'package:flutter_application_1/features/home/presentation/components/leaderboard_list.dart';
import 'package:flutter_application_1/features/home/presentation/components/mountain_progress_widget.dart';
import 'package:flutter_application_1/features/home/presentation/components/quick_access_grid.dart';
import 'package:flutter_application_1/features/roadmap/services/progress_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mountain progress data
  int _completedLessons = 0;
  int _totalLessons     = 25;
  String _levelLabel    = 'N5';
  bool _loadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final all = await ProgressService.getAllProgress();
      final completed = all.where((p) => p['lesson_completed'] == true).length;
      final total     = all.isNotEmpty ? all.length : 25;

      // Xác định level hiện tại theo số bài đã hoàn thành
      String level = 'N5';
      if (completed >= 25) level = 'N4';
      if (completed >= 50) level = 'N3';
      if (completed >= 75) level = 'N2';

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
  Widget build(BuildContext context) {
    final dummyUser = UserModel(
      name: 'Minh Anh',
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
      streakDays: 12,
      balanceYen: 2450,
    );

    final dummyLeaderboard = [
      LeaderboardUser(
        rank: 1,
        name: 'Hương Nguyễn',
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
        pointsXP: 8420,
      ),
      LeaderboardUser(
        rank: 2,
        name: 'Quốc Trung',
        avatarUrl: 'https://i.pravatar.cc/150?img=11',
        pointsXP: 7910,
      ),
      LeaderboardUser(
        rank: 3,
        name: 'Duy Mạnh',
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        pointsXP: 7200,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color(0xFFF3E5E7),
                    Color(0xFFEBDDE0),
                    Colors.white,
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeHeader(user: dummyUser),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.toriiRed,
                    onRefresh: _loadProgress,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // ── Section label ─────────────────────────
                          const Padding(
                            padding: EdgeInsets.only(left: 24, bottom: 12),
                            child: Text(
                              '⛰️  Hành trình leo núi Phú Sĩ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate800,
                              ),
                            ),
                          ),

                          // ── Mountain Progress ────────────────────
                          _loadingProgress
                              ? _buildMountainSkeleton()
                              : MountainProgressWidget(
                                  completedLessons: _completedLessons,
                                  totalLessons: _totalLessons,
                                  levelLabel: _levelLabel,
                                  animate: true,
                                  onTap: () {
                                    // TODO: navigate to roadmap
                                  },
                                ),

                          const SizedBox(height: 24),

                          // ── Quick Access Grid ────────────────────
                          const QuickAccessGrid(),

                          const SizedBox(height: 24),

                          // ── Leaderboard ─────────────────────────
                          LeaderboardList(users: dummyLeaderboard),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMountainSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A3E),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.toriiRed,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
