import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        neonBorder: true,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'CÂU TIẾNG NHẬT',
              style: TextStyle(
                color: SNJ.sakura,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 18),

            FuriganaText(
              text: sentence.kanji.isNotEmpty ? sentence.kanji : sentence.romaji,
              furigana: sentence.furiganaHtml,
              kanjiFontSize: 28,
              furiganaFontSize: 13,
              kanjiColor: Colors.white,
              furiganaColor: SNJ.sakura,
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 16),

            if (sentence.romaji.isNotEmpty)
              _buildTranslationRow(
                'ROMAJI',
                sentence.romaji,
                SNJ.sakuraSoft,
                SNJ.sakura,
              ),
            if (sentence.romaji.isNotEmpty) const SizedBox(height: 12),

            if (sentence.hanViet.isNotEmpty)
              _buildTranslationRow(
                'HÁN-VIỆT',
                sentence.hanViet,
                Colors.white.withOpacity(0.06),
                const Color(0xFFCCB8D8),
              ),
            if (sentence.hanViet.isNotEmpty) const SizedBox(height: 12),

            if (sentence.meaning.isNotEmpty)
              _buildTranslationRow(
                'DỊCH NGHĨA',
                sentence.meaning,
                const Color(0x2710B981),
                const Color(0xFF34D399),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationRow(
      String label, String value, Color badgeColor, Color labelColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: labelColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlindModeCard() {
    final hintText = sentence.kanji.isNotEmpty
        ? sentence.kanji.substring(0, sentence.kanji.length.clamp(0, 3))
        : '？';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        neonBorder: true,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 240,
          child: CustomPaint(
            painter: DashedBorderPainter(color: SNJ.sakura),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: SNJ.sakuraGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: SNJ.sakura.withOpacity(0.2),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: const Text(
                      'BLIND MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.visibility_off_rounded,
                        size: 44,
                        color: SNJ.sakura.withOpacity(0.8),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Lắng nghe và lặp lại',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: SNJ.sakura,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        hintText,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      if (sentence.hanViet.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          sentence.hanViet.split(' ').take(2).join(' '),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.25)
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