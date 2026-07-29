import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/roadmap/models/roadmap_model.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';

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
    final alignment = _getAlignment();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: alignment,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.lesson.status == LessonStatus.inProgress)
              _InProgressBadge(progress: widget.lesson.progress),
            if (widget.lesson.status == LessonStatus.completed)
              const _CompletedBadge(),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: widget.onTap,
              child: _buildNode(),
            ),
            const SizedBox(height: 8),
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
          gradient: SNJ.sakuraGradient,
          boxShadow: [
            BoxShadow(
              color: SNJ.sakura.withOpacity(0.45),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case LessonStatus.inProgress:
        return BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF160A30),
          border: Border.all(color: SNJ.sakura, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: SNJ.sakura.withOpacity(0.5),
              blurRadius: 22,
              spreadRadius: 3,
            ),
          ],
        );
      case LessonStatus.locked:
        return BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        );
    }
  }

  Widget _innerContent() {
    switch (status) {
      case LessonStatus.completed:
        return const Icon(Icons.check_rounded, color: Colors.white, size: 34);
      case LessonStatus.inProgress:
        return Icon(icon, color: Colors.white, size: 30);
      case LessonStatus.locked:
        return const Icon(Icons.lock_rounded,
            color: Color(0xFF5E4E75), size: 24);
    }
  }
}

class _NodeLabel extends StatelessWidget {
  final LessonModel lesson;
  const _NodeLabel({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final isLocked    = lesson.status == LessonStatus.locked;
    final isInProgress = lesson.status == LessonStatus.inProgress;
    final isCompleted  = lesson.status == LessonStatus.completed;

    final subtitleColor = isLocked
        ? const Color(0xFF5E4E75)
        : isInProgress
            ? SNJ.sakura
            : isCompleted
                ? const Color(0xFF10B981)
                : const Color(0xFF8877A0);

    final titleColor = isLocked ? const Color(0xFF5E4E75) : Colors.white;

    return Column(
      children: [
        Text(
          lesson.subtitle.isNotEmpty ? lesson.subtitle.toUpperCase() : '',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: subtitleColor,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 120,
          child: Text(
            lesson.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: titleColor,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _InProgressBadge extends StatelessWidget {
  final double? progress;
  const _InProgressBadge({this.progress});

  @override
  Widget build(BuildContext context) {
    final int percent = progress != null ? (progress! * 100).round() : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: SNJ.sakuraGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: SNJ.sakura.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Text(
        percent > 0 ? 'ĐANG HỌC ($percent%)' : 'ĐANG HỌC',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x2710B981),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981), width: 1.0),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 11),
          SizedBox(width: 4),
          Text(
            'HOÀN THÀNH',
            style: TextStyle(
              color: Color(0xFF34D399),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}