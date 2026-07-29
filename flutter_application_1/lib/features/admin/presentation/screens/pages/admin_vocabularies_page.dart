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
              title: Text(isEditing ? 'Chỉnh sửa từ vựng' : 'Thêm từ vựng', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              backgroundColor: AdminPalette.surfaceMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
              ),
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
                              decoration: _inputDeco('Gán vào Lesson'),
                              dropdownColor: AdminPalette.surfaceMuted,
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
                              decoration: _inputDeco('Gán vào Shadowing Topic'),
                              dropdownColor: AdminPalette.surfaceMuted,
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
                              fontSize: 15,
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
                              icon: const Icon(Icons.add_rounded, size: 16, color: AdminPalette.vocabularyAccent),
                              label: const Text('Thêm từ nữa', style: TextStyle(color: AdminPalette.vocabularyAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(vocabularies.length, (index) {
                        final voc = vocabularies[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.015),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Từ vựng ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white70,
                                      fontSize: 13,
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
                                      icon: const Icon(Icons.delete_outline_rounded, color: AdminPalette.errorRed, size: 18),
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

  Widget _smallField(Map<String, String> values, String key, String label) {
    return TextFormField(
      initialValue: values[key] ?? '',
      onChanged: (value) => values[key] = value,
      decoration: _inputDeco(label, isDense: true),
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
              const Expanded(
                child: AdminSectionHeader(
                  title: 'Từ vựng',
                  subtitle:
                      'Quản lý kho từ vựng dùng cho lesson và shadowing topic.',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  value: _lessons.any((l) => l['id'] == _selectedLessonId) ? _selectedLessonId : null,
                  decoration: _inputDeco('Lọc theo bài học', isDense: true),
                  dropdownColor: AdminPalette.surfaceMuted,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả bài học'),
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

    if (_vocabularies.isEmpty) {
      return const AdminEmptyState(
        title: 'Chưa có từ vựng nào',
        subtitle: 'Bạn có thể thêm từ vựng trực tiếp cho bài học hoặc chủ đề.',
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.01),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.white.withOpacity(0.05),
                dataTableTheme: DataTableThemeData(
                  headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.02)),
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13),
                  dataTextStyle: const TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
              ),
              child: DataTable(
                columnSpacing: 28,
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Từ vựng')),
                  DataColumn(label: Text('Reading')),
                  DataColumn(label: Text('Nghĩa')),
                  DataColumn(label: Text('Mã Lesson')),
                  DataColumn(label: Text('Mã Topic')),
                  DataColumn(label: Text('Hành động')),
                ],
                rows: _vocabularies
                    .map(
                      (vocabulary) => DataRow(
                        cells: [
                          DataCell(Text('${vocabulary['id']}', style: const TextStyle(color: AdminPalette.textMuted))),
                          DataCell(Text((vocabulary['word'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white))),
                          DataCell(Text((vocabulary['reading'] ?? '-').toString(), style: const TextStyle(color: Colors.white60))),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                (vocabulary['meaning'] ?? '').toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text('${vocabulary['lesson_id'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text('${vocabulary['topic_id'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Sửa',
                                  onPressed: () => _openVocabularyDialog(vocabulary),
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 19),
                                ),
                                IconButton(
                                  tooltip: 'Xóa',
                                  onPressed: () => _deleteVocabulary(vocabulary),
                                  icon: const Icon(Icons.delete_outline_rounded, color: AdminPalette.errorRed, size: 19),
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
          ),
        ),
      ),
    );
  }
}