import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/roadmap/models/roadmap_model.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

/// A single lesson node displayed on the zigzag path.
class LessonNode extends StatefulWidget {
  final LessonModel lesson;
  final int index;
  final VoidCallback? onTap;

  const LessonNode({
    super.key,
    required this.lesson,
    required this.index,
    this.onTap,
  });

  @override
  State<LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends State<LessonNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.lesson.status == LessonStatus.inProgress) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Zigzag: even index → aligned left, odd → center-right
    final alignment = _getAlignment();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: alignment,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label above
            if (widget.lesson.status == LessonStatus.inProgress)
              _InProgressBadge(title: widget.lesson.title),

            // The node circle
            GestureDetector(
              onTap: widget.onTap,
              child: _buildNode(),
            ),

            const SizedBox(height: 6),

            // Label below
            _NodeLabel(lesson: widget.lesson),
          ],
        ),
      ),
    );
  }

  Alignment _getAlignment() {
    final mod = widget.index % 4;
    if (mod == 0) return const Alignment(-0.7, 0);
    if (mod == 1) return const Alignment(0, 0);
    if (mod == 2) return const Alignment(0.7, 0);
    return const Alignment(0, 0);
  }

  Widget _buildNode() {
    final status = widget.lesson.status;

    if (status == LessonStatus.inProgress) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnim.value,
          child: child,
        ),
        child: _NodeCircle(
          status: status,
          icon: widget.lesson.icon,
        ),
      );
    }

    return _NodeCircle(
      status: status,
      icon: widget.lesson.icon,
    );
  }
}

class _NodeCircle extends StatelessWidget {
  final LessonStatus status;
  final IconData icon;

  const _NodeCircle({required this.status, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: _decoration(),
      child: Center(child: _innerContent()),
    );
  }

  BoxDecoration _decoration() {
    switch (status) {
      case LessonStatus.completed:
        return BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.toriiRed,
          boxShadow: [
            BoxShadow(
              color: AppColors.toriiRed.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        );
      case LessonStatus.inProgress:
        return BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFEBEE)],
          ),
          border: Border.all(color: AppColors.toriiRed, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.toriiRed.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        );
      case LessonStatus.locked:
        return BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE8EDF5),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
        );
    }
  }

  Widget _innerContent() {
    switch (status) {
      case LessonStatus.completed:
        return const Icon(Icons.check_rounded, color: Colors.white, size: 32);
      case LessonStatus.inProgress:
        return Icon(icon, color: AppColors.toriiRed, size: 30);
      case LessonStatus.locked:
        return const Icon(Icons.lock_rounded,
            color: Color(0xFFADB5BD), size: 26);
    }
  }
}

class _NodeLabel extends StatelessWidget {
  final LessonModel lesson;
  const _NodeLabel({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final isLocked = lesson.status == LessonStatus.locked;
    final isInProgress = lesson.status == LessonStatus.inProgress;
    return Column(
      children: [
        Text(
          lesson.subtitle.isNotEmpty ? lesson.subtitle.toUpperCase() : '',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isLocked
                ? const Color(0xFFADB5BD)
                : isInProgress
                    ? AppColors.toriiRed
                    : const Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 110,
          child: Text(
            lesson.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isLocked
                  ? const Color(0xFFADB5BD)
                  : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

class _InProgressBadge extends StatelessWidget {
  final String title;
  const _InProgressBadge({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.toriiRed,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.toriiRed.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ĐANG HỌC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
