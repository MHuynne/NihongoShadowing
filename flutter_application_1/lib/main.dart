import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/admin_shell_screen.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool get _isAdminRoute {
    if (!kIsWeb) return false;

    final path = Uri.base.path.toLowerCase();
    final fragment = Uri.base.fragment.toLowerCase();
    final adminQuery = Uri.base.queryParameters['admin'];

    return path == '/admin' ||
        path.endsWith('/admin') ||
        fragment == 'admin' ||
        fragment == '/admin' ||
        adminQuery == '1' ||
        adminQuery == 'true';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TokyoNihongo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: _isAdminRoute ? const AdminShellScreen() : const AuthGate(),
    );
  }
}
