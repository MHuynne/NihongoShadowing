import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingFooter extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;

  const OnboardingFooter({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(30.0),
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Column(
        children: [
          // Pagination Dots
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: List.generate(totalSteps, (index) {
          //     final isCurrent = index + 1 == currentStep;
          //     return Container(
          //       margin: const EdgeInsets.symmetric(horizontal: 4),
          //       height: 6,
          //       width: isCurrent ? 24 : 6,
          //       decoration: BoxDecoration(
          //         color: isCurrent
          //             ? AppColors.primary
          //             : (isDark ? AppColors.slate700 : AppColors.slate300),
          //         borderRadius: BorderRadius.circular(3),
          //       ),
          //     );s
          //   }),
          // ),
          const SizedBox(height: 32),
          // Primary Button
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.5),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'By continuing, you agree to our Terms of Service',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.slate600 : AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}
