import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingTopBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingTopBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
      
            ),
          ),
          Text(
            'STEP $currentStep OF $totalSteps',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: isDark ? AppColors.slate100 : AppColors.slate900,
            ),
          ),
          const SizedBox(width: 40), // Spacer for centering
        ],
      ),
    );
  }
}
