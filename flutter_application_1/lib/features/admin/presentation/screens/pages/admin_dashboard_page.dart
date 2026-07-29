import 'package:flutter/material.dart';
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
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AdminPalette.sidebarSelectedForeground),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AdminSurface(
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
                const SizedBox(height: 16),
                const Text(
                  'Không thể kết nối đến backend',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AdminPalette.textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                AdminPrimaryButton(
                  label: 'Thử lại',
                  icon: Icons.refresh_rounded,
                  onPressed: _loadOverview,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final counts = Map<String, dynamic>.from((_overview?['counts'] as Map?) ?? {});
    final latestLessons = ((_overview?['latest_lessons'] as List?) ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final latestTopics = ((_overview?['latest_topics'] as List?) ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Tổng quan hệ thống',
            subtitle: 'Số liệu thời gian thực từ database MySQL thông qua FastAPI.',
          ),
          const SizedBox(height: 24),
          
          // Responsive Stat Cards Wrap
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = (constraints.maxWidth - 32) / 3;
              final double finalWidth = cardWidth > 220 ? cardWidth : 220.0;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    label: 'Bài học',
                    value: '${counts['lessons'] ?? 0}',
                    icon: Icons.menu_book_rounded,
                    color: AdminPalette.lessonAccent,
                    backgroundColor: AdminPalette.lessonSurface,
                    width: finalWidth,
                  ),
                  _StatCard(
                    label: 'Chủ đề',
                    value: '${counts['topics'] ?? 0}',
                    icon: Icons.graphic_eq_rounded,
                    color: AdminPalette.topicAccent,
                    backgroundColor: AdminPalette.topicSurface,
                    width: finalWidth,
                  ),
                  _StatCard(
                    label: 'Từ vựng',
                    value: '${counts['vocabularies'] ?? 0}',
                    icon: Icons.translate_rounded,
                    color: AdminPalette.vocabularyAccent,
                    backgroundColor: AdminPalette.vocabularySurface,
                    width: finalWidth,
                  ),
                  _StatCard(
                    label: 'Kịch bản nhập vai',
                    value: '${counts['scenarios'] ?? 0}',
                    icon: Icons.forum_rounded,
                    color: AdminPalette.roleplayAccent,
                    backgroundColor: AdminPalette.roleplaySurface,
                    width: finalWidth,
                  ),
                  _StatCard(
                    label: 'Lượt học',
                    value: '${counts['sessions'] ?? 0}',
                    icon: Icons.history_rounded,
                    color: AdminPalette.neutralAccent,
                    backgroundColor: AdminPalette.neutralSurface,
                    width: finalWidth,
                  ),
                  _StatCard(
                    label: 'Kết quả shadowing',
                    value: '${counts['shadowing_results'] ?? 0}',
                    icon: Icons.analytics_rounded,
                    color: AdminPalette.topicAccent,
                    backgroundColor: AdminPalette.topicSurface,
                    width: finalWidth,
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 28),
          
          // Latest Content Split Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AdminSurface(
                  child: _RecentListCard(
                    title: 'Bài học mới nhất',
                    emptyLabel: 'Chưa có bài học nào.',
                    items: latestLessons,
                    builder: (item) => _buildRecentItem(
                      title: (item['chapter_name'] ?? 'Không tên').toString(),
                      subtitle: 'Cấp độ ${item['level'] ?? 'N/A'}  •  Thứ tự index: ${item['order_index'] ?? '-'}',
                      icon: Icons.menu_book_rounded,
                      accentColor: AdminPalette.lessonAccent,
                      surfaceColor: AdminPalette.lessonSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: AdminSurface(
                  child: _RecentListCard(
                    title: 'Chủ đề mới nhất',
                    emptyLabel: 'Chưa có chủ đề nào.',
                    items: latestTopics,
                    builder: (item) => _buildRecentItem(
                      title: (item['title'] ?? 'Không tên').toString(),
                      subtitle: 'Cấp độ ${item['level'] ?? 'N/A'}  •  Mã bài học: ${item['lesson_id'] ?? '-'}',
                      icon: Icons.graphic_eq_rounded,
                      accentColor: AdminPalette.topicAccent,
                      surfaceColor: AdminPalette.topicSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color surfaceColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColor.withOpacity(0.2), width: 0.8),
          ),
          child: Icon(icon, color: accentColor, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Colors.white),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AdminPalette.textMuted),
          ),
        ),
      ),
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
    required this.width,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AdminSurface(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.25), width: 0.8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AdminPalette.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AdminPalette.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AdminPalette.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white.withOpacity(0.5)),
          ],
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          AdminEmptyState(
            title: emptyLabel,
            subtitle: 'Hệ thống chưa ghi nhận bản ghi mới nào gần đây.',
          )
        else
          ...items.take(5).map(builder),
      ],
    );
  }
}