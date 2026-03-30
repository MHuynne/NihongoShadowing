import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/home/models/leaderboard_user.dart';
import 'package:flutter_application_1/features/home/models/srs_progress_model.dart';
import 'package:flutter_application_1/features/home/models/user_model.dart';
import 'package:flutter_application_1/features/home/presentation/components/home_header.dart';
import 'package:flutter_application_1/features/home/presentation/components/leaderboard_list.dart';
import 'package:flutter_application_1/features/home/presentation/components/quick_access_grid.dart';
import 'package:flutter_application_1/features/home/presentation/components/srs_progress_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data
    final dummyUser = UserModel(
      name: 'Minh Anh',
      avatarUrl: 'https://i.pravatar.cc/150?img=47', // Placeholder avatar
      streakDays: 12,
      balanceYen: 2450,
    );

    final dummyProgress = SrsProgressModel(
      completedWords: 15,
      totalWords: 30,
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
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(user: dummyUser),
              const SizedBox(height: 8),
              SrsProgressCard(progress: dummyProgress),
              const SizedBox(height: 24),
              const QuickAccessGrid(),
              const SizedBox(height: 24),
              LeaderboardList(users: dummyLeaderboard),
              const SizedBox(height: 32), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
