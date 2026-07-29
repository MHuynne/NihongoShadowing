import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';
import 'package:flutter_application_1/features/dictionary/presentation/screens/dictionary_screen.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  static const _items = [
    _GridItem(
      icon: Icons.map_rounded,
      title: 'Lộ trình học',
      gradient: SNJ.roadmapGrad,
      shadowColor: Color(0xFF4F46E5),
      tabIndex: 1,
    ),
    _GridItem(
      icon: Icons.menu_book_rounded,
      title: 'Từ điển',
      gradient: SNJ.dictionaryGrad,
      shadowColor: Color(0xFF10B981),
      tabIndex: -1, // push screen
    ),
    _GridItem(
      icon: Icons.graphic_eq_rounded,
      title: 'Shadowing',
      gradient: SNJ.shadowingGrad,
      shadowColor: Color(0xFFF59E0B),
      tabIndex: 2,
    ),
    _GridItem(
      icon: Icons.record_voice_over_rounded,
      title: 'Roleplay',
      gradient: SNJ.roleplayGrad,
      shadowColor: Color(0xFFEC4899),
      tabIndex: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildCard(context, _items[0])),
              const SizedBox(width: 14),
              Expanded(child: _buildCard(context, _items[1])),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildCard(context, _items[2])),
              const SizedBox(width: 14),
              Expanded(child: _buildCard(context, _items[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, _GridItem item) {
    return _AnimatedGridCard(
      item: item,
      onTap: () {
        if (item.tabIndex == -1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DictionaryScreen()),
          );
        } else {
          MainScreen.switchTab(context, item.tabIndex);
        }
      },
    );
  }
}

class _AnimatedGridCard extends StatefulWidget {
  final _GridItem item;
  final VoidCallback onTap;
  const _AnimatedGridCard({required this.item, required this.onTap});

  @override
  State<_AnimatedGridCard> createState() => _AnimatedGridCardState();
}

class _AnimatedGridCardState extends State<_AnimatedGridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            gradient: item.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: item.shadowColor.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: item.shadowColor.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon với nền semi-transparent
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                  shadows: [
                    Shadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridItem {
  final IconData icon;
  final String title;
  final LinearGradient gradient;
  final Color shadowColor;
  final int tabIndex;

  const _GridItem({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.shadowColor,
    required this.tabIndex,
  });
}
