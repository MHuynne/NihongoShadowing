import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1325ec);
  static const Color backgroundLight = Color(0xFFf6f6f8);
  static const Color backgroundDark = Color(0xFF101222);
  static const Color surfaceDark = Color(0xFF171B2E);
  static const Color elevatedSurfaceDark = Color(0xFF1D2338);
  static const Color borderDark = Color(0xFF2B344E);

  static const Color slate50 = Color(0xFFf8fafc);
  static const Color slate100 = Color(0xFFf1f5f9);
  static const Color slate200 = Color(0xFFe2e8f0);
  static const Color slate300 = Color(0xFFcbd5e1);
  static const Color slate400 = Color(0xFF94a3b8);
  static const Color slate500 = Color(0xFF64748b);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1e293b);
  static const Color slate900 = Color(0xFF0f172a);

  // Custom Project Colors
  static const Color sunRed = Color(0xFFE53935);
  static const Color sakuraPink = Color(0xFFFFB7C5);
  static const Color progressTeal = Color(0xFF38A3A5);
  static const Color buttonYellow = Color(0xFFE9C46A);
  static const Color itemBackground = Color(0xFFFFFFFF);
  static const Color surfaceBackground = Color(0xFFFCFCFC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color lightTealGreen = Color(0xFFD3F2E7);
  static const Color lightBlueBackground = Color(0xFFE6EFFF);
  static const Color lightPinkBackground = Color(0xFFFFEAEB);
  static const Color lightPurpleBackground = Color(0xFFF3E8FF);

  // Aliases used by the main branch screens.
  static const Color toriiRed = sunRed;
  static const Color toriiRedLight = Color(0xFFE8534A);
  static const Color matcha = progressTeal;
  static const Color matchaLight = lightTealGreen;
  static const Color goldAccent = buttonYellow;
  static const Color goldLight = Color(0xFFFFF3CD);
  static const Color inkBlack = backgroundDark;
  static const Color inkDeep = Color(0xFF12121F);
  static const Color washi = backgroundLight;
  static const Color washiLight = surfaceBackground;

  // Shadowing specific
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenLight = Color(0xFFD1FAE5);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningYellow = Color(0xFFF59E0B);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffoldBackground(BuildContext context) =>
      isDark(context) ? backgroundDark : backgroundLight;

  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceDark : itemBackground;

  static Color elevatedSurface(BuildContext context) =>
      isDark(context) ? elevatedSurfaceDark : surfaceBackground;

  static Color inputFill(BuildContext context) =>
      isDark(context) ? elevatedSurfaceDark : slate50;

  static Color border(BuildContext context) =>
      isDark(context) ? borderDark : slate200;

  static Color divider(BuildContext context) =>
      isDark(context) ? borderDark : slate100;

  static Color primaryText(BuildContext context) =>
      isDark(context) ? slate100 : textDark;

  static Color secondaryText(BuildContext context) =>
      isDark(context) ? slate400 : slate500;

  static Color tertiaryText(BuildContext context) =>
      isDark(context) ? slate500 : slate400;

  static Color softAccentSurface(BuildContext context, Color accent) =>
      isDark(context) ? accent.withOpacity(0.18) : accent.withOpacity(0.10);

  static Color shadow(BuildContext context, {double opacity = 0.05}) =>
      Colors.black.withOpacity(isDark(context) ? opacity * 4 : opacity);
}
