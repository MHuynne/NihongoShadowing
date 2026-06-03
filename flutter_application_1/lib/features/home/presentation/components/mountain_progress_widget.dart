import 'package:flutter/material.dart';

class MountainProgressWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final double progress =
        totalLessons > 0 ? completedLessons / totalLessons : 0;
    final int pct = (progress * 100).round();

    // Map level to Japanese traditional trail names or milestones
    String trailName = 'Gotemba Trail';
    String levelJapanese = '富士山';
    if (levelLabel == 'N5') {
      trailName = 'Yoshida Trail (Sơ cấp)';
      levelJapanese = '五合目 (Trạm 5)';
    } else if (levelLabel == 'N4') {
      trailName = 'Subashiri Trail (Trung cấp)';
      levelJapanese = '六合目 (Trạm 6)';
    } else if (levelLabel == 'N3') {
      trailName = 'Gotemba Trail (Cao cấp)';
      levelJapanese = '七合目 (Trạm 7)';
    } else if (levelLabel == 'N2') {
      trailName = 'Fujinomiya Trail (Thượng cấp)';
      levelJapanese = '八合目 (Trạm 8)';
    } else if (levelLabel == 'N1') {
      trailName = 'Summit Peak (Bản xứ)';
      levelJapanese = '剣ヶ峰 (Đỉnh Fuji)';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 175,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Midnight Dark
              Color(0xFF1E1B4B), // Deep Indigo
              Color(0xFF311042), // Dark Sunset Violet
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFFF4D6D).withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Stylized Mt. Fuji Silhouette in the background (Custom Paint)
              Positioned(
                bottom: -20,
                right: -40,
                width: 260,
                height: 180,
                child: Opacity(
                  opacity: 0.15,
                  child: CustomPaint(
                    painter: FujiPainter(
                      mountainColor: const Color(0xFF94A3B8),
                      snowCapColor: Colors.white,
                    ),
                  ),
                ),
              ),

              // Decorative Sun glow in background
              Positioned(
                top: -30,
                right: 30,
                width: 120,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF4D6D).withOpacity(0.3),
                        const Color(0xFFFF4D6D).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Layout
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    // Left Text Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Top Header Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.terrain_rounded,
                                      color: Color(0xFFFF4D6D),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      levelJapanese,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Goal / Level Title
                          Text(
                            '$levelLabel Mastery',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Subtitle (Trail)
                          Text(
                            trailName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),

                          // Station progress pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4D6D),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF4D6D).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              'Bài $completedLessons / $totalLessons',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Progress Circle
                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Circular Outer Glow
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF4D6D).withOpacity(0.15),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),

                          // Circular Track Background
                          SizedBox(
                            width: 76,
                            height: 76,
                            child: CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 7,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ),

                          // Value Indicator
                          SizedBox(
                            width: 76,
                            height: 76,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 7,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF4D6D),
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),

                          // Text Info
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$pct',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withOpacity(0.7),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

/// Custom Painter for drawing a clean, minimalist silhouette of Mount Fuji.
class FujiPainter extends CustomPainter {
  final Color mountainColor;
  final Color snowCapColor;

  FujiPainter({
    required this.mountainColor,
    required this.snowCapColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = mountainColor
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Draw Mt Fuji Silhouette
    final path = Path();
    path.moveTo(0, h);
    path.cubicTo(w * 0.25, h * 0.95, w * 0.40, h * 0.22, w * 0.45, h * 0.15);
    path.lineTo(w * 0.55, h * 0.15);
    path.cubicTo(w * 0.60, h * 0.22, w * 0.75, h * 0.95, w, h);
    path.close();
    canvas.drawPath(path, paint);

    // Draw Snow Cap
    final capPaint = Paint()
      ..color = snowCapColor
      ..style = PaintingStyle.fill;

    final capPath = Path();
    capPath.moveTo(w * 0.45, h * 0.15);
    capPath.lineTo(w * 0.55, h * 0.15);

    // Top right of slope cap
    capPath.cubicTo(w * 0.57, h * 0.25, w * 0.54, h * 0.32, w * 0.51, h * 0.38);
    // Wavy edge of snow cap
    capPath.quadraticBezierTo(w * 0.5, h * 0.32, w * 0.49, h * 0.38);
    capPath.cubicTo(w * 0.46, h * 0.32, w * 0.43, h * 0.25, w * 0.45, h * 0.15);
    capPath.close();
    canvas.drawPath(capPath, capPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
