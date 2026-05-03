import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

class FuriganaText extends StatelessWidget {
  final String text;
  final double kanjiFontSize;
  final double furiganaFontSize;
  final Color kanjiColor;
  final Color furiganaColor;

  const FuriganaText({
    super.key,
    required this.text,
    this.kanjiFontSize = 26.0,
    this.furiganaFontSize = 12.0,
    this.kanjiColor = AppColors.textDark,
    this.furiganaColor = AppColors.sunRed,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    // Regex to extract <ruby>kanji<rt>furigana</rt></ruby>
    final RegExp rubyRegex = RegExp(r'<ruby>(.*?)<rt>(.*?)</rt></ruby>');
    final List<Widget> children = [];

    text.splitMapJoin(
      rubyRegex,
      onMatch: (Match match) {
        // match.group(1) is Kanji, match.group(2) is Furigana
        final kanji = match.group(1) ?? '';
        final furigana = match.group(2) ?? '';

        children.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                furigana,
                style: TextStyle(
                  fontSize: furiganaFontSize,
                  color: furiganaColor,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                kanji,
                style: TextStyle(
                  fontSize: kanjiFontSize,
                  color: kanjiColor,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ],
          ),
        );
        return '';
      },
      onNonMatch: (String nonMatchText) {
        if (nonMatchText.isNotEmpty) {
          children.add(
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Invisible furigana to keep baseline alignment horizontally
                Text(
                  ' ',
                  style: TextStyle(
                    fontSize: furiganaFontSize,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nonMatchText,
                  style: TextStyle(
                    fontSize: kanjiFontSize,
                    color: kanjiColor,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          );
        }
        return '';
      },
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: 10.0,
      children: children,
    );
  }
}
