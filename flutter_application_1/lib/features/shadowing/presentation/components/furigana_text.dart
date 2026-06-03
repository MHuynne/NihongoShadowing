import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

/// Widget hiển thị furigana (chú âm) cho câu tiếng Nhật.
/// Hỗ trợ 2 định dạng dữ liệu:
///   1. HTML: <ruby>漢字<rt>かんじ</rt></ruby> — ánh xạ từng từ
///   2. Hiragana thuần: toàn bộ chuỗi hiragana hiển thị nhỏ bên trên kanji
class FuriganaText extends StatelessWidget {
  final String text;       // kanji (câu gốc)
  final String furigana;  // furigana (HTML ruby hoặc hiragana thuần)
  final double kanjiFontSize;
  final double furiganaFontSize;
  final Color kanjiColor;
  final Color furiganaColor;

  const FuriganaText({
    super.key,
    required this.text,
    this.furigana = '',
    this.kanjiFontSize = 26.0,
    this.furiganaFontSize = 12.0,
    this.kanjiColor = AppColors.textDark,
    this.furiganaColor = AppColors.sunRed,
  });

  @override
  Widget build(BuildContext context) {
    if (furigana.isNotEmpty && furigana.contains('<ruby>')) {
      // Format 1: HTML ruby tags
      return _buildFromRubyHtml(furigana);
    } else if (furigana.isNotEmpty) {
      // Format 2: hiragana thuần — hiển thị trên dòng kanji
      return _buildSimpleFurigana(text, furigana);
    } else if (text.isNotEmpty) {
      // Không có furigana — chỉ hiển thị kanji
      return Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: kanjiFontSize,
          color: kanjiColor,
          fontWeight: FontWeight.bold,
          height: 1.6,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Format 1: Parse <ruby>kanji<rt>furi</rt></ruby> ──────────────────────────
  Widget _buildFromRubyHtml(String htmlText) {
    final RegExp rubyRegex = RegExp(r'<ruby>(.*?)<rt>(.*?)</rt></ruby>');
    final List<Widget> children = [];

    htmlText.splitMapJoin(
      rubyRegex,
      onMatch: (Match match) {
        final kanji = match.group(1) ?? '';
        final furi  = match.group(2) ?? '';
        children.add(_rubyPair(kanji, furi));
        return '';
      },
      onNonMatch: (String nonMatch) {
        if (nonMatch.isNotEmpty) {
          children.add(_plainChar(nonMatch));
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

  // ── Format 2: Hiragana thuần trên dòng kanji ─────────────────────────────────
  Widget _buildSimpleFurigana(String kanji, String reading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          reading,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: furiganaFontSize,
            color: furiganaColor,
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          kanji,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: kanjiFontSize,
            color: kanjiColor,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ── Helpers cho ruby HTML ────────────────────────────────────────────────────
  Widget _rubyPair(String kanji, String furi) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          furi,
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
    );
  }

  Widget _plainChar(String chars) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(' ', style: TextStyle(fontSize: furiganaFontSize, height: 1.0)),
        const SizedBox(height: 2),
        Text(
          chars,
          style: TextStyle(
            fontSize: kanjiFontSize,
            color: kanjiColor,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
