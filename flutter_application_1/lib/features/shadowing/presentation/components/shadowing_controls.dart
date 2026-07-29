import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';

class ShadowingControls extends StatelessWidget {
  final bool isRecording;
  final bool isPlayingSample;
  final VoidCallback onRecordPressed;
  final VoidCallback onPlaySample;
  final VoidCallback onSpeedToggle;
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SampleButton(
            isPlaying: isPlayingSample,
            onPressed: onPlaySample,
          ),

          GestureDetector(
            onTap: onRecordPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                gradient: SNJ.sakuraGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SNJ.sakura.withOpacity(isRecording ? 0.6 : 0.3),
                    blurRadius: isRecording ? 28 : 16,
                    spreadRadius: isRecording ? 6 : 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),

          _buildSideButton(
            icon: Icons.speed_rounded,
            label: '×${currentSpeed == 1.0 ? "1.0" : currentSpeed.toString()}',
            color: SNJ.sakura,
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
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.0,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFFCCB8D8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

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
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: isPlaying
                  ? SNJ.sakuraSoft
                  : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isPlaying
                    ? SNJ.sakura
                    : Colors.white.withOpacity(0.08),
                width: isPlaying ? 1.5 : 1.0,
              ),
            ),
            child: isPlaying
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: SNJ.sakura,
                    ),
                  )
                : const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            isPlaying ? 'ĐANG PHÁT' : 'AUDIO MẪU',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isPlaying ? SNJ.sakura : const Color(0xFFCCB8D8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}