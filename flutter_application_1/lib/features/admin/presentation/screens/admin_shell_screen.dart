import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/pages/admin_dashboard_page.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/pages/admin_lessons_page.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/pages/admin_roleplay_page.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/pages/admin_topics_page.dart';
import 'package:flutter_application_1/features/admin/presentation/screens/pages/admin_vocabularies_page.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

enum AdminSection {
  dashboard,
  lessons,
  vocabularies,
  topics,
  roleplay,
}

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  final AdminApiService _api = AdminApiService();
  AdminSection _section = AdminSection.dashboard;

  @override
  Widget build(BuildContext context) {
    final title = switch (_section) {
      AdminSection.dashboard => 'Admin Dashboard',
      AdminSection.lessons => 'Quan ly bai hoc',
      AdminSection.vocabularies => 'Quan ly tu vung',
      AdminSection.topics => 'Quan ly shadowing',
      AdminSection.roleplay => 'Quan ly roleplay',
    };

    return Scaffold(
      backgroundColor: AdminPalette.scaffold,
      body: Row(
        children: [
          _AdminSidebar(
            current: _section,
            onChanged: (section) => setState(() => _section = section),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: const BoxDecoration(
                    color: AdminPalette.surface,
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
                                color: AppColors.textDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ket noi truc tiep FastAPI + MySQL Laragon',
                              style: const TextStyle(
                                color: AppColors.slate500,
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
                          border: Border.all(color: AdminPalette.borderSoft),
                        ),
                        child: const Text(
                          'WEB ADMIN',
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
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case AdminSection.dashboard:
        return AdminDashboardPage(api: _api);
      case AdminSection.lessons:
        return AdminLessonsPage(api: _api);
      case AdminSection.vocabularies:
        return AdminVocabulariesPage(api: _api);
      case AdminSection.topics:
        return AdminTopicsPage(api: _api);
      case AdminSection.roleplay:
        return AdminRoleplayPage(api: _api);
    }
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.current,
    required this.onChanged,
  });

  final AdminSection current;
  final ValueChanged<AdminSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      color: AdminPalette.sidebar,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.toriiRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TokyoNihongo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Content administration',
            style: TextStyle(
              color: AdminPalette.sidebarMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          _SidebarItem(
            label: 'Tong quan',
            icon: Icons.dashboard_rounded,
            selected: current == AdminSection.dashboard,
            onTap: () => onChanged(AdminSection.dashboard),
          ),
          _SidebarItem(
            label: 'Bai hoc',
            icon: Icons.menu_book_rounded,
            selected: current == AdminSection.lessons,
            onTap: () => onChanged(AdminSection.lessons),
          ),
          _SidebarItem(
            label: 'Tu vung',
            icon: Icons.translate_rounded,
            selected: current == AdminSection.vocabularies,
            onTap: () => onChanged(AdminSection.vocabularies),
          ),
          _SidebarItem(
            label: 'Shadowing',
            icon: Icons.graphic_eq_rounded,
            selected: current == AdminSection.topics,
            onTap: () => onChanged(AdminSection.topics),
          ),
          _SidebarItem(
            label: 'Roleplay',
            icon: Icons.forum_rounded,
            selected: current == AdminSection.roleplay,
            onTap: () => onChanged(AdminSection.roleplay),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminPalette.sidebarSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AdminPalette.sidebarBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_done_rounded,
                      size: 18,
                      color: AppColors.progressTeal,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Laragon + FastAPI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Trang admin nay duoc canh mau theo app chinh va noi truc tiep den du lieu MySQL qua backend FastAPI.',
                  style: TextStyle(
                    color: AdminPalette.sidebarMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? AdminPalette.sidebarSelectedBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? AdminPalette.sidebarSelectedForeground
                      : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AdminPalette.sidebarSelectedForeground
                        : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
