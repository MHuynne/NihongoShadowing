import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'furigana_text.dart';
import '../../models/chat_message_model.dart';

class KeigoSuggestionCard extends StatelessWidget {
  final VoidCallback onApply;

  const KeigoSuggestionCard({super.key, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.progressTeal.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.progressTeal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.progressTeal, size: 16),
              const SizedBox(width: 8),
              const Text(
                'KEIGO SUGGESTION',
                style: TextStyle(
                  color: AppColors.progressTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                 width: 32,
                 height: 32,
                 decoration: BoxDecoration(
                   color: AppColors.progressTeal.withValues(alpha: 0.1),
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(Icons.auto_awesome, color: AppColors.progressTeal, size: 16),
              )
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(color: AppColors.slate700, fontSize: 14, height: 1.5),
              children: [
                TextSpan(text: 'In a formal context, use '),
                TextSpan(text: '"desu"', style: TextStyle(color: AppColors.progressTeal, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                TextSpan(text: ' and honorifics. Try this version:'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: const [
                 FuriganaText(
                   words: [
                     ChatFuriganaWord('失礼', furigana: 'しつれい'),
                     ChatFuriganaWord('いたします。'),
                   ],
                 ),
               ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.progressTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Apply Suggestion',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
