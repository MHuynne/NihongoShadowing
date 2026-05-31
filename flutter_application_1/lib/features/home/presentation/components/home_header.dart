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
          // Left: Title only
          const Text(
            'NihongoJP',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF4D6D),
              letterSpacing: -0.5,
            ),
          ),
          // Right: Profile Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: _HomeAvatar(user: user),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAvatar extends StatelessWidget {
  final UserModel user;

  const _HomeAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl.trim();
    final initials = user.name.trim().isEmpty
        ? 'U'
        : user.name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
            .join();

    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppColors.slate200,
        onBackgroundImageError: (_, __) {},
        child: const SizedBox.shrink(),
      );
    }

    return CircleAvatar(
      backgroundColor: AppColors.lightPinkBackground,
      child: Text(
        initials.isEmpty ? 'U' : initials,
        style: const TextStyle(
          color: Color(0xFFFF4D6D),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
