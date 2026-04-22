import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/features/home/models/user_model.dart';
import 'package:intl/intl.dart';

class HomeHeader extends StatelessWidget {
  final UserModel user;

  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.toriiRed.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo/Title
              const Text(
                'TokyoNihongo',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.toriiRed,
                  letterSpacing: -0.5,
                ),
              ),
              // Actions
              Row(
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: AppColors.slate700, size: 28),
                      Container(
                        margin: const EdgeInsets.only(top: 2, right: 3),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.toriiRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await AuthService().signOut();
                        // AuthGate will redirect to LoginScreen automatically
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(children: [
                          Icon(Icons.person_outline_rounded, color: AppColors.slate600, size: 20),
                          SizedBox(width: 10),
                          Text('Hồ sơ', style: TextStyle(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(children: [
                          Icon(Icons.logout_rounded, color: AppColors.toriiRed, size: 20),
                          SizedBox(width: 10),
                          Text('Đăng xuất', style: TextStyle(color: AppColors.toriiRed, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.toriiRed.withValues(alpha: 0.3), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(user.avatarUrl),
                        backgroundColor: AppColors.slate200,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          // User Stats
          Row(
            children: [
              Text(
                'Xin chào, ${user.name}!',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: AppColors.toriiRed, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${user.streakDays}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700),
                    ),
                    const SizedBox(width: 12),
                    const Text('¥', style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      NumberFormat('#,###').format(user.balanceYen),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
