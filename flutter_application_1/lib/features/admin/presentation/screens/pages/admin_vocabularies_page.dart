import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

class AdminVocabulariesPage extends StatefulWidget {
  const AdminVocabulariesPage({super.key, required this.api});

  final AdminApiService api;

  @override
  State<AdminVocabulariesPage> createState() => _AdminVocabulariesPageState();
}

class _AdminVocabulariesPageState extends State<AdminVocabulariesPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _vocabularies = [];
  int? _selectedLessonId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessons = await widget.api.fetchLessons();
      final vocabularies = await widget.api.fetchVocabularies(
        lessonId: _selectedLessonId,
      );
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _vocabularies = vocabularies;
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

  Future<void> _openVocabularyDialog([Map<String, dynamic>? vocabulary]) async {
    final wordController = TextEditingController(
      text: (vocabulary?['word'] ?? '').toString(),
    );
    final readingController = TextEditingController(
      text: (vocabulary?['reading'] ?? '').toString(),
    );
    final meaningController = TextEditingController(
      text: (vocabulary?['meaning'] ?? '').toString(),
    );
    final exampleController = TextEditingController(
      text: (vocabulary?['example'] ?? '').toString(),
    );
    String? lessonIdValue = vocabulary?['lesson_id']?.toString();
    final topicIdController = TextEditingController(
      text: (vocabulary?['topic_id'] ?? '').toString(),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                  vocabulary == null ? 'Them tu vung' : 'Chinh sua tu vung'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: wordController,
                        decoration: const InputDecoration(
                          labelText: 'Tu / Kanji',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: readingController,
                        decoration: const InputDecoration(
                          labelText: 'Reading',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: meaningController,
                        decoration: const InputDecoration(
                          labelText: 'Nghia',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: lessonIdValue,
                        decoration: const InputDecoration(
                          labelText: 'Gan vao lesson',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Khong chon'),
                          ),
                          ..._lessons.map(
                            (lesson) => DropdownMenuItem<String?>(
                              value: lesson['id'].toString(),
                              child: Text(
                                '${lesson['chapter_name'] ?? 'Khong ten'} (${lesson['level'] ?? 'N/A'})',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => lessonIdValue = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: topicIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Topic ID (neu co)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: exampleController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Vi du',
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
            );
          },
        );
      },
    );

    if (saved != true) return;

    final payload = {
      'lesson_id': int.tryParse(lessonIdValue ?? ''),
      'topic_id': int.tryParse(topicIdController.text.trim()),
      'word': wordController.text.trim(),
      'reading': readingController.text.trim().isEmpty
          ? null
          : readingController.text.trim(),
      'meaning': meaningController.text.trim(),
      'example': exampleController.text.trim().isEmpty
          ? null
          : exampleController.text.trim(),
    };

    try {
      if (vocabulary == null) {
        await widget.api.createVocabulary(payload);
      } else {
        await widget.api.updateVocabulary(vocabulary['id'] as int, payload);
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong the luu tu vung: $e')),
      );
    }
  }

  Future<void> _deleteVocabulary(Map<String, dynamic> vocabulary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa tu vung?'),
        content: Text(
          'Tu "${vocabulary['word'] ?? ''}" se bi xoa khoi he thong.',
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
      await widget.api.deleteVocabulary(vocabulary['id'] as int);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong the xoa tu vung: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: const AdminSectionHeader(
                  title: 'Tu vung',
                  subtitle:
                      'Quan ly kho tu vung dung cho lesson va shadowing topic.',
                ),
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<int?>(
                  value: _selectedLessonId,
                  decoration: const InputDecoration(
                    labelText: 'Loc theo lesson',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tat ca lesson'),
                    ),
                    ..._lessons.map(
                      (lesson) => DropdownMenuItem<int?>(
                        value: lesson['id'] as int,
                        child: Text(
                          (lesson['chapter_name'] ?? 'Khong ten').toString(),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedLessonId = value);
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              AdminPrimaryButton(
                label: 'Them tu vung',
                onPressed: _openVocabularyDialog,
              ),
            ],
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

    if (_vocabularies.isEmpty) {
      return const AdminEmptyState(
        title: 'Chua co tu vung nao',
        subtitle: 'Ban co the them tu vung truc tiep cho lesson hoac topic.',
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 22,
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Word')),
          DataColumn(label: Text('Reading')),
          DataColumn(label: Text('Meaning')),
          DataColumn(label: Text('Lesson')),
          DataColumn(label: Text('Topic')),
          DataColumn(label: Text('Hanh dong')),
        ],
        rows: _vocabularies
            .map(
              (vocabulary) => DataRow(
                cells: [
                  DataCell(Text('${vocabulary['id']}')),
                  DataCell(Text((vocabulary['word'] ?? '').toString())),
                  DataCell(Text((vocabulary['reading'] ?? '-').toString())),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        (vocabulary['meaning'] ?? '').toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text('${vocabulary['lesson_id'] ?? '-'}')),
                  DataCell(Text('${vocabulary['topic_id'] ?? '-'}')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _openVocabularyDialog(vocabulary),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => _deleteVocabulary(vocabulary),
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
