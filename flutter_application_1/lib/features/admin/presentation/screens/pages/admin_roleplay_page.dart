import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

class AdminRoleplayPage extends StatefulWidget {
  const AdminRoleplayPage({super.key, required this.api});

  final AdminApiService api;

  @override
  State<AdminRoleplayPage> createState() => _AdminRoleplayPageState();
}

class _AdminRoleplayPageState extends State<AdminRoleplayPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _scenarios = [];

  @override
  void initState() {
    super.initState();
    _loadScenarios();
  }

  Future<void> _loadScenarios() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final scenarios = await widget.api.fetchScenarios();
      if (!mounted) return;
      setState(() {
        _scenarios = scenarios;
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

  InputDecoration _inputDeco(String label, {bool isDense = false}) {
    return InputDecoration(
      labelText: label,
      isDense: isDense,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
      floatingLabelStyle: const TextStyle(color: AdminPalette.sidebarSelectedForeground, fontSize: 13, fontWeight: FontWeight.w700),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isDense ? 12 : 16),
      filled: true,
      fillColor: Colors.white.withOpacity(0.015),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminPalette.sidebarSelectedForeground, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AdminPalette.errorRed, width: 1.0),
      ),
    );
  }

  Future<void> _openScenarioDialog([Map<String, dynamic>? scenario]) async {
    final titleController = TextEditingController(
      text: (scenario?['title'] ?? '').toString(),
    );
    final descriptionController = TextEditingController(
      text: (scenario?['description'] ?? '').toString(),
    );
    final iconController = TextEditingController(
      text: (scenario?['icon_url'] ?? '').toString(),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          scenario == null ? 'Thêm kịch bản' : 'Chỉnh sửa kịch bản',
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        backgroundColor: AdminPalette.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: _inputDeco('Tiêu đề'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: _inputDeco('Mô tả bối cảnh'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: iconController,
                  decoration: _inputDeco('Icon URL (tuỳ chọn)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final payload = {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      'icon_url': iconController.text.trim().isEmpty
          ? null
          : iconController.text.trim(),
    };

    try {
      if (scenario == null) {
        await widget.api.createScenario(payload);
      } else {
        await widget.api.updateScenario(scenario['id'] as int, payload);
      }
      await _loadScenarios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu kịch bản: $e')),
      );
    }
  }

  Future<void> _deleteScenario(Map<String, dynamic> scenario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa kịch bản?'),
        content: Text(
          'Kịch bản "${scenario['title'] ?? ''}" sẽ bị xóa khỏi hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AdminPalette.errorRed),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.api.deleteScenario(scenario['id'] as int);
      await _loadScenarios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa kịch bản: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Kịch bản nhập vai',
            subtitle: 'Quản lý các bối cảnh hội thoại cho AI Sensei.',
            action: AdminPrimaryButton(
              label: 'Thêm kịch bản',
              onPressed: _openScenarioDialog,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AdminPalette.sidebarSelectedForeground),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AdminPalette.errorRed)),
      );
    }

    if (_scenarios.isEmpty) {
      return const AdminEmptyState(
        title: 'Chưa có kịch bản nào',
        subtitle: 'Thêm bối cảnh nhập vai để người học tập giao tiếp với AI.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _scenarios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final scenario = _scenarios[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.015),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.8),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AdminPalette.roleplaySurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminPalette.roleplayAccent.withOpacity(0.2), width: 0.8),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: AdminPalette.roleplayAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (scenario['title'] ?? 'Không tên').toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AdminPalette.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (scenario['description'] ?? 'Không có mô tả').toString(),
                      style: const TextStyle(
                        color: AdminPalette.textSecondary,
                        height: 1.5,
                        fontSize: 13.5,
                      ),
                    ),
                    if ((scenario['icon_url'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        (scenario['icon_url'] ?? '').toString(),
                        style: const TextStyle(
                          color: AdminPalette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Sửa',
                    onPressed: () => _openScenarioDialog(scenario),
                    icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: () => _deleteScenario(scenario),
                    icon: const Icon(Icons.delete_outline_rounded, color: AdminPalette.errorRed, size: 20),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}