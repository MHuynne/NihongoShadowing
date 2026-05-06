import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RoleplayMicButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const RoleplayMicButton({
    super.key,
    required this.isRecording,
    required this.onTap,
  });

  @override
  State<RoleplayMicButton> createState() => _RoleplayMicButtonState();
}

class _RoleplayMicButtonState extends State<RoleplayMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RoleplayMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hiệu ứng vòng tròn xung quanh khi thu âm
          if (widget.isRecording)
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.toriiRed.withValues(alpha: 0.24),
                ),
              ),
            ),

          // Nút Mic chính
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: widget.isRecording ? 64 : 56,
            height: widget.isRecording ? 64 : 56,
            decoration: BoxDecoration(
              gradient: widget.isRecording
                  ? const LinearGradient(
                      colors: [AppColors.errorRed, AppColors.toriiRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [AppColors.toriiRed, AppColors.toriiRedLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              shape: BoxShape.circle,
              boxShadow: widget.isRecording
                  ? [
                      BoxShadow(
                        color: AppColors.toriiRed.withValues(alpha: 0.34),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.toriiRed.withValues(alpha: 0.26),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Icon(
              widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: widget.isRecording ? 32 : 28,
            ),
          ),
        ],
      ),
    );
  }
}
