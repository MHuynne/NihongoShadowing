import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/roadmap/models/roadmap_model.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/lesson_node.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/flashcard_screen.dart';

class ChapterSection extends StatefulWidget {
  final ChapterModel chapter;

  const ChapterSection({super.key, required this.chapter});

  @override
  State<ChapterSection> createState() => _ChapterSectionState();
}

class _ChapterSectionState extends State<ChapterSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnimController;
  late Animation<double> _fadeAnim;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _headerAnimController.forward();
      } else {
        _headerAnimController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (chapter.lessons.isEmpty) return _buildEmptyChapter();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChapterBanner(),
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          child: _expanded
              ? FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildLessonsPath(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  ChapterModel get chapter => widget.chapter;

  Widget _buildChapterBanner() {
    final color =
        chapter.isLocked ? const Color(0xFF94A3B8) : AppColors.toriiRed;
    final bgColor = chapter.isLocked
        ? const Color(0xFFF1F5F9)
        : Colors.white;

    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        margin: const EdgeInsets.only(top: 24, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: chapter.isLocked
                ? const Color(0xFFE2E8F0)
                : AppColors.toriiRed.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Mountain icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: chapter.isLocked
                    ? const Color(0xFFE2E8F0)
                    : AppColors.toriiRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                chapter.isLocked
                    ? Icons.lock_rounded
                    : Icons.landscape_rounded,
                color: chapter.isLocked
                    ? const Color(0xFF94A3B8)
                    : Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  if (chapter.statusBadge != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      chapter.statusBadge!,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedRotation(
              turns: _expanded ? 0 : 0.5,
              duration: const Duration(milliseconds: 300),
              child: Icon(Icons.keyboard_arrow_up_rounded,
                  color: color, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsPath() {
    return CustomPaint(
      painter: _ZigzagPathPainter(
        lessonCount: chapter.lessons.length,
        tealColor: AppColors.toriiRed,
        dotted: true,
      ),
      child: Column(
        children: chapter.lessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          return LessonNode(
            lesson: lesson,
            index: index,
            onTap: () {
              if (lesson.status != LessonStatus.locked &&
                  lesson.id != 'err_msg') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FlashcardScreen(topicId: int.tryParse(lesson.id) ?? 1),
                  ),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyChapter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChapterBanner(),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.slate200,
            ),
          ),
          child: Center(
            child: Text(
              '···',
              style: TextStyle(
                  color: AppColors.slate400,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints a dashed zigzag path behind the lesson nodes.
class _ZigzagPathPainter extends CustomPainter {
  final int lessonCount;
  final Color tealColor;
  final bool dotted;

  _ZigzagPathPainter({
    required this.lessonCount,
    required this.tealColor,
    this.dotted = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lessonCount < 2) return;

    final paint = Paint()
      ..color = tealColor.withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double nodeHeight = 140.0; // approx height per node slot

    // Zigzag x positions
    final positions = List.generate(lessonCount, (i) {
      final mod = i % 4;
      if (mod == 0) return size.width * 0.15;
      if (mod == 1) return size.width * 0.5;
      if (mod == 2) return size.width * 0.85;
      return size.width * 0.5;
    });

    final path = Path();
    for (int i = 0; i < lessonCount; i++) {
      final y = nodeHeight * i + nodeHeight / 2;
      final x = positions[i];
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevY = nodeHeight * (i - 1) + nodeHeight / 2;
        final prevX = positions[i - 1];
        final midY = (y + prevY) / 2;
        path.cubicTo(prevX, midY, x, midY, x, y);
      }
    }

    // Draw as dashes
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 5.0;
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
