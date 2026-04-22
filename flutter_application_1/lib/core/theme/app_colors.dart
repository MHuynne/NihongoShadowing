import 'package:flutter/material.dart';

class AppColors {
  // ── Japanese Torii Red — Core Theme ──────────────────────────────────────
  static const Color toriiRed      = Color(0xFFBC2428); // Đỏ Torii Gate chính
  static const Color toriiRedLight = Color(0xFFE8534A); // Đỏ nhạt hơn
  static const Color inkBlack      = Color(0xFF1A1A2E); // Mực đen sâu (nền tối)
  static const Color inkDeep       = Color(0xFF12121F); // Nền tối nhất
  static const Color washi         = Color(0xFFF5F0E8); // Giấy washi (nền sáng)
  static const Color washiLight    = Color(0xFFFCFAF7); // Giấy nhạt nhất
  static const Color matcha        = Color(0xFF5B8A5F); // Xanh matcha
  static const Color matchaLight   = Color(0xFFD4EDDA); // Xanh matcha nhạt
  static const Color goldAccent    = Color(0xFFD4A843); // Vàng accent
  static const Color goldLight     = Color(0xFFFFF3CD); // Vàng nhạt

  // ── Backward-compatible aliases (giữ nguyên để không phá code cũ) ────────
  static const Color primary            = toriiRed;
  static const Color backgroundLight    = washi;
  static const Color backgroundDark     = inkBlack;
  static const Color sunRed             = toriiRed;
  static const Color progressTeal       = matcha;
  static const Color lightTealGreen     = matchaLight;
  static const Color sakuraPink         = Color(0xFFFFB7C5);
  static const Color buttonYellow       = goldAccent;
  static const Color itemBackground     = Color(0xFFFFFFFF);
  static const Color surfaceBackground  = washiLight;
  static const Color textDark           = Color(0xFF1E293B);
  static const Color textLight          = Color(0xFF64748B);
  static const Color lightBlueBackground   = Color(0xFFE6EFFF);
  static const Color lightPinkBackground   = Color(0xFFFFEAEB);
  static const Color lightPurpleBackground = Color(0xFFF3E8FF);

  // ── Neutral Slate Scale ──────────────────────────────────────────────────
  static const Color slate50  = Color(0xFFf8fafc);
  static const Color slate100 = Color(0xFFf1f5f9);
  static const Color slate200 = Color(0xFFe2e8f0);
  static const Color slate300 = Color(0xFFcbd5e1);
  static const Color slate400 = Color(0xFF94a3b8);
  static const Color slate500 = Color(0xFF64748b);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1e293b);
  static const Color slate900 = Color(0xFF0f172a);

  // ── Semantic Colors ───────────────────────────────────────────────────────
  static const Color successGreen      = Color(0xFF10B981);
  static const Color successGreenLight = Color(0xFFD1FAE5);
  static const Color errorRed          = Color(0xFFEF4444);
  static const Color warningYellow     = Color(0xFFF59E0B);
}
