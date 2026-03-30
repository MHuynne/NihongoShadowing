import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/roadmap/models/roadmap_model.dart';

class LessonCard extends StatelessWidget {
  final LessonModel lesson;

  const LessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: _getBoxDecoration(lesson.status),
      child: Row(
        children: [
          // Icon Circle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(lesson.status),
              shape: BoxShape.circle,
            ),
            child: Icon(
              lesson.icon,
              color: _getIconColor(lesson.status),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lesson.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getTitleColor(lesson.status),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (lesson.status == LessonStatus.completed)
                      const Icon(Icons.check_circle, color: AppColors.progressTeal, size: 14),
                    if (lesson.status == LessonStatus.completed)
                      const SizedBox(width: 4),
                    Text(
                      lesson.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getSubtitleColor(lesson.status),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Trailing Icon
          _buildTrailingIcon(lesson.status),
        ],
      ),
    );
  }

  BoxDecoration _getBoxDecoration(LessonStatus status) {
    if (status == LessonStatus.completed) {
      return BoxDecoration(
        color: AppColors.itemBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (status == LessonStatus.inProgress) {
      return BoxDecoration(
        color: AppColors.itemBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.progressTeal, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.progressTeal.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else {
      // Locked
      return BoxDecoration(
        color: AppColors.slate50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200, width: 1, style: BorderStyle.solid), // Ideally dashed
      );
    }
  }

  Color _getIconBackgroundColor(LessonStatus status) {
    if (status == LessonStatus.completed) return AppColors.lightTealGreen;
    if (status == LessonStatus.inProgress) return AppColors.progressTeal;
    return AppColors.slate200;
  }

  Color _getIconColor(LessonStatus status) {
    if (status == LessonStatus.completed) return AppColors.progressTeal;
    if (status == LessonStatus.inProgress) return AppColors.itemBackground;
    return AppColors.slate400;
  }

  Color _getTitleColor(LessonStatus status) {
    if (status == LessonStatus.locked) return AppColors.slate400;
    return AppColors.textDark;
  }

  Color _getSubtitleColor(LessonStatus status) {
    if (status == LessonStatus.inProgress) return AppColors.progressTeal;
    if (status == LessonStatus.locked) return AppColors.slate400;
    return AppColors.slate500;
  }

  Widget _buildTrailingIcon(LessonStatus status) {
    if (status == LessonStatus.completed) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: AppColors.progressTeal,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: AppColors.itemBackground, size: 16),
      );
    } else if (status == LessonStatus.inProgress) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.lightTealGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.play_arrow_rounded, color: AppColors.progressTeal, size: 16),
      );
    } else {
      // Locked
      return const Icon(Icons.lock_rounded, color: AppColors.slate400, size: 20);
    }
  }
}
