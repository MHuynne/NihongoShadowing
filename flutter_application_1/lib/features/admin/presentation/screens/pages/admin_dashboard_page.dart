import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.api});

  final AdminApiService api;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _overview;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final overview = await widget.api.fetchOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return AdminSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AdminPalette.lessonSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 30,
                color: AdminPalette.lessonAccent,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Khong tai duoc tong quan admin',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminPalette.textSecondary),
            ),
            const SizedBox(height: 16),
            AdminPrimaryButton(
              label: 'Thu lai',
              icon: Icons.refresh_rounded,
              onPressed: _loadOverview,
            ),
          ],
        ),
      );
    }

    final counts =
        Map<String, dynamic>.from((_overview?['counts'] as Map?) ?? {});
    final latestLessons = ((_overview?['latest_lessons'] as List?) ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final latestTopics = ((_overview?['latest_topics'] as List?) ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionHeader(
          title: 'Tong quan noi dung',
          subtitle:
              'So lieu duoc doc truc tiep tu backend FastAPI va MySQL Laragon.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              label: 'Lessons',
              value: '${counts['lessons'] ?? 0}',
              icon: Icons.menu_book_rounded,
              color: AdminPalette.lessonAccent,
              backgroundColor: AdminPalette.lessonSurface,
            ),
            _StatCard(
              label: 'Topics',
              value: '${counts['topics'] ?? 0}',
              icon: Icons.graphic_eq_rounded,
              color: AdminPalette.topicAccent,
              backgroundColor: AdminPalette.topicSurface,
            ),
            _StatCard(
              label: 'Vocabularies',
              value: '${counts['vocabularies'] ?? 0}',
              icon: Icons.translate_rounded,
              color: AdminPalette.vocabularyAccent,
              backgroundColor: AdminPalette.vocabularySurface,
            ),
            _StatCard(
              label: 'Scenarios',
              value: '${counts['scenarios'] ?? 0}',
              icon: Icons.forum_rounded,
              color: AdminPalette.roleplayAccent,
              backgroundColor: AdminPalette.roleplaySurface,
            ),
            _StatCard(
              label: 'Sessions',
              value: '${counts['sessions'] ?? 0}',
              icon: Icons.history_rounded,
              color: AdminPalette.neutralAccent,
              backgroundColor: AdminPalette.neutralSurface,
            ),
            _StatCard(
              label: 'Results',
              value: '${counts['shadowing_results'] ?? 0}',
              icon: Icons.analytics_rounded,
              color: AdminPalette.topicAccent,
              backgroundColor: AdminPalette.topicSurface,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AdminSurface(
                  child: _RecentListCard(
                    title: 'Lesson moi nhat',
                    emptyLabel: 'Chua co lesson nao.',
                    items: latestLessons,
                    builder: (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AdminPalette.lessonSurface,
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: AdminPalette.lessonAccent,
                        ),
                      ),
                      title: Text(
                        (item['chapter_name'] ?? 'Khong ten').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Level ${item['level'] ?? 'N/A'} | Thu tu ${item['order_index'] ?? '-'}',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminSurface(
                  child: _RecentListCard(
                    title: 'Topic moi nhat',
                    emptyLabel: 'Chua co topic nao.',
                    items: latestTopics,
                    builder: (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AdminPalette.topicSurface,
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          color: AdminPalette.topicAccent,
                        ),
                      ),
                      title: Text(
                        (item['title'] ?? 'Khong ten').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Level ${item['level'] ?? 'N/A'} | Lesson ${item['lesson_id'] ?? '-'}',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: AdminSurface(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AdminPalette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentListCard extends StatelessWidget {
  const _RecentListCard({
    required this.title,
    required this.items,
    required this.builder,
    required this.emptyLabel,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final Widget Function(Map<String, dynamic>) builder;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AdminPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          AdminEmptyState(
            title: emptyLabel,
            subtitle: 'Khi co du lieu moi, danh sach se hien o day.',
          )
        else
          ...items.map(builder),
      ],
    );
  }
}
