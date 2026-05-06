import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItemData(Icons.home_outlined, Icons.home_rounded, 'Trang chủ'),
    _NavItemData(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Lộ trình'),
    _NavItemData(Icons.record_voice_over_outlined,
        Icons.record_voice_over_rounded, 'Shadowing'),
    _NavItemData(
        Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat'),
    _NavItemData(Icons.person_outline_rounded, Icons.person_rounded, 'Hồ sơ'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface(context).withValues(
                alpha: isDark ? 0.92 : 0.98,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppColors.border(context).withValues(alpha: 0.65),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow(context, opacity: 0.10),
                  blurRadius: 26,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 82,
                child: Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: _BottomNavItem(
                          data: _items[i],
                          isSelected: currentIndex == i,
                          showBadge: i == 3,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final bool showBadge;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.data,
    required this.isSelected,
    required this.showBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: isSelected ? 1 : 0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final inactiveColor =
            AppColors.isDark(context) ? AppColors.slate400 : AppColors.slate400;
        final iconColor = Color.lerp(inactiveColor, Colors.white, value)!;
        final labelColor =
            Color.lerp(inactiveColor, AppColors.toriiRed, value)!;
        final iconSize = lerpDouble(23, 28, value)!;
        final bubbleSize = lerpDouble(36, 54, value)!;
        final top = lerpDouble(10, 0, value)!;
        final labelBottom = lerpDouble(10, 7, value)!;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 82,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: top,
                    child: _IconBubble(
                      icon: isSelected ? data.selectedIcon : data.icon,
                      iconColor: iconColor,
                      iconSize: iconSize,
                      size: bubbleSize,
                      selectedProgress: value,
                      showBadge: showBadge && !isSelected,
                    ),
                  ),
                  Positioned(
                    bottom: labelBottom,
                    left: 2,
                    right: 2,
                    child: Text(
                      data.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final double size;
  final double selectedProgress;
  final bool showBadge;

  const _IconBubble({
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.size,
    required this.selectedProgress,
    required this.showBadge,
  });

  @override
  Widget build(BuildContext context) {
    final background = Color.lerp(
      Colors.transparent,
      AppColors.toriiRed,
      selectedProgress,
    )!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            boxShadow: selectedProgress > 0.05
                ? [
                    BoxShadow(
                      color: AppColors.toriiRed.withValues(
                        alpha: 0.28 * selectedProgress,
                      ),
                      blurRadius: 22 * selectedProgress,
                      spreadRadius: 2 * selectedProgress,
                      offset: Offset(0, 9 * selectedProgress),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
        if (showBadge)
          Positioned(
            right: 5,
            top: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.toriiRed,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface(context),
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItemData(this.icon, this.selectedIcon, this.label);
}
