import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class AdminPalette {
  static const Color scaffold = Color(0xFF080710); // Deep indigo black
  static const Color surface = Color(0x9E131224); // Frosted glass dark purple-charcoal
  static const Color surfaceMuted = Color(0xCC1A1A33);
  static const Color border = Color(0x338A8AFF); // Semi-transparent soft violet
  static const Color borderSoft = Color(0x1F8A8AFF); // Very soft borders

  static const Color sidebar = Color(0x8A080812); // Translucent sidebar
  static const Color sidebarSurface = Color(0x4D1B1B33);
  static const Color sidebarBorder = Color(0x1F8A8AFF);
  static const Color sidebarMuted = Color(0xFF8C8CA3);
  static const Color sidebarSelectedBackground = Color(0x267C3AED); // Tokyo Violet selection background
  static const Color sidebarSelectedForeground = Color(0xFF9D66FF); // Bright soft violet-purple

  static const Color pillBackground = Color(0x26EC4899); // Sakura Pink background
  static const Color pillForeground = Color(0xFFF472B6); // Sakura Pink foreground

  static const Color lessonAccent = Color(0xFFEC4899); // Sakura Pink
  static const Color lessonSurface = Color(0x22EC4899);
  
  static const Color topicAccent = Color(0xFF06B6D4); // Ocean Blue
  static const Color topicSurface = Color(0x2206B6D4);
  
  static const Color vocabularyAccent = Color(0xFF10B981); // Wasabi/Matcha Green
  static const Color vocabularySurface = Color(0x2210B981);
  
  static const Color roleplayAccent = Color(0xFFF59E0B); // Sunset Orange
  static const Color roleplaySurface = Color(0x22F59E0B);
  
  static const Color neutralAccent = Color(0xFF3B82F6); // Fuji Sky Blue
  static const Color neutralSurface = Color(0x223B82F6);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8C8CA3);
  static const Color textMuted = Color(0xFFA0A0B8);
  static const Color errorRed = Color(0xFFEF4444); // Shinto Red
}

class TokyoZenBackground extends StatefulWidget {
  const TokyoZenBackground({super.key, required this.child});
  final Widget child;

  @override
  State<TokyoZenBackground> createState() => _TokyoZenBackgroundState();
}

class _TokyoZenBackgroundState extends State<TokyoZenBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Particle> _particles = List.generate(40, (index) => Particle.random());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update particles
        for (var p in _particles) {
          p.update();
        }
        return CustomPaint(
          painter: _BackgroundPainter(_particles),
          child: widget.child,
        );
      },
    );
  }
}

class Particle {
  double x = 0;
  double y = 0;
  double size = 0;
  double speedY = 0;
  double speedX = 0;
  double opacity = 0;
  double maxOpacity = 0;
  double waveOffset = 0;

  Particle.random() {
    reset(randomY: true);
  }

  void reset({bool randomY = false}) {
    final rand = math.Random();
    x = rand.nextDouble();
    y = randomY ? rand.nextDouble() : 1.0;
    size = rand.nextDouble() * 3.0 + 1.0;
    speedY = -(rand.nextDouble() * 0.0010 + 0.0003);
    speedX = (rand.nextDouble() - 0.5) * 0.0004;
    maxOpacity = rand.nextDouble() * 0.35 + 0.15;
    opacity = randomY ? rand.nextDouble() * maxOpacity : 0.0;
    waveOffset = rand.nextDouble() * math.pi * 2;
  }

  void update() {
    y += speedY;
    x += speedX + math.sin(y * 8 + waveOffset) * 0.0001;
    
    // Fade in/out logic
    if (y < 0.2) {
      opacity = (y / 0.2) * maxOpacity;
    } else if (opacity < maxOpacity) {
      opacity += 0.01;
    }

    if (y < 0 || x < 0 || x > 1) {
      reset();
    }
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.particles);
  final List<Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // 1. Base dark background
    final rect = Offset.zero & size;
    final bgGradient = RadialGradient(
      center: Alignment.bottomCenter,
      radius: 1.6,
      colors: [
        const Color(0xFF130E26), // Deep warm indigo-purple bottom
        const Color(0xFF06050A), // Dark near-black top
      ],
    );
    paint.shader = bgGradient.createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;

    // 2. Large glowing aura orbs
    final glowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 130);
    
    // Pink aura bottom-right
    glowPaint.color = const Color(0x13EC4899);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.85), 260, glowPaint);

    // Cyan/Blue aura mid-left
    glowPaint.color = const Color(0x0E06B6D4);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.35), 320, glowPaint);

    // Violet aura center top
    glowPaint.color = const Color(0x0C7C3AED);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.1), 300, glowPaint);

    // 3. Subtle traditional Seigaiha waves at the bottom area
    final wavePaint = Paint()
      ..color = const Color(0x048A8AFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double waveRadius = 45.0;
    const double xSpacing = waveRadius * 2;
    const double ySpacing = waveRadius * 0.72;
    final int rows = (size.height / ySpacing).ceil() + 2;
    final int cols = (size.width / xSpacing).ceil() + 2;

    for (int r = 0; r < rows; r++) {
      // Draw waves mostly in the lower half of screen for cleanliness
      final double y = size.height - (r * ySpacing);
      final double xOffset = (r % 2) * waveRadius;
      for (int c = -1; c < cols; c++) {
        final double x = c * xSpacing + xOffset;
        final center = Offset(x, y);
        canvas.drawArc(Rect.fromCircle(center: center, radius: waveRadius), math.pi, math.pi, false, wavePaint);
        canvas.drawArc(Rect.fromCircle(center: center, radius: waveRadius * 0.65), math.pi, math.pi, false, wavePaint);
        canvas.drawArc(Rect.fromCircle(center: center, radius: waveRadius * 0.3), math.pi, math.pi, false, wavePaint);
      }
    }

    // 4. Draw floating sakura particles
    for (var p in particles) {
      final pos = Offset(p.x * size.width, p.y * size.height);
      
      // Sakura aura
      final particleGlow = Paint()
        ..color = const Color(0xFFEC4899).withOpacity(p.opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(pos, p.size * 2, particleGlow);

      // Sakura solid center
      final particlePaint = Paint()
        ..color = Colors.white.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, p.size, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => true;
}

class AdminSurface extends StatelessWidget {
  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AdminPalette.surface,
            borderRadius: br,
            border: Border.all(color: AdminPalette.borderSoft, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AdminPalette.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF8A5BFF), Color(0xFF6331DF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon ?? Icons.add_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AdminPalette.topicSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AdminPalette.borderSoft),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 32,
                color: AdminPalette.topicAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AdminPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SoundwaveVisualizer extends StatefulWidget {
  const SoundwaveVisualizer({super.key});

  @override
  State<SoundwaveVisualizer> createState() => _SoundwaveVisualizerState();
}

class _SoundwaveVisualizerState extends State<SoundwaveVisualizer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final rand = math.Random(42);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(8, (index) {
            final double phase = (index / 8.0) * math.pi * 2;
            final double value = math.sin(_controller.value * math.pi * 2 + phase);
            final double height = 4.0 + (value.abs() * 24.0) + (rand.nextDouble() * 4.0);
            return Container(
              width: 3.5,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AdminPalette.topicAccent,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        );
      },
    );
  }
}