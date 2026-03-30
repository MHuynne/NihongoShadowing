import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.itemBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Trang chủ',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.map_outlined,
                label: 'Lộ trình',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.graphic_eq,
                label: 'Shadowing',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Kingo Chat',
                index: 3,
                badgeValue: '1',
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Tài khoản',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    String? badgeValue,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.progressTeal : AppColors.slate500;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badgeValue != null)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.buttonYellow,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeValue,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
