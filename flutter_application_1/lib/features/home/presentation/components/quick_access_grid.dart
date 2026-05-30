import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';
import 'package:flutter_application_1/features/dictionary/presentation/screens/dictionary_screen.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildGridItem(
                  context: context,
                  icon: Icons.map_rounded,
                  title: 'Lộ trình học',
                  onTap: () => MainScreen.switchTab(context, 1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGridItem(
                  context: context,
                  icon: Icons.menu_book_rounded,
                  title: 'Từ điển',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DictionaryScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGridItem(
                  context: context,
                  icon: Icons.graphic_eq_rounded,
                  title: 'Shadowing',
                  onTap: () => MainScreen.switchTab(context, 2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGridItem(
                  context: context,
                  icon: Icons.record_voice_over_rounded,
                  title: 'Roleplay',
                  onTap: () => MainScreen.switchTab(context, 3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    BuildContext? context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFFFF4D6D), size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

