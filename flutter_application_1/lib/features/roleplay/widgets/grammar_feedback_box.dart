import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GrammarFeedbackBox extends StatelessWidget {
  final String error;
  final String correction;
  final String explanation;

  const GrammarFeedbackBox({
    super.key,
    required this.error,
    required this.correction,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.toriiRed.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.toriiRed
                .withValues(alpha: AppColors.isDark(context) ? 0.12 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: AppColors.toriiRed,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: AppColors.toriiRed, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Sensei Feedback',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.toriiRed,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: AppColors.secondaryText(context),
                              fontSize: 14),
                          children: [
                            const TextSpan(text: 'Sai: '),
                            TextSpan(
                              text: error,
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.tertiaryText(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: AppColors.primaryText(context),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            const TextSpan(text: 'Sửa lại: '),
                            const TextSpan(
                              text: '',
                            ),
                            TextSpan(
                              text: correction,
                              style: const TextStyle(
                                  color: AppColors.successGreen),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          explanation,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText(context),
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
