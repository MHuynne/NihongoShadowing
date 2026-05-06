
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

/// Widget hiển thị tiến độ học tập dưới dạng leo núi Phú Sĩ.
///
/// [completedLessons] - số bài đã hoàn thành
/// [totalLessons]     - tổng số bài học
/// [levelLabel]       - nhãn cấp độ hiện tại (N5, N4, N3...)
/// [animate]          - có chạy animation khi vào màn hình không
class MountainProgressWidget extends StatefulWidget {
  final int completedLessons;
  final int totalLessons;
  final String levelLabel;
  final bool animate;
  final VoidCallback? onTap;

  const MountainProgressWidget({
    super.key,
    required this.completedLessons,
    required this.totalLessons,
    required this.levelLabel,
    this.animate = true,
    this.onTap,
  });

  @override
  State<MountainProgressWidget> createState() => _MountainProgressWidgetState();
}

class _MountainProgressWidgetState extends State<MountainProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progressAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    final target = widget.totalLessons > 0
        ? widget.completedLessons / widget.totalLessons
        : 0.0;

    _progressAnim = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MountainProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completedLessons != widget.completedLessons) {
      final target = widget.totalLessons > 0
          ? widget.completedLessons / widget.totalLessons
          : 0.0;
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: target,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.totalLessons > 0
        ? (widget.completedLessons / widget.totalLessons * 100).round()
        : 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A3E), Color(0xFF0F1729)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.toriiRed.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Column(
                children: [
                  // ── Mountain canvas ─────────────────────────────────────
                  SizedBox(
                    height: 180,
                    child: CustomPaint(
                      painter: _MountainPainter(
                        progress: _progressAnim.value,
                        glowOpacity: _glowAnim.value,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildTopBadge(),
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom info bar ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF12122A),
                    ),
                    child: Row(
                      children: [
                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.toriiRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.toriiRed.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            widget.levelLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.toriiRedLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${widget.completedLessons}/${widget.totalLessons} bài',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$pct%',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _progressAnim.value,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.08),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppColors.toriiRed),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            '🗻 Leo núi Phú Sĩ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '富士山',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── CustomPainter — Vẽ núi Phú Sĩ + nhân vật leo núi ────────────────────────

class _MountainPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final double glowOpacity;

  const _MountainPainter({
    required this.progress,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Background sky gradient ──────────────────────────────────────────
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0D1B3E),
          const Color(0xFF1A2A5E),
          const Color(0xFF243060),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // ── Stars ────────────────────────────────────────────────────────────
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.fill;

    final starPositions = [
      Offset(w * 0.08, h * 0.08),
      Offset(w * 0.2,  h * 0.05),
      Offset(w * 0.35, h * 0.12),
      Offset(w * 0.65, h * 0.07),
      Offset(w * 0.78, h * 0.04),
      Offset(w * 0.90, h * 0.10),
      Offset(w * 0.55, h * 0.03),
      Offset(w * 0.12, h * 0.20),
      Offset(w * 0.88, h * 0.22),
    ];
    for (final pos in starPositions) {
      canvas.drawCircle(pos, 1.5, starPaint);
    }

    // ── Moon ─────────────────────────────────────────────────────────────
    final moonPaint = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.9);
    canvas.drawCircle(Offset(w * 0.85, h * 0.15), 10, moonPaint);
    // Moon crescent shadow
    canvas.drawCircle(
      Offset(w * 0.88, h * 0.14),
      9,
      Paint()..color = const Color(0xFF1A2A5E),
    );

    // ── Mountain body ────────────────────────────────────────────────────
    final mountainPath = Path();
    mountainPath.moveTo(0, h);
    mountainPath.lineTo(w * 0.05, h * 0.75);
    mountainPath.quadraticBezierTo(w * 0.15, h * 0.45, w * 0.35, h * 0.25);
    mountainPath.quadraticBezierTo(w * 0.45, h * 0.12, w * 0.50, h * 0.05);
    mountainPath.quadraticBezierTo(w * 0.55, h * 0.12, w * 0.65, h * 0.25);
    mountainPath.quadraticBezierTo(w * 0.85, h * 0.45, w * 0.95, h * 0.75);
    mountainPath.lineTo(w, h);
    mountainPath.close();

    final mountainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3D4A6B),
          const Color(0xFF2D3A5B),
          const Color(0xFF1E2A45),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(mountainPath, mountainPaint);

    // ── Snow cap ──────────────────────────────────────────────────────────
    final snowPath = Path();
    snowPath.moveTo(w * 0.35, h * 0.28);
    snowPath.quadraticBezierTo(w * 0.45, h * 0.14, w * 0.50, h * 0.05);
    snowPath.quadraticBezierTo(w * 0.55, h * 0.14, w * 0.65, h * 0.28);
    snowPath.quadraticBezierTo(w * 0.575, h * 0.20, w * 0.50, h * 0.18);
    snowPath.quadraticBezierTo(w * 0.425, h * 0.20, w * 0.35, h * 0.28);
    snowPath.close();

    canvas.drawPath(
      snowPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.92)
        ..style = PaintingStyle.fill,
    );

    // Snow outline
    canvas.drawPath(
      snowPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // ── Path trail on mountain ────────────────────────────────────────────
    // Điểm trên đường leo (từ đáy → đỉnh)
    final pathPoints = _getMountainPathPoints(w, h);

    // Vẽ đường trail (chưa đi)
    final trailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final trailPath = Path();
    trailPath.moveTo(pathPoints.first.dx, pathPoints.first.dy);
    for (int i = 1; i < pathPoints.length; i++) {
      trailPath.lineTo(pathPoints[i].dx, pathPoints[i].dy);
    }
    canvas.drawPath(trailPath, trailPaint);

    // ── Completed trail (đã đi) ───────────────────────────────────────────
    final completedIndex =
        (progress * (pathPoints.length - 1)).round().clamp(0, pathPoints.length - 1);

    if (completedIndex > 0) {
      final donePaint = Paint()
        ..color = AppColors.toriiRed.withValues(alpha: 0.85)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final donePath = Path();
      donePath.moveTo(pathPoints[0].dx, pathPoints[0].dy);
      for (int i = 1; i <= completedIndex; i++) {
        donePath.lineTo(pathPoints[i].dx, pathPoints[i].dy);
      }
      canvas.drawPath(donePath, donePaint);

      // Waypoint dots
      for (int i = 0; i <= completedIndex; i += 3) {
        canvas.drawCircle(
          pathPoints[i],
          2.5,
          Paint()..color = AppColors.toriiRed,
        );
      }
    }

    // ── Climber (nhân vật leo núi) ────────────────────────────────────────
    final climberPos = pathPoints[completedIndex];
    _drawClimber(canvas, climberPos, glowOpacity);

    // ── Flag at summit ────────────────────────────────────────────────────
    if (progress >= 1.0) {
      _drawFlag(canvas, Offset(w * 0.50, h * 0.05 - 16));
    }

    // ── XP label (nếu progress > 0) ──────────────────────────────────────
    if (progress > 0.05) {
      final labelOffset = pathPoints[completedIndex];
      _drawXpLabel(canvas, labelOffset, progress);
    }
  }

  List<Offset> _getMountainPathPoints(double w, double h) {
    // 20 điểm từ chân → đỉnh núi, theo cạnh phải của núi
    final points = <Offset>[];
    const steps = 20;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      // Đường leo theo cạnh phải núi (từ góc phải đáy → đỉnh)
      final x = w * (0.95 - t * 0.45);
      // y theo hình dạng núi
      final y = _mountainY(t, h);
      points.add(Offset(x, y));
    }
    return points;
  }

  double _mountainY(double t, double h) {
    // t=0: đáy (y = h * 0.9), t=1: đỉnh (y = h * 0.05)
    // Dùng easeIn để gần đỉnh thì dốc hơn
    final ease = t * t * (3 - 2 * t); // smoothstep
    return h * 0.90 - ease * h * 0.85;
  }

  void _drawClimber(Canvas canvas, Offset pos, double glow) {
    // Glow effect
    canvas.drawCircle(
      pos,
      14,
      Paint()
        ..color = AppColors.toriiRed.withValues(alpha: 0.3 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Climber body (circle)
    canvas.drawCircle(
      pos,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Inner dot (toriiRed)
    canvas.drawCircle(
      pos,
      5,
      Paint()..color = AppColors.toriiRed,
    );

    // Outline
    canvas.drawCircle(
      pos,
      8,
      Paint()
        ..color = AppColors.toriiRed.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawFlag(Canvas canvas, Offset pos) {
    // Pole
    canvas.drawLine(
      pos,
      Offset(pos.dx, pos.dy - 20),
      Paint()
        ..color = AppColors.goldAccent
        ..strokeWidth = 2,
    );
    // Flag
    final flagPath = Path()
      ..moveTo(pos.dx, pos.dy - 20)
      ..lineTo(pos.dx + 14, pos.dy - 15)
      ..lineTo(pos.dx, pos.dy - 10)
      ..close();
    canvas.drawPath(
      flagPath,
      Paint()..color = AppColors.toriiRed,
    );
  }

  void _drawXpLabel(Canvas canvas, Offset climberPos, double progress) {
    final pct = (progress * 100).round();
    final label = '$pct%';

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(climberPos.dx - tp.width / 2, climberPos.dy - 22),
    );
  }

  @override
  bool shouldRepaint(_MountainPainter old) =>
      old.progress != progress || old.glowOpacity != glowOpacity;
}


// ── Compact version dùng cho HomeScreen ──────────────────────────────────────

/// Version nhỏ gọn hơn để embed trong HomeScreen card.
class MountainProgressCard extends StatelessWidget {
  final int completedLessons;
  final int totalLessons;
  final String levelLabel;
  final String xpGained;
  final VoidCallback? onTap;

  const MountainProgressCard({
    super.key,
    required this.completedLessons,
    required this.totalLessons,
    required this.levelLabel,
    this.xpGained = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MountainProgressWidget(
      completedLessons: completedLessons,
      totalLessons: totalLessons,
      levelLabel: levelLabel,
      animate: true,
      onTap: onTap,
    );
  }
}
