import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

class AdminLessonsPage extends StatefulWidget {
  const AdminLessonsPage({super.key, required this.api});

  final AdminApiService api;

  @override
  State<AdminLessonsPage> createState() => _AdminLessonsPageState();
}

class _AdminLessonsPageState extends State<AdminLessonsPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessons = await widget.api.fetchLessons();
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
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

  Future<void> _openLessonDialog([Map<String, dynamic>? lesson]) async {
    final chapterController = TextEditingController(
      text: (lesson?['chapter_name'] ?? '').toString(),
    );
    final orderController = TextEditingController(
      text: (lesson?['order_index'] ?? '').toString(),
    );
    String? level = lesson?['level']?.toString();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title:
                  Text(lesson == null ? 'Them bai hoc' : 'Chinh sua bai hoc'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: chapterController,
                      decoration: const InputDecoration(
                        labelText: 'Ten bai hoc',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: level,
                      decoration: const InputDecoration(
                        labelText: 'Cap do',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['N5', 'N4', 'N3', 'N2', 'N1']
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setDialogState(() => level = value),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: orderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Thu tu hien thi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
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
            );
          },
        );
      },
    );

    if (saved != true) {
      return;
    }

    final payload = {
      'chapter_name': chapterController.text.trim(),
      'level': level,
      'order_index': int.tryParse(orderController.text.trim()),
      'vocabularies': <Map<String, dynamic>>[],
    };

    try {
      if (lesson == null) {
        await widget.api.createLesson(payload);
      } else {
        await widget.api.updateLesson(lesson['id'] as int, payload);
      }
      await _loadLessons();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong the luu bai hoc: $e')),
      );
    }
  }

  Future<void> _deleteLesson(Map<String, dynamic> lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa bai hoc?'),
        content: Text(
          'Bai hoc "${lesson['chapter_name'] ?? 'Khong ten'}" se bi xoa khoi he thong.',
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
      await widget.api.deleteLesson(lesson['id'] as int);
      await _loadLessons();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong the xoa bai hoc: $e')),
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
            title: 'Bai hoc',
            subtitle: 'Them, sua va xoa lesson dang luu trong MySQL Laragon.',
            action: AdminPrimaryButton(
              label: 'Them bai hoc',
              onPressed: _openLessonDialog,
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

    if (_lessons.isEmpty) {
      return const AdminEmptyState(
        title: 'Chua co bai hoc nao',
        subtitle: 'Tao bai hoc dau tien de bat dau quan tri lo trinh hoc.',
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Ten bai hoc')),
          DataColumn(label: Text('Level')),
          DataColumn(label: Text('Thu tu')),
          DataColumn(label: Text('Hanh dong')),
        ],
        rows: _lessons
            .map(
              (lesson) => DataRow(
                cells: [
                  DataCell(Text('${lesson['id']}')),
                  DataCell(Text((lesson['chapter_name'] ?? '').toString())),
                  DataCell(Text((lesson['level'] ?? 'N/A').toString())),
                  DataCell(Text('${lesson['order_index'] ?? '-'}')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Sua',
                          onPressed: () => _openLessonDialog(lesson),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Xoa',
                          onPressed: () => _deleteLesson(lesson),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
