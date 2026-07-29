import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// 🌸 Sakura Night Journey — Design System
/// Dùng cho toàn bộ màn hình người dùng (Home, Roadmap, Shadowing, ...)
class SNJ {
  // ── Nền chính ──────────────────────────────────────────────────────────────
  static const Color bgDeep   = Color(0xFF0D0720); // Đêm tím thẳm
  static const Color bgMid    = Color(0xFF13082A); // Tím đêm ấm
  static const Color bgLight  = Color(0xFF1E0F38); // Tím nhạt hơn

  // ── Accent & Gradient ──────────────────────────────────────────────────────
  static const Color sakura       = Color(0xFFFF6B9D); // Sakura Coral chính
  static const Color sakuraDark   = Color(0xFFE0407A);
  static const Color sakuraGlow   = Color(0x33FF6B9D); // Glow sakura
  static const Color sakuraSoft   = Color(0x1AFF6B9D); // Nền nhẹ sakura

  static const LinearGradient sakuraGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF3E73)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Card / Surface ─────────────────────────────────────────────────────────
  static const Color surface     = Color(0x1AFFFFFF); // Glass surface
  static const Color surfaceHigh = Color(0x26FFFFFF); // Glass elevated
  static const Color border      = Color(0x1AFFFFFF); // Glass border nhẹ
  static const Color borderNeon  = Color(0x33FF6B9D); // Neon border coral

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Color(0xFFCCB8D8); // Tím nhạt dễ đọc
  static const Color textMuted     = Color(0xFF8877A0);

  // ── Quick Access Gradient per feature ─────────────────────────────────────
  static const LinearGradient roadmapGrad = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient dictionaryGrad = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient shadowingGrad = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient roleplayGrad = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Background gradient ────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [bgDeep, bgMid, bgLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );
}

/// Hạt sakura rơi — dùng lại logic từ Admin nhưng bảng màu ấm hơn
class SakuraNightBackground extends StatefulWidget {
  const SakuraNightBackground({super.key, required this.child});
  final Widget child;

  @override
  State<SakuraNightBackground> createState() => _SakuraNightBgState();
}

class _SakuraNightBgState extends State<SakuraNightBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Petal> _petals = List.generate(35, (_) => _Petal.random());

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        for (var p in _petals) p.update();
        return CustomPaint(
          painter: _BgPainter(_petals),
          child: widget.child,
        );
      },
    );
  }
}

class _Petal {
  double x = 0, y = 0, size = 0, speedY = 0, speedX = 0;
  double opacity = 0, maxOpacity = 0, waveOffset = 0;

  _Petal.random() { reset(randomY: true); }

  void reset({bool randomY = false}) {
    final r = math.Random();
    x = r.nextDouble();
    y = randomY ? r.nextDouble() : 1.0;
    size = r.nextDouble() * 2.5 + 1.0;
    speedY = -(r.nextDouble() * 0.0008 + 0.0002);
    speedX = (r.nextDouble() - 0.5) * 0.0003;
    maxOpacity = r.nextDouble() * 0.45 + 0.15;
    opacity = randomY ? r.nextDouble() * maxOpacity : 0.0;
    waveOffset = r.nextDouble() * math.pi * 2;
  }

  void update() {
    y += speedY;
    x += speedX + math.sin(y * 6 + waveOffset) * 0.0002;
    if (y < 0.2) opacity = (y / 0.2) * maxOpacity;
    else if (opacity < maxOpacity) opacity += 0.008;
    if (y < 0 || x < -0.1 || x > 1.1) reset();
  }
}

class _BgPainter extends CustomPainter {
  _BgPainter(this.petals);
  final List<_Petal> petals;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Offset.zero & size;

    // 1. Gradient nền chính
    paint.shader = const LinearGradient(
      colors: [Color(0xFF0D0720), Color(0xFF13082A), Color(0xFF1E0F38)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0.0, 0.5, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;

    // 2. Aura orbs mềm
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    // Sakura pink aura bottom-right
    glow.color = const Color(0x18FF6B9D);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.8), 240, glow);

    // Violet aura top-left
    glow.color = const Color(0x12A855F7);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 280, glow);

    // Deep blue aura center
    glow.color = const Color(0x0E4F46E5);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 300, glow);

    // 3. Sakura petals rơi
    for (var p in petals) {
      final pos = Offset(p.x * size.width, p.y * size.height);

      // Glow
      final pg = Paint()
        ..color = const Color(0xFFFF6B9D).withOpacity(p.opacity * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(pos, p.size * 1.8, pg);

      // Solid
      canvas.drawCircle(
        pos, p.size,
        Paint()..color = Colors.white.withOpacity(p.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => true;
}

/// Glass card widget tái dùng cho toàn bộ màn hình user
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24.0,
    this.neonBorder = false,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool neonBorder;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: neonBorder
            ? [BoxShadow(color: SNJ.sakuraGlow, blurRadius: 20, offset: const Offset(0, 6))]
            : [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: SNJ.surface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: neonBorder ? SNJ.borderNeon : SNJ.border,
                width: neonBorder ? 1.2 : 0.8,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
