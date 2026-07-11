import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/home/models/user_model.dart';

class HomeHeader extends StatelessWidget {
  final UserModel user;

  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          const Text(
            'NihongoJP',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF4D6D),
              letterSpacing: -0.5,
            ),
          ),

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: ClipOval(
                child: user.avatarUrl.isNotEmpty
                    ? Image.network(
                        user.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackAvatar(user.name);
                        },
                      )
                    : _buildFallbackAvatar(user.name),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    final cleanName = name.trim();
    final String initial = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : 'U';
    return Container(
      color: const Color(0xFFFF4D6D),
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