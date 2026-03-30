import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/shadowing/models/shadowing_model.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/chapter_section.dart'; // To reuse DashedBorderPainter

class ShadowingCard extends StatelessWidget {
  final ShadowingSentenceModel sentence;
  final bool isBlindMode;

  const ShadowingCard({
    super.key,
    required this.sentence,
    required this.isBlindMode,
  });

  @override
  Widget build(BuildContext context) {
    if (isBlindMode) {
      return _buildBlindModeCard();
    }
    return _buildReadingModeCard();
  }

  Widget _buildReadingModeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.itemBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'JAPANESE KANJI',
            style: TextStyle(
              color: AppColors.sunRed,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // We cheat a bit with flutter text spans since real Ruby text needs specialized packages
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 32,
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: '今日'),
                TextSpan(
                  text: ' (きょう) ',
                  style: const TextStyle(fontSize: 16, color: AppColors.sunRed),
                ),
                const TextSpan(text: 'は天気'),
                TextSpan(
                  text: ' (てんき)\n',
                  style: const TextStyle(fontSize: 16, color: AppColors.sunRed),
                ),
                const TextSpan(text: 'がいいですね'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.slate100),
          const SizedBox(height: 24),
          _buildTranslationRow('ROMAJI', sentence.romaji, AppColors.lightPinkBackground, AppColors.sunRed),
          const SizedBox(height: 16),
          _buildTranslationRow('HÁN-VIỆT', sentence.hanViet, AppColors.lightPinkBackground, AppColors.textDark),
          const SizedBox(height: 16),
          _buildTranslationRow('DỊCH', sentence.meaning, AppColors.lightTealGreen, AppColors.progressTeal),
        ],
      ),
    );
  }

  Widget _buildTranslationRow(String label, String value, Color badgeColor, Color labelColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlindModeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.sakuraPink.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: CustomPaint(
        painter: DashedBorderPainter(color: AppColors.sakuraPink),
        child: Stack(
          children: [
             Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.sunRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('BLIND MODE ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            Center(
               child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_off_rounded, size: 48, color: AppColors.sakuraPink.withOpacity(0.8)),
                  const SizedBox(height: 16),
                  Text(
                    'Lắng nghe và lặp lại',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: AppColors.sunRed.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Keyword Hint Ghost Text
                  Text(
                    '漢字',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate300.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    'Hán-Việt',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate300.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
