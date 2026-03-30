import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/home/models/user_model.dart';
import 'package:intl/intl.dart';

class HomeHeader extends StatelessWidget {
  final UserModel user;

  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(user.avatarUrl),
                backgroundColor: AppColors.slate200,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chào buổi sáng,',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.slate500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${user.name}!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('🌸', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lightTealGreen.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${user.streakDays}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(width: 8),
                const Text('¥', style: TextStyle(color: AppColors.progressTeal, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text(
                  NumberFormat('#,###').format(user.balanceYen),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.progressTeal),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
