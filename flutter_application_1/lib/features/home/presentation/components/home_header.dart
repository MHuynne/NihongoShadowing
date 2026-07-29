import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';
import 'package:flutter_application_1/features/home/models/user_model.dart';

class HomeHeader extends StatelessWidget {
  final UserModel user;
  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo với shimmer gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFFB3CC), Color(0xFFFF6B9D)],
              stops: [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: const Text(
              'NihongoJP',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white, // masked by shader
                letterSpacing: -0.8,
              ),
            ),
          ),

          // Avatar với neon ring
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: SNJ.sakuraGlow,
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: ClipOval(
                child: user.avatarUrl.isNotEmpty
                    ? Image.network(
                        user.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallback(user.name),
                      )
                    : _fallback(user.name),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}