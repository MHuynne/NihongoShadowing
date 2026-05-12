import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

class AdminPalette {
  static const Color scaffold = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1B1B2F);
  static const Color surfaceMuted = Color(0xFF262640);
  static const Color border = Color(0xFF383854);
  static const Color borderSoft = Color(0xFF2E2E48);

  static const Color sidebar = Color(0xFF0B0B14);
  static const Color sidebarSurface = Color(0xFF161625);
  static const Color sidebarBorder = Color(0xFF222238);
  static const Color sidebarMuted = Color(0xFF8B8BA7);
  static const Color sidebarSelectedBackground = Color(0x334D4DFF);
  static const Color sidebarSelectedForeground = Color(0xFF8A8AFF);

  static const Color pillBackground = Color(0x33B200FF);
  static const Color pillForeground = Color(0xFFD466FF);

  static const Color lessonAccent = Color(0xFFFF007F);
  static const Color lessonSurface = Color(0x33FF007F);
  static const Color topicAccent = Color(0xFF00F0FF);
  static const Color topicSurface = Color(0x3300F0FF);
  static const Color vocabularyAccent = Color(0xFFB200FF);
  static const Color vocabularySurface = Color(0x33B200FF);
  static const Color roleplayAccent = Color(0xFFFFD700);
  static const Color roleplaySurface = Color(0x33FFD700);
  static const Color neutralAccent = Color(0xFF8B8BA7);
  static const Color neutralSurface = Color(0x338B8BA7);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8B8BA7);
  static const Color textMuted = Color(0xFFA0A0B8);
  static const Color errorRed = Color(0xFFFF3366);
}

class AdminSurface extends StatelessWidget {
  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminPalette.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: padding,
      child: child,
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
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
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
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AdminPalette.sidebarSelectedForeground,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon ?? Icons.add_rounded, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AdminPalette.topicSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 30,
              color: AdminPalette.topicAccent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
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
    );
  }
}
