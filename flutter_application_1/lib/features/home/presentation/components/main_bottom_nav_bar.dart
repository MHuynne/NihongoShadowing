import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItemData(Icons.home_outlined,             Icons.home_rounded,               'Trang chủ'),
    _NavItemData(Icons.menu_book_outlined,         Icons.menu_book_rounded,          'Lộ trình'),
    _NavItemData(Icons.record_voice_over_outlined, Icons.record_voice_over_rounded,  'Shadowing'),
    _NavItemData(Icons.chat_bubble_outline_rounded,Icons.chat_bubble_rounded,        'Chat'),
    _NavItemData(Icons.person_outline_rounded,     Icons.person_rounded,             'Hồ sơ'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              // Dark glass — nền tím đêm bán trong suốt
              color: const Color(0xD4100825),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: SNJ.border, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
                BoxShadow(
                  color: SNJ.sakuraGlow,
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 80,
                child: Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: _NavItem(
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

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final bool showBadge;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.showBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: isSelected ? 1 : 0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final inactiveColor = SNJ.textMuted;
        final iconColor   = Color.lerp(inactiveColor, Colors.white, value)!;
        final labelColor  = Color.lerp(inactiveColor, SNJ.sakura, value)!;
        final iconSize    = lerpDouble(22, 26, value)!;
        final bubbleSize  = lerpDouble(34, 50, value)!;
        final top         = lerpDouble(10, 2, value)!;
        final labelBottom = lerpDouble(10, 6, value)!;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 80,
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
                        letterSpacing: 0.3,
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
    // Bubble: Gradient sakura khi active, transparent khi inactive
    final bgColor = Color.lerp(Colors.transparent, SNJ.sakura, selectedProgress)!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: selectedProgress > 0.05
                ? [
                    BoxShadow(
                      color: SNJ.sakura.withOpacity(0.45 * selectedProgress),
                      blurRadius: 18 * selectedProgress,
                      spreadRadius: 2 * selectedProgress,
                      offset: Offset(0, 6 * selectedProgress),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
        if (showBadge)
          Positioned(
            right: 4,
            top: 3,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: SNJ.sakura,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF100825), width: 1.5),
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