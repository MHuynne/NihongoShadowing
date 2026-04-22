import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

class ShadowingControls extends StatelessWidget {
  final bool isRecording;
  final bool isPlayingSample;   // THÊM: đang phát audio mẫu hay không
  final VoidCallback onRecordPressed;
  final VoidCallback onPlaySample;
  final VoidCallback onSpeedToggle;  // THÊM: thay đổi tốc độ
  final double currentSpeed;

  const ShadowingControls({
    super.key,
    required this.isRecording,
    required this.onRecordPressed,
    required this.onPlaySample,
    this.isPlayingSample = false,
    required this.onSpeedToggle,
    this.currentSpeed = 1.0,
  });

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Play Sample Button ──────────────────────────────────────
          _SampleButton(
            isPlaying: isPlayingSample,
            onPressed: onPlaySample,
          ),

          // ── Main Record Button ──────────────────────────────────────
          GestureDetector(
            onTap: onRecordPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.sunRed,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isRecording)
                    BoxShadow(
                      color: AppColors.sunRed.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 10,
                    ),
                  BoxShadow(
                    color: AppColors.sunRed.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          // ── Speed Toggle Button ────────────────────────────────────
          _buildSideButton(
            icon: Icons.speed_rounded,
            label: '×${currentSpeed == 1.0 ? "1.0" : currentSpeed.toString()}',
            color: AppColors.sunRed,
            onPressed: onSpeedToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightPinkBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sample Button với animation loading ──────────────────────────────────────
class _SampleButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _SampleButton({required this.isPlaying, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPlaying
                  ? AppColors.sunRed.withValues(alpha: 0.15)
                  : AppColors.lightPinkBackground,
              shape: BoxShape.circle,
              border: isPlaying
                  ? Border.all(color: AppColors.sunRed, width: 2)
                  : null,
            ),
            child: isPlaying
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.sunRed,
                    ),
                  )
                : Icon(Icons.play_arrow_rounded, color: AppColors.sunRed, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            isPlaying ? 'ĐANG PHÁT' : 'SAMPLE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.sunRed,
            ),
          ),
        ],
      ),
    );
  }
}
