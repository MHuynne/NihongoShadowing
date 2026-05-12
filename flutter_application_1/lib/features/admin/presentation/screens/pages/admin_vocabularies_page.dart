import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

class AdminVocabulariesPage extends StatefulWidget {
  const AdminVocabulariesPage({super.key, required this.api, this.initialLessonId});

  final AdminApiService api;
  final int? initialLessonId;

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
    _selectedLessonId = widget.initialLessonId;
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
    final bool isEditing = vocabulary != null;

    String? lessonIdValue = vocabulary?['lesson_id']?.toString() ?? _selectedLessonId?.toString();
    final topicIdController = TextEditingController(
      text: (vocabulary?['topic_id'] ?? '').toString(),
    );

    final List<Map<String, String>> vocabularies = [];
    if (isEditing) {
      vocabularies.add({
        'word': (vocabulary['word'] ?? '').toString(),
        'reading': (vocabulary['reading'] ?? '').toString(),
        'meaning': (vocabulary['meaning'] ?? '').toString(),
        'example': (vocabulary['example'] ?? '').toString(),
      });
    } else {
      vocabularies.add({
        'word': '',
        'reading': '',
        'meaning': '',
        'example': '',
      });
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Chinh sua tu vung' : 'Them tu vung'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              isExpanded: true,
                              value: _lessons.any((l) => l['id'].toString() == lessonIdValue) ? lessonIdValue : null,
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setDialogState(() => lessonIdValue = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: topicIdController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Topic ID (neu co)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text(
                            'Danh sach tu vung',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AdminPalette.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (!isEditing)
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  vocabularies.add({
                                    'word': '',
                                    'reading': '',
                                    'meaning': '',
                                    'example': '',
                                  });
                                });
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Them tu nua'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(vocabularies.length, (index) {
                        final voc = vocabularies[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AdminPalette.surfaceMuted,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AdminPalette.borderSoft),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Tu vung ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AdminPalette.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!isEditing && vocabularies.length > 1)
                                    IconButton(
                                      onPressed: () {
                                        setDialogState(() {
                                          vocabularies.removeAt(index);
                                        });
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _smallField(voc, 'word', 'Tu / Kanji'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _smallField(voc, 'reading', 'Reading'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _smallField(voc, 'meaning', 'Nghia'),
                              const SizedBox(height: 10),
                              _smallField(voc, 'example', 'Vi du'),
                            ],
                          ),
                        );
                      }),
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

    try {
      if (isEditing) {
        final voc = vocabularies.first;
        final payload = {
          'lesson_id': int.tryParse(lessonIdValue ?? ''),
          'topic_id': int.tryParse(topicIdController.text.trim()),
          'word': voc['word']!.trim(),
          'reading': voc['reading']!.trim().isEmpty ? null : voc['reading']!.trim(),
          'meaning': voc['meaning']!.trim(),
          'example': voc['example']!.trim().isEmpty ? null : voc['example']!.trim(),
        };
        await widget.api.updateVocabulary(vocabulary['id'] as int, payload);
      } else {
        for (final voc in vocabularies) {
          if (voc['word']!.trim().isEmpty) continue;
          final payload = {
            'lesson_id': int.tryParse(lessonIdValue ?? ''),
            'topic_id': int.tryParse(topicIdController.text.trim()),
            'word': voc['word']!.trim(),
            'reading': voc['reading']!.trim().isEmpty ? null : voc['reading']!.trim(),
            'meaning': voc['meaning']!.trim(),
            'example': voc['example']!.trim().isEmpty ? null : voc['example']!.trim(),
          };
          await widget.api.createVocabulary(payload);
        }
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong the luu tu vung: $e')),
      );
    }
  }

  Widget _smallField(Map<String, String> values, String key, String label) {
    return TextFormField(
      initialValue: values[key] ?? '',
      onChanged: (value) => values[key] = value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
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
            style: FilledButton.styleFrom(backgroundColor: AdminPalette.errorRed),
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
                  isExpanded: true,
                  value: _lessons.any((l) => l['id'] == _selectedLessonId) ? _selectedLessonId : null,
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
                          overflow: TextOverflow.ellipsis,
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
              Text(_error!, style: const TextStyle(color: AdminPalette.errorRed)));
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
