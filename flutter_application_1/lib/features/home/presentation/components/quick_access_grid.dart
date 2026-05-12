import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';

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
                  icon: Icons.style_rounded, // Flashcards icon
                  title: 'Flashcards',
                  onTap: () {}, // Can be implemented later
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGridItem(
                  context: context,
                  icon: Icons.graphic_eq_rounded, // AI Shadowing
                  title: 'AI Shadowing',
                  onTap: () => MainScreen.switchTab(context, 2),
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
                  icon: Icons.record_voice_over_rounded, // Roleplay
                  title: 'Roleplay',
                  onTap: () => MainScreen.switchTab(context, 3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGridItem(
                  context: context,
                  icon: Icons.bar_chart_rounded, // Mastery Stats
                  title: 'Mastery Stats',
                  onTap: () {}, // Can be implemented later
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
              child: Icon(icon, color: const Color(0xFFFF5238), size: 24),
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

