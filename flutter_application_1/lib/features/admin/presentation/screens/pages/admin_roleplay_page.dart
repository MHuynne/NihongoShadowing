import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
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
        title: Text(scenario == null ? 'Them scenario' : 'Chinh sua scenario'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tieu de',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mo ta boi canh',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Luu'),
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
        SnackBar(content: Text('Khong the luu scenario: $e')),
      );
    }
  }

  Future<void> _deleteScenario(Map<String, dynamic> scenario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa scenario?'),
        content: Text(
          'Scenario "${scenario['title'] ?? ''}" se bi xoa khoi he thong.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Xoa'),
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
        SnackBar(content: Text('Khong the xoa scenario: $e')),
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
            title: 'Roleplay scenarios',
            subtitle: 'Quan ly cac boi canh hoi thoai cho AI Sensei.',
            action: AdminPrimaryButton(
              label: 'Them scenario',
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
          child:
              Text(_error!, style: const TextStyle(color: AppColors.errorRed)));
    }

    if (_scenarios.isEmpty) {
      return const AdminEmptyState(
        title: 'Chua co scenario nao',
        subtitle: 'Them boi canh roleplay de nguoi hoc tap giao tiep voi AI.',
      );
    }

    return ListView.separated(
      itemCount: _scenarios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final scenario = _scenarios[index];
        return Container(
          decoration: BoxDecoration(
            color: AdminPalette.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminPalette.borderSoft),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AdminPalette.roleplaySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: AdminPalette.roleplayAccent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (scenario['title'] ?? 'Khong ten').toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (scenario['description'] ?? 'Khong co mo ta').toString(),
                      style: const TextStyle(
                        color: AdminPalette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if ((scenario['icon_url'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        (scenario['icon_url'] ?? '').toString(),
                        style: const TextStyle(
                          color: AdminPalette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Sua',
                    onPressed: () => _openScenarioDialog(scenario),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Xoa',
                    onPressed: () => _deleteScenario(scenario),
                    icon: const Icon(Icons.delete_outline_rounded),
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
