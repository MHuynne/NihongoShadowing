import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';
import 'package:flutter_application_1/features/roleplay/screens/scenario_selection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Japanese Learning App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Will switch based on system dark/light mode
      // Tạm thời Load màn hình Roleplay lên trước để bạn test UI
      home: const ScenarioSelectionScreen(),
    );
  }
}
