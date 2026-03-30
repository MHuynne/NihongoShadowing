import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/roadmap/models/roadmap_model.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/lesson_card.dart';

class ChapterSection extends StatelessWidget {
  final ChapterModel chapter;

  const ChapterSection({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    if (chapter.lessons.isEmpty) {
      return _buildEmptyChapter();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChapterHeader(),
        const SizedBox(height: 16),
        ...chapter.lessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          final isLast = index == chapter.lessons.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline line
                Container(
                  width: 3,
                  margin: const EdgeInsets.only(left: 32, right: 32),
                  decoration: BoxDecoration(
                     color: isLast ? Colors.transparent : _getTimelineColor(lesson.status),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: LessonCard(lesson: lesson),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChapterHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 24,
              decoration: BoxDecoration(
                color: chapter.isLocked ? AppColors.slate300 : AppColors.progressTeal,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              chapter.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: chapter.isLocked ? AppColors.slate500 : AppColors.textDark,
              ),
            ),
          ],
        ),
        if (chapter.statusBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: chapter.isLocked ? AppColors.slate100 : AppColors.lightTealGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              chapter.statusBadge!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: chapter.isLocked ? AppColors.slate500 : AppColors.progressTeal,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyChapter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChapterHeader(),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.only(left: 48),
          height: 60,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200, style: BorderStyle.none),
          ),
          child: CustomPaint(
            painter: DashedBorderPainter(color: AppColors.slate300),
            child: const Center(
               child: Text('...', style: TextStyle(color: AppColors.slate400, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Color _getTimelineColor(LessonStatus status) {
     if (status == LessonStatus.completed) {
       return AppColors.lightTealGreen;
     } else if (status == LessonStatus.inProgress) {
       return AppColors.slate200;
     }
     return AppColors.slate200;
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;

  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Using simple path with dash, normally would be done with path_drawing package or similar
    // We'll mimic this by simply drawing rounded rect with normal border if dash is complex without 3rd party.
    // For simplicity without external dashed package:
    final RRect rect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20));
    canvas.drawRRect(rect, paint..strokeWidth = 1.5..color = color.withOpacity(0.5)); // Fallback to semi-transparent solid
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
