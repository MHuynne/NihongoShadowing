import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/presentation/components/main_bottom_nav_bar.dart';
import 'package:flutter_application_1/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/roadmap_screen.dart';
import 'package:flutter_application_1/features/shadowing/presentation/screens/shadowing_topic_list_screen.dart';
import 'package:flutter_application_1/features/roleplay/screens/scenario_selection_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RoadmapScreen(),
    const ShadowingTopicListScreen(),
    const ScenarioSelectionScreen(),
    const Center(child: Text('Tài khoản')), // Placeholder
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
