import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

class AdminPalette {
  static const Color scaffold = AppColors.washi;
  static const Color surface = AppColors.itemBackground;
  static const Color surfaceMuted = AppColors.surfaceBackground;
  static const Color border = AppColors.slate200;
  static const Color borderSoft = AppColors.slate100;

  static const Color sidebar = AppColors.inkBlack;
  static const Color sidebarSurface = AppColors.surfaceDark;
  static const Color sidebarBorder = AppColors.borderDark;
  static const Color sidebarMuted = AppColors.slate400;
  static const Color sidebarSelectedBackground = AppColors.lightBlueBackground;
  static const Color sidebarSelectedForeground = AppColors.primary;

  static const Color pillBackground = AppColors.lightBlueBackground;
  static const Color pillForeground = AppColors.primary;

  static const Color lessonAccent = AppColors.toriiRed;
  static const Color lessonSurface = AppColors.lightPinkBackground;
  static const Color topicAccent = AppColors.primary;
  static const Color topicSurface = AppColors.lightBlueBackground;
  static const Color vocabularyAccent = AppColors.progressTeal;
  static const Color vocabularySurface = AppColors.lightTealGreen;
  static const Color roleplayAccent = AppColors.sunRed;
  static const Color roleplaySurface = AppColors.goldLight;
  static const Color neutralAccent = AppColors.slate700;
  static const Color neutralSurface = AppColors.slate100;
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
            color: AppColors.primary.withValues(alpha: 0.04),
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
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slate500,
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
        backgroundColor: AppColors.primary,
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
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}
