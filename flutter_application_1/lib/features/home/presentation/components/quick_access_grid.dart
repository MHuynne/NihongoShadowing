import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.grid_view_rounded, color: AppColors.progressTeal),
              SizedBox(width: 8),
              Text(
                'Truy cập nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGridItem(
                  icon: Icons.map_outlined,
                  title: 'Lộ trình',
                  iconBgColor: AppColors.lightTealGreen,
                  iconColor: AppColors.progressTeal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGridItem(
                  icon: Icons.graphic_eq,
                  title: 'Shadowing',
                  iconBgColor: AppColors.lightBlueBackground,
                  iconColor: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGridItem(
                  icon: Icons.smart_toy_outlined,
                  title: 'Roleplay Chat',
                  iconBgColor: AppColors.lightPinkBackground,
                  iconColor: AppColors.sunRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGridItem(
                  icon: Icons.search_rounded,
                  title: 'Từ điển',
                  iconBgColor: AppColors.lightPurpleBackground,
                  iconColor: Colors.purpleAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String title,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.itemBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
