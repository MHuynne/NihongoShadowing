import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/pages/admin_dashboard_page.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/pages/admin_lessons_page.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/pages/admin_roleplay_page.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/pages/admin_segments_page.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/pages/admin_topics_page.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/pages/admin_vocabularies_page.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

enum AdminSection {
  dashboard,
  lessons,
  vocabularies,
  topics,
  segments,
  roleplay
}

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  final AdminApiService _api = AdminApiService();
  AdminSection _section = AdminSection.dashboard;
  int? _initialLessonIdForVocab;
  int? _initialLessonIdForTopic;

  void _navigateToVocab(int lessonId) {
    setState(() {
      _initialLessonIdForVocab = lessonId;
      _section = AdminSection.vocabularies;
    });
  }

  void _navigateToTopic(int lessonId) {
    setState(() {
      _initialLessonIdForTopic = lessonId;
      _section = AdminSection.topics;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_section) {
      AdminSection.dashboard => 'Tổng quan Admin',
      AdminSection.lessons => 'Lộ trình bài học',
      AdminSection.vocabularies => 'Quản lý từ vựng',
      AdminSection.topics => 'Chủ đề Shadowing',
      AdminSection.segments => 'Phân đoạn & Danh mục',
      AdminSection.roleplay => 'Quản lý Roleplay',
    };

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: AdminPalette.sidebarSelectedForeground,
          surface: AdminPalette.surface,
        ),
        cardColor: AdminPalette.surface,
        dialogBackgroundColor: AdminPalette.surfaceMuted,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: TokyoZenBackground(
          child: Row(
            children: [
              _AdminSidebar(
                current: _section,
                onChanged: (section) {
                  setState(() {
                    _section = section;
                    if (section == AdminSection.vocabularies) {
                      _initialLessonIdForVocab = null;
                    }
                    if (section == AdminSection.topics) {
                      _initialLessonIdForTopic = null;
                    }
                  });
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 76,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        border: Border(
                          bottom: BorderSide(color: AdminPalette.borderSoft),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: AdminPalette.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kết nối trực tiếp FastAPI + MySQL Laragon',
                                  style: const TextStyle(
                                    color: AdminPalette.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AdminPalette.pillBackground,
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: AdminPalette.borderSoft),
                            ),
                            child: const Text(
                              'QUẢN TRỊ VIÊN',
                              style: TextStyle(
                                color: AdminPalette.pillForeground,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildSection(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case AdminSection.dashboard:
        return AdminDashboardPage(api: _api);
      case AdminSection.lessons:
        return AdminLessonsPage(
          api: _api,
          onNavigateToVocab: _navigateToVocab,
          onNavigateToTopic: _navigateToTopic,
        );
      case AdminSection.vocabularies:
        return AdminVocabulariesPage(
          api: _api,
          initialLessonId: _initialLessonIdForVocab,
        );
      case AdminSection.topics:
        return AdminTopicsPage(
          api: _api,
          initialLessonId: _initialLessonIdForTopic,
        );
      case AdminSection.segments:
        return AdminSegmentsPage(api: _api);
      case AdminSection.roleplay:
        return AdminRoleplayPage(api: _api);
    }
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.current, required this.onChanged});

  final AdminSection current;
  final ValueChanged<AdminSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.fromLTRB(20, 20, 0, 20),
      decoration: BoxDecoration(
        color: AdminPalette.sidebar,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdminPalette.sidebarBorder, width: 0.8),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AdminPalette.lessonAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'TokyoNihongo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Quản trị nội dung',
              style: TextStyle(
                color: AdminPalette.sidebarMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _SidebarItem(
            label: 'Tổng quan',
            icon: Icons.dashboard_rounded,
            selected: current == AdminSection.dashboard,
            onTap: () => onChanged(AdminSection.dashboard),
          ),
          _SidebarItem(
            label: 'Lộ trình bài học',
            icon: Icons.menu_book_rounded,
            selected: current == AdminSection.lessons,
            onTap: () => onChanged(AdminSection.lessons),
          ),
          _SidebarItem(
            label: 'Từ vựng',
            icon: Icons.translate_rounded,
            selected: current == AdminSection.vocabularies,
            onTap: () => onChanged(AdminSection.vocabularies),
          ),
          _SidebarItem(
            label: 'Chủ đề Shadowing',
            icon: Icons.graphic_eq_rounded,
            selected: current == AdminSection.topics,
            onTap: () => onChanged(AdminSection.topics),
          ),
          _SidebarItem(
            label: 'Phân đoạn & Danh mục',
            icon: Icons.label_rounded,
            selected: current == AdminSection.segments,
            onTap: () => onChanged(AdminSection.segments),
          ),
          _SidebarItem(
            label: 'Quản lý Roleplay',
            icon: Icons.forum_rounded,
            selected: current == AdminSection.roleplay,
            onTap: () => onChanged(AdminSection.roleplay),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AdminPalette.sidebarSurface,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: AdminPalette.sidebarBorder, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_done_rounded,
                          size: 16,
                          color: AdminPalette.topicAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Laragon + FastAPI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Trang admin này được phối màu theo ứng dụng chính và kết nối trực tiếp đến dữ liệu MySQL qua backend FastAPI.',
                      style: TextStyle(
                        color: AdminPalette.sidebarMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? AdminPalette.sidebarSelectedBackground
              : Colors.transparent,
          border: Border.all(
            color: selected ? AdminPalette.borderSoft : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? AdminPalette.sidebarSelectedForeground
                        : AdminPalette.sidebarMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color:
                            selected ? Colors.white : AdminPalette.sidebarMuted,
                        fontSize: 13.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AdminPalette.sidebarSelectedForeground,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
