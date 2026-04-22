import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/home/models/leaderboard_user.dart';
import 'package:intl/intl.dart';

class LeaderboardList extends StatelessWidget {
  final List<LeaderboardUser> users;

  const LeaderboardList({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart_rounded, color: AppColors.toriiRed),
              SizedBox(width: 8),
              Text(
                'Bảng xếp hạng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.toriiRed.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              separatorBuilder: (context, index) => const Divider(
                color: AppColors.slate100,
                height: 1,
                indent: 64, // roughly align with name text
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final user = users[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${user.rank}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: _getRankColor(user.rank),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(user.avatarUrl),
                        backgroundColor: AppColors.slate200,
                      ),
                      const SizedBox(width: 16),
                      // Name & XP
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate800,
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,###').format(user.pointsXP)} XP',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badges
                      if (user.rank == 1)
                        const Icon(Icons.workspace_premium, color: AppColors.goldAccent, size: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.goldAccent; // Gold/Yellow
      case 2:
        return AppColors.slate400; // Silver/Grey
      case 3:
        return Colors.brown.shade400; // Bronze
      default:
        return AppColors.slate300;
    }
  }
}
