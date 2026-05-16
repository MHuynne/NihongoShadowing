import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/presentation/components/main_bottom_nav_bar.dart';
import 'package:flutter_application_1/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/roadmap_screen.dart';
import 'package:flutter_application_1/features/shadowing/presentation/screens/shadowing_topic_list_screen.dart';
import 'package:flutter_application_1/features/kingo_chat/presentation/screens/kingo_chat_screen.dart';
import 'package:flutter_application_1/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter_application_1/features/roleplay/screens/scenario_selection_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  /// Gọi từ LessonSummaryScreen sau khi hoàn thành bài để force-refresh RoadmapScreen
  static void refreshRoadmap(BuildContext context) {
    final state = context.findAncestorStateOfType<_MainScreenState>();
    state?._forceRefreshRoadmap();
  }

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainScreenState>();
    if (state != null) {
      state._onTabTapped(index);
    }
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  // Tăng key này để force rebuild RoadmapScreen sau khi hoàn thành bài
  int _roadmapRefreshKey = 0;

  final _homeScreen = const HomeScreen();
  final _shadowingScreen = const ShadowingTopicListScreen();
  final _chatScreen = const ScenarioSelectionScreen();
  final _profileScreen = const ProfileScreen();

  void _forceRefreshRoadmap() {
    setState(() {
      _currentIndex = 1; // Chuyển sang tab Roadmap
      _roadmapRefreshKey++; // Đổi key → AnimatedSwitcher rebuild RoadmapScreen
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _homeScreen;
      case 1: // Key thay đổi mỗi khi hoàn thành bài → RoadmapScreen.initState() chạy lại
        return RoadmapScreen(key: ValueKey('roadmap_$_roadmapRefreshKey'));
      case 2:
        return _shadowingScreen;
      case 3:
        return _chatScreen;
      case 4:
        return _profileScreen;
      default:
        return _homeScreen;
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey('${_currentIndex}_$_roadmapRefreshKey'),
          child: _buildCurrentScreen(),
        ),
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
