import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';

class RoadmapHeader extends StatelessWidget {
  final String title;
  final double progress;
  final int completed;
  final int total;
  final String? levelBadge;

  const RoadmapHeader({
    super.key,
    required this.title,
    required this.progress,
    required this.completed,
    required this.total,
    this.levelBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (levelBadge != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: SNJ.sakuraSoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: SNJ.borderNeon, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: SNJ.sakura.withOpacity(0.15),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: Text(
                            levelBadge!,
                            style: const TextStyle(
                              color: SNJ.sakura,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.landscape_rounded,
                        color: Color(0xFFCCB8D8),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Mount Fuji · Station $completed',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFCCB8D8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tiến độ leo núi card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: GlassCard(
                neonBorder: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              color: SNJ.sakura,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'TIẾN ĐỘ LEO NÚI',
                              style: TextStyle(
                                color: SNJ.sakura,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        // Track
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Fill
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: SNJ.sakuraGradient,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: SNJ.sakura.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}