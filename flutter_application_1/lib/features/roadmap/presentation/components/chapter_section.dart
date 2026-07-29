import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';
import 'package:flutter_application_1/features/roadmap/models/roadmap_model.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/lesson_node.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/flashcard_screen.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/vocabulary_test_screen.dart';
import 'package:flutter_application_1/features/shadowing/presentation/screens/shadowing_screen.dart';

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
    final isLocked = chapter.isLocked;

    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        margin: const EdgeInsets.only(top: 24, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isLocked
              ? Colors.white.withOpacity(0.03)
              : const Color(0xD4150A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLocked
                ? Colors.white.withOpacity(0.08)
                : SNJ.borderNeon,
            width: isLocked ? 0.8 : 1.2,
          ),
          boxShadow: isLocked
              ? null
              : [
                  BoxShadow(
                    color: SNJ.sakura.withOpacity(0.12),
                    blurRadius: 18,
                    spreadRadius: 1,
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.white.withOpacity(0.06)
                    : SNJ.sakuraSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLocked
                      ? Colors.transparent
                      : SNJ.borderNeon.withOpacity(0.5),
                  width: 1.0,
                ),
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.landscape_rounded,
                color: isLocked ? const Color(0xFF8877A0) : SNJ.sakura,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isLocked ? const Color(0xFF8877A0) : Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (chapter.statusBadge != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      chapter.statusBadge!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isLocked
                            ? const Color(0xFF685780)
                            : const Color(0xFFCCB8D8),
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
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                color: isLocked ? const Color(0xFF8877A0) : SNJ.sakura,
                size: 24,
              ),
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
        tealColor: SNJ.sakura,
        dotted: true,
      ),
      child: Column(
        children: chapter.lessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          return LessonNode(
            lesson: lesson,
            index: index,
            onTap: () => _navigateToLesson(lesson),
          );
        }).toList(),
      ),
    );
  }

  void _navigateToLesson(LessonModel lesson) {
    if (lesson.status == LessonStatus.locked || lesson.id == 'err_msg') return;

    if (lesson.status == LessonStatus.completed) {
      _showReplayDialog(lesson);
      return;
    }

    if (lesson.testPassed) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShadowingScreen(
            topicId: lesson.topicId,
            lessonId: lesson.lessonId,
            testErrors: 0,
          ),
        ),
      );
    } else if (lesson.flashcardDone) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VocabularyTestScreen(
            topicId: lesson.topicId,
            lessonId: lesson.lessonId,
            isReview: false,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlashcardScreen(
            topicId: lesson.topicId,
            lessonId: lesson.lessonId,
          ),
        ),
      );
    }
  }

  void _showReplayDialog(LessonModel lesson) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1E0F38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: SNJ.borderNeon, width: 1.5),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: SNJ.sakura.withOpacity(0.12),
                blurRadius: 28,
              )
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0x1F16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                lesson.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bài học này đã hoàn thành. Hãy chọn nội dung bạn muốn ôn tập lại bên dưới:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFCCB8D8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _replayBtn(
                icon: Icons.style_rounded,
                label: 'Từ vựng (Flashcard)',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardScreen(
                          topicId: lesson.topicId, lessonId: lesson.lessonId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _replayBtn(
                icon: Icons.quiz_rounded,
                label: 'Kiểm tra từ vựng (Test)',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VocabularyTestScreen(
                          topicId: lesson.topicId,
                          lessonId: lesson.lessonId,
                          isReview: false),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _replayBtn(
                icon: Icons.mic_rounded,
                label: 'Luyện phát âm (Shadowing)',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShadowingScreen(
                          topicId: lesson.topicId,
                          lessonId: lesson.lessonId,
                          testErrors: 0),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Hủy bỏ',
                  style: TextStyle(
                    color: Color(0xFF8877A0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _replayBtn(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: SNJ.sakura),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: SNJ.borderNeon, width: 1.2),
          backgroundColor: Colors.white.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
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
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: const Center(
            child: Text(
              '···',
              style: TextStyle(
                color: Color(0xFF8877A0),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
      ..color = tealColor.withOpacity(0.3)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double nodeHeight = 140.0;

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