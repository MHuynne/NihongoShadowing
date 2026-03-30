import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

class ShadowingControls extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onRecordPressed;
  final VoidCallback onPlaySample;

  const ShadowingControls({
    super.key,
    required this.isRecording,
    required this.onRecordPressed,
    required this.onPlaySample,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Play Sample Button
          _buildSideButton(
            icon: Icons.play_arrow_rounded,
            label: 'SAMPLE',
            color: AppColors.sunRed,
            onPressed: onPlaySample,
          ),
          
          // Main Record Button
          GestureDetector(
             onTap: onRecordPressed,
             child: Container(
               width: 80,
               height: 80,
               decoration: BoxDecoration(
                 color: AppColors.sunRed,
                 shape: BoxShape.circle,
                 boxShadow: [
                   if (isRecording)
                     BoxShadow(
                       color: AppColors.sunRed.withOpacity(0.4),
                       blurRadius: 20,
                       spreadRadius: 10,
                     ),
                   BoxShadow(
                     color: AppColors.sunRed.withOpacity(0.2),
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
          
          // Slowmo Button
          _buildSideButton(
            icon: Icons.play_circle_outline_rounded,
            label: 'X0.5',
            color: AppColors.sunRed,
            onPressed: () {}, // Future implementation
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
