import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/shadowing/models/shadowing_model.dart';
import 'package:flutter_application_1/features/shadowing/presentation/components/furigana_text.dart';

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
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.sunRed.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'CÂU TIẾNG NHẬT',
            style: TextStyle(
              color: AppColors.sunRed,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // --- KANJI & FURIGANA (Parse từ HTML và đưa furigana lên đầu) ---
          if (sentence.furiganaHtml.isNotEmpty && sentence.furiganaHtml.contains('<ruby>'))
             FuriganaText(text: sentence.furiganaHtml)
          else 
             Text(
               sentence.kanji.isNotEmpty ? sentence.kanji : sentence.romaji,
               textAlign: TextAlign.center,
               style: const TextStyle(
                 fontSize: 30,
                 color: AppColors.textDark,
                 fontWeight: FontWeight.bold,
                 height: 1.6,
               ),
             ),

          const SizedBox(height: 24),
          const Divider(color: AppColors.slate100),
          const SizedBox(height: 20),

          // --- CÁC DÒNG DỊCH (Data thật từ API) ---
          if (sentence.romaji.isNotEmpty)
            _buildTranslationRow('ROMAJI', sentence.romaji, AppColors.lightPinkBackground, AppColors.sunRed),
          if (sentence.romaji.isNotEmpty) const SizedBox(height: 12),

          if (sentence.hanViet.isNotEmpty)
            _buildTranslationRow('HÁN-VIỆT', sentence.hanViet, AppColors.lightPinkBackground, AppColors.textDark),
          if (sentence.hanViet.isNotEmpty) const SizedBox(height: 12),

          if (sentence.meaning.isNotEmpty)
            _buildTranslationRow('DỊCH NGHĨA', sentence.meaning, AppColors.lightTealGreen, AppColors.progressTeal),
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
              fontSize: 15,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlindModeCard() {
    // Lấy 2-3 ký tự đầu của Kanji làm gợi ý mờ
    final hintText = sentence.kanji.isNotEmpty
        ? sentence.kanji.substring(0, sentence.kanji.length.clamp(0, 3))
        : '？';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.sakuraPink.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                child: const Text('BLIND MODE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_off_rounded, size: 40, color: AppColors.sakuraPink.withValues(alpha: 0.8)),
                  const SizedBox(height: 12),
                  const Text(
                    'Lắng nghe và lặp lại',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: AppColors.sunRed,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Gợi ý mờ từ data thật
                  Text(
                    hintText,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate300.withValues(alpha: 0.5),
                    ),
                  ),
                  if (sentence.hanViet.isNotEmpty)
                    Text(
                      sentence.hanViet.split(' ').take(2).join(' '),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.slate300.withValues(alpha: 0.5),
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

/// Dashed border painter for blind mode card.
class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(24),
    );

    const dashLength = 10.0;
    const gapLength = 6.0;
    final path = Path()..addRRect(rRect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      bool drawing = true;
      while (distance < metric.length) {
        if (drawing) {
          final end = (distance + dashLength).clamp(0.0, metric.length);
          canvas.drawPath(metric.extractPath(distance, end), paint);
        }
        distance += drawing ? dashLength : gapLength;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
