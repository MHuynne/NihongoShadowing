import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _topics = [];
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
      final topics = await widget.api.fetchTopics();
      final vocabularies = await widget.api.fetchVocabularies(
        lessonId: _selectedLessonId,
      );
      if (!mounted) return;
      setState(() {
        _lessons = lessons..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        _topics = topics..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        _vocabularies = vocabularies..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
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
    String? topicIdValue = vocabulary?['topic_id']?.toString();

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
              title: Text(isEditing ? 'Chỉnh sửa từ vựng' : 'Thêm từ vựng'),
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
                                labelText: 'Gán vào Lesson',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Không chọn'),
                                ),
                                ..._lessons.map(
                                  (lesson) => DropdownMenuItem<String?>(
                                    value: lesson['id'].toString(),
                                    child: Text(
                                      '${lesson['chapter_name'] ?? 'Không tên'} (${lesson['level'] ?? 'N/A'})',
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
                            child: DropdownButtonFormField<String?>(
                              isExpanded: true,
                              value: _topics.any((t) => t['id'].toString() == topicIdValue) ? topicIdValue : null,
                              decoration: const InputDecoration(
                                labelText: 'Gán vào Shadowing Topic',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Không chọn'),
                                ),
                                ..._topics.map(
                                  (topic) => DropdownMenuItem<String?>(
                                    value: topic['id'].toString(),
                                    child: Text(
                                      '${topic['title'] ?? 'Không tên'}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setDialogState(() => topicIdValue = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text(
                            'Danh sách từ vựng',
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
                              label: const Text('Thêm từ nữa'),
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
                                    'Từ vựng ${index + 1}',
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
                                    child: _smallField(voc, 'word', 'Từ / Kanji'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _smallField(voc, 'reading', 'Reading'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _smallField(voc, 'meaning', 'Nghĩa'),
                              const SizedBox(height: 10),
                              _smallField(voc, 'example', 'Ví dụ'),
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
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () {
                    for (int i = 0; i < vocabularies.length; i++) {
                      final voc = vocabularies[i];
                      final word = voc['word']!.trim();
                      final meaning = voc['meaning']!.trim();
                      if (word.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Vui lòng nhập Từ / Kanji ở dòng số ${i + 1}')),
                        );
                        return;
                      }
                      if (meaning.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Vui lòng nhập Nghĩa ở dòng số ${i + 1}')),
                        );
                        return;
                      }
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Lưu'),
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
          'topic_id': int.tryParse(topicIdValue ?? ''),
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
            'topic_id': int.tryParse(topicIdValue ?? ''),
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
        SnackBar(content: Text('Không thể lưu từ vựng: $e')),
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
        title: const Text('Xóa từ vựng?'),
        content: Text(
          'Từ "${vocabulary['word'] ?? ''}" sẽ bị xóa khỏi hệ thống.',
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
      await widget.api.deleteVocabulary(vocabulary['id'] as int);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa từ vựng: $e')),
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
                  title: 'Từ vựng',
                  subtitle:
                      'Quản lý kho từ vựng dùng cho lesson và shadowing topic.',
                ),
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  value: _lessons.any((l) => l['id'] == _selectedLessonId) ? _selectedLessonId : null,
                  decoration: const InputDecoration(
                    labelText: 'Lọc theo lesson',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả lesson'),
                    ),
                    ..._lessons.map(
                      (lesson) => DropdownMenuItem<int?>(
                        value: lesson['id'] as int,
                        child: Text(
                          (lesson['chapter_name'] ?? 'Không tên').toString(),
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
                label: 'Thêm từ vựng',
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
        title: 'Chưa có từ vựng nào',
        subtitle: 'Bạn có thể thêm từ vựng trực tiếp cho lesson hoặc topic.',
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 22,
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Word')),
            DataColumn(label: Text('Reading')),
            DataColumn(label: Text('Nghĩa')),
            DataColumn(label: Text('Lesson')),
            DataColumn(label: Text('Topic')),
            DataColumn(label: Text('Hành động')),
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
      ),
    );
  }
}
