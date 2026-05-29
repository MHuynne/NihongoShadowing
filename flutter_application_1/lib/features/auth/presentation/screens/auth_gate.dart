import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_application_1/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:flutter_application_1/features/onboarding/presentation/screens/level_selection_screen.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';
import 'package:flutter_application_1/core/services/user_prefs_service.dart';

/// AuthGate lắng nghe stream auth để tự động điều hướng.
/// - Chưa đăng nhập         → OnboardingWelcomeScreen
/// - Đã đăng nhập, chưa chọn level → LevelSelectionScreen
/// - Đã đăng nhập, đã chọn level   → MainScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Đang khởi tạo Firebase Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashView();
        }

        // Đã đăng nhập — kiểm tra đã chọn level chưa
        if (snapshot.hasData && snapshot.data != null) {
          final uid = snapshot.data!.uid;
          return FutureBuilder<bool>(
            future: UserPrefsService().hasSelectedLevel(uid),
            builder: (context, levelSnap) {
              // Đang kiểm tra SharedPreferences
              if (levelSnap.connectionState == ConnectionState.waiting) {
                return const _SplashView();
              }
              // Chưa chọn level → bắt buộc chọn trước khi vào app
              if (levelSnap.data != true) {
                return const LevelSelectionScreen(isChanging: false);
              }
              // Đã chọn level → vào MainScreen bình thường
              return const MainScreen();
            },
          );
        }

        // Chưa đăng nhập -> Hiện Onboarding đầu tiên
        return const OnboardingWelcomeScreen();
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFBC2428),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFBC2428).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🗾', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TokyoNihongo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFFBC2428),
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Color(0xFFBC2428),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
