import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/auth/presentation/screens/auth_gate.dart';
import 'firebase_options.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';
import 'package:flutter_application_1/features/roleplay/screens/scenario_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TokyoNihongo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(), // ← Auth Gate thay thế MainScreen trực tiếp
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Will switch based on system dark/light mode
      // Tạm thời Load màn hình Roleplay lên trước để bạn test UI
      home: const ScenarioSelectionScreen(),
    );
  }
}
