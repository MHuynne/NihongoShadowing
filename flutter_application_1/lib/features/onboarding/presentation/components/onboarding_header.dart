import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingHeader extends StatelessWidget {
  final String titleStart;
  final String highlightWord;
  final String titleEnd;
  final String subtitle;

  const OnboardingHeader({
    super.key,
    required this.titleStart,
    required this.highlightWord,
    required this.titleEnd,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.slate100 : AppColors.slate900;
    final subtitleColor = isDark ? AppColors.slate400 : AppColors.slate600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
                color: textColor,
                fontFamily: 'Inter',
              ),
              children: [
                TextSpan(text: titleStart),
                TextSpan(
                  text: highlightWord,
                  style: const TextStyle(color: AppColors.primary),
                ),
                TextSpan(text: titleEnd),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
