import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/shadowing/models/shadowing_model.dart';

// ─── Màu Sakura Pink ────────────────────────────────────────────────────────
const _sakuraBg       = Color(0xFFFFF0F5);
const _sakuraBorder   = Color(0xFFFFB7C5);
const _sakuraDark     = Color(0xFFB5375A);
const _sakuraAccent   = Color(0xFFFF6B9D);

/// Bottom sheet hiện sau khi hoàn thành bài học Shadowing.
/// Hiển thị lời khuyên cá nhân hóa từ RecommendationEngine.
class RecommendationBottomSheet extends StatelessWidget {
  final ActionPlan actionPlan;
  final ErrorTypes errorTypes;
  final List<String> misprnouncedWords;
  final int accuracy;
  final int fluency;
  final int prosody;

  /// Callback khi người dùng nhấn action button
  final VoidCallback? onActionPressed;

  /// Callback khi nhấn "Tiếp tục"
  final VoidCallback? onContinue;

  const RecommendationBottomSheet({
    super.key,
    required this.actionPlan,
    required this.errorTypes,
    required this.misprnouncedWords,
    required this.accuracy,
    required this.fluency,
    required this.prosody,
    this.onActionPressed,
    this.onContinue,
  });

  /// Hiển thị bottom sheet với animation từ dưới lên
  static Future<void> show({
    required BuildContext context,
    required ActionPlan actionPlan,
    required ErrorTypes errorTypes,
    required List<String> misprnouncedWords,
    required int accuracy,
    required int fluency,
    required int prosody,
    VoidCallback? onActionPressed,
    VoidCallback? onContinue,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => RecommendationBottomSheet(
        actionPlan: actionPlan,
        errorTypes: errorTypes,
        misprnouncedWords: misprnouncedWords,
        accuracy: accuracy,
        fluency: fluency,
        prosody: prosody,
        onActionPressed: onActionPressed,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCelebrate = actionPlan.action == ActionType.celebrate &&
        actionPlan.severity == 0;

    return Container(
      decoration: BoxDecoration(
        color: _sakuraBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: _sakuraBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _sakuraBorder.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ───────────────────────────────────────────────────
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: _sakuraBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCelebrate
                      ? const Color(0xFFFFE4B5)
                      : _sakuraBorder.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  isCelebrate ? '🌟' : '🌸',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCelebrate ? 'Xuất sắc!' : 'AI Sensei nhận xét',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isCelebrate ? const Color(0xFFD97706) : _sakuraDark,
                    ),
                  ),
                  Text(
                    isCelebrate ? 'Phát âm rất chuẩn!' : 'Lời khuyên cải thiện',
                    style: TextStyle(
                      fontSize: 12,
                      color: _sakuraDark.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Error type badges ─────────────────────────────────────────────
          if (errorTypes.hasAnyError) ...[
            _buildErrorBadges(),
            const SizedBox(height: 16),
          ],

          // ── AI message box ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _sakuraBorder.withValues(alpha: 0.5)),
            ),
            child: Text(
              actionPlan.message,
              style: TextStyle(
                fontSize: 14,
                color: _sakuraDark,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Score summary mini ────────────────────────────────────────────
          _buildScoreSummary(),
          const SizedBox(height: 20),

          // ── Action Button (nếu có action cụ thể) ─────────────────────────
          if (actionPlan.action != ActionType.celebrate &&
              actionPlan.action != ActionType.retry &&
              onActionPressed != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: Icon(_getActionIcon(), size: 18),
                label: Text(
                  _getActionLabel(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sakuraAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Nút tiếp tục ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onContinue?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCelebrate ? AppColors.sunRed : Colors.white,
                foregroundColor: isCelebrate ? Colors.white : _sakuraDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                side: BorderSide(color: _sakuraBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isCelebrate ? 'Hoàn thành bài học 🎌' : 'Tiếp tục lộ trình →',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error Badge Cards ─────────────────────────────────────────────────────
  Widget _buildErrorBadges() {
    final badges = <_ErrorBadge>[];
    if (errorTypes.pronunciation.isNotEmpty) {
      badges.add(_ErrorBadge(
        label: 'Phát âm',
        icon: Icons.record_voice_over_rounded,
        color: AppColors.sunRed,
        words: errorTypes.pronunciation,
      ));
    }
    if (errorTypes.prosody.isNotEmpty) {
      badges.add(_ErrorBadge(
        label: 'Ngữ điệu',
        icon: Icons.graphic_eq_rounded,
        color: Colors.purple,
        words: errorTypes.prosody,
      ));
    }
    if (errorTypes.pitchAccent.isNotEmpty) {
      badges.add(_ErrorBadge(
        label: 'Trường âm',
        icon: Icons.music_note_rounded,
        color: Colors.indigo,
        words: errorTypes.pitchAccent,
      ));
    }
    if (errorTypes.rhythm.isNotEmpty) {
      badges.add(_ErrorBadge(
        label: 'Nhịp ngắt',
        icon: Icons.timer_outlined,
        color: Colors.orange,
        words: errorTypes.rhythm,
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges.map((b) => _buildBadgeChip(b)).toList(),
    );
  }

  Widget _buildBadgeChip(_ErrorBadge badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badge.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 13, color: badge.color),
          const SizedBox(width: 5),
          Text(
            badge.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: badge.color,
            ),
          ),
          if (badge.words.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              '(${badge.words.join(', ')})',
              style: TextStyle(
                fontSize: 11,
                color: badge.color.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ── Score Summary ─────────────────────────────────────────────────────────
  Widget _buildScoreSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sakuraBorder.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _miniScore('Phát âm', accuracy, AppColors.sunRed),
          _divider(),
          _miniScore('Ngắt nghỉ', fluency, Colors.orange),
          _divider(),
          _miniScore('Ngữ điệu', prosody, Colors.purple),
        ],
      ),
    );
  }

  Widget _miniScore(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          '$score',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        height: 36,
        width: 1,
        color: _sakuraBorder.withValues(alpha: 0.5),
      );

  // ── Action helpers ────────────────────────────────────────────────────────
  IconData _getActionIcon() {
    switch (actionPlan.action) {
      case ActionType.openVocabulary:    return Icons.menu_book_rounded;
      case ActionType.activateSlowMode:  return Icons.slow_motion_video_rounded;
      case ActionType.showHanVietMode:   return Icons.translate_rounded;
      case ActionType.showPitchGuide:    return Icons.music_note_rounded;
      default:                           return Icons.arrow_forward_rounded;
    }
  }

  String _getActionLabel() {
    switch (actionPlan.action) {
      case ActionType.openVocabulary:
        final word = actionPlan.targetWord;
        return word != null ? 'Xem từ 「$word」 trong kho từ vựng' : 'Mở kho từ vựng';
      case ActionType.activateSlowMode:  return 'Kích hoạt chế độ 0.75x';
      case ActionType.showHanVietMode:   return 'Bật chế độ Hiện Hán-Việt';
      case ActionType.showPitchGuide:    return 'Xem hướng dẫn Pitch-accent';
      default:                           return 'Xem chi tiết';
    }
  }
}

// ── Helper class ──────────────────────────────────────────────────────────────
class _ErrorBadge {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> words;
  const _ErrorBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.words,
  });
}
