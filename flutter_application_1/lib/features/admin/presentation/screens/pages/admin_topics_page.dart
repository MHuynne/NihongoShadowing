import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

class AdminTopicsPage extends StatefulWidget {
  const AdminTopicsPage({super.key, required this.api, this.initialLessonId});

  final AdminApiService api;
  final int? initialLessonId;

  @override
  State<AdminTopicsPage> createState() => _AdminTopicsPageState();
}

class _AdminTopicsPageState extends State<AdminTopicsPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _allTopics = [];
  int? _selectedLessonId;

  @override
  void initState() {
    super.initState();
    _selectedLessonId = widget.initialLessonId;
    _loadData();
  }

  void _applyFilter() {
    if (_selectedLessonId == null) {
      _topics = _allTopics;
    } else if (_selectedLessonId == -1) {
      _topics = _allTopics.where((t) => t['lesson_id'] == null).toList();
    } else {
      _topics = _allTopics.where((t) => t['lesson_id'] == _selectedLessonId).toList();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessons = await widget.api.fetchLessons();
      final topics = await widget.api.fetchTopics();
      if (!mounted) return;
      setState(() {
        _lessons = lessons..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        _allTopics = topics..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        _applyFilter();
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

  List<Map<String, String>> _normalizeRows(
    dynamic source,
    List<String> keys,
  ) {
    final items = source is List ? source : <dynamic>[];
    if (items.isEmpty) {
      return [
        for (final _ in [0]) {for (final key in keys) key: ''}
      ];
    }

    return items.map<Map<String, String>>((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return {
        for (final key in keys) key: (map[key] ?? '').toString(),
      };
    }).toList();
  }

  Future<void> _openTopicDialog([Map<String, dynamic>? topic]) async {
    final titleController = TextEditingController(
      text: (topic?['title'] ?? '').toString(),
    );
    String? level = topic?['level']?.toString();
    String? lessonId = topic?['lesson_id']?.toString();

    // Chỉ giữ 3 trường cần thiết cho mỗi câu
    final rawSegments = topic?['segments'];
    final segments = <Map<String, String>>[];
    if (rawSegments is List && rawSegments.isNotEmpty) {
      for (final s in rawSegments) {
        final m = Map<String, dynamic>.from(s as Map);
        segments.add({
          'kanji_content': (m['kanji_content'] ?? '').toString(),
          'furigana': (m['furigana'] ?? '').toString(),
          'translation_vi': (m['translation_vi'] ?? '').toString(),
          'order_index': (m['order_index'] ?? '').toString(),
          'romaji': (m['romaji'] ?? '').toString(),
          'sino_vietnamese': (m['sino_vietnamese'] ?? '').toString(),
          'start_time': (m['start_time'] ?? '').toString(),
          'end_time': (m['end_time'] ?? '').toString(),
        });
      }
    }
    if (segments.isEmpty) {
      segments.add({
        'kanji_content': '',
        'furigana': '',
        'translation_vi': '',
        'order_index': '1',
        'romaji': '',
        'sino_vietnamese': '',
        'start_time': '',
        'end_time': '',
      });
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                topic == null ? 'Thêm Shadowing Topic' : 'Chỉnh sửa Shadowing Topic',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SizedBox(
                width: 760,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Tên chủ đề + Cấp độ ─────────────────────
                      _twoColumn(
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Tên chủ đề',
                            hintText: 'VD: Chào hỏi cơ bản',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: level,
                          decoration: const InputDecoration(
                            labelText: 'Cấp độ JLPT',
                            border: OutlineInputBorder(),
                          ),
                          items: const ['N5', 'N4', 'N3', 'N2', 'N1']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) => setDialogState(() => level = v),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Gán vào lesson ───────────────────────────
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: _lessons.any((l) => l['id'].toString() == lessonId) ? lessonId : null,
                        decoration: const InputDecoration(
                          labelText: 'Gán vào Lesson (tuỳ chọn)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Không chọn lesson'),
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
                        onChanged: (v) => setDialogState(() => lessonId = v),
                      ),
                      const SizedBox(height: 20),

                      // ── Danh sách câu Shadowing ──────────────────
                      Row(
                        children: [
                          const Text(
                            'Các câu Shadowing',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AdminPalette.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => setDialogState(() {
                              segments.add({
                                'kanji_content': '',
                                'furigana': '',
                                'translation_vi': '',
                                'order_index': '${segments.length + 1}',
                                'romaji': '',
                                'sino_vietnamese': '',
                                'start_time': '',
                                'end_time': '',
                              });
                            }),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Thêm câu'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ...List.generate(segments.length, (index) {
                        final seg = segments[index];
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
                                    'Câu ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AdminPalette.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (segments.length > 1)
                                    IconButton(
                                      onPressed: () => setDialogState(() => segments.removeAt(index)),
                                      icon: const Icon(Icons.delete_outline_rounded),
                                      tooltip: 'Xoá câu này',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: seg['kanji_content'],
                                onChanged: (v) => seg['kanji_content'] = v,
                                decoration: const InputDecoration(
                                  labelText: '漢字 — Câu gốc (có Kanji)',
                                  hintText: 'VD: 日本語を勉強しています',
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: seg['furigana'],
                                onChanged: (v) => seg['furigana'] = v,
                                decoration: const InputDecoration(
                                  labelText: 'Furigana — Phiên âm Hiragana',
                                  hintText: 'VD: にほんごをべんきょうしています',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: seg['translation_vi'],
                                onChanged: (v) => seg['translation_vi'] = v,
                                decoration: const InputDecoration(
                                  labelText: 'Dịch nghĩa tiếng Việt',
                                  hintText: 'VD: Tôi đang học tiếng Nhật.',
                                  border: OutlineInputBorder(),
                                ),
                              ),
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
                  child: const Text('Huỷ'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final payload = {
      'title': titleController.text.trim(),
      'level': level,
      'lesson_id': int.tryParse(lessonId ?? ''),
      'image_url': null,
      'full_audio_url': null,
      'full_script_ja': null,
      'total_duration': null,
      'vocabularies': [],
      'segments': segments
          .where((s) => (s['kanji_content'] ?? '').trim().isNotEmpty)
          .toList()
          .asMap()
          .entries
          .map((e) => {
                'order_index': e.key + 1,
                'kanji_content': _nullable(e.value['kanji_content']),
                'furigana': _nullable(e.value['furigana']),
                'translation_vi': _nullable(e.value['translation_vi']),
                'romaji': null,
                'sino_vietnamese': null,
                'start_time': null,
                'end_time': null,
              })
          .toList(),
    };

    try {
      if (topic == null) {
        await widget.api.createTopic(payload);
      } else {
        await widget.api.updateTopic(topic['id'] as int, payload);
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu topic: $e')),
      );
    }
  }



  Future<void> _deleteTopic(Map<String, dynamic> topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa topic?'),
        content: Text(
          'Topic "${topic['title'] ?? ''}" se bi xoa cung cac segment va vocabulary lien quan.',
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
      await widget.api.deleteTopic(topic['id'] as int);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong the xoa topic: $e')),
      );
    }
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _smallField(
    Map<String, String> values,
    String key,
    String label,
  ) {
    return TextFormField(
      initialValue: values[key] ?? '',
      onChanged: (value) => values[key] = value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _sectionTitle(String title, {required VoidCallback onAdd}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AdminPalette.textPrimary,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Them'),
        ),
      ],
    );
  }

  Widget _twoColumn(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _threeColumn(Widget first, Widget second, Widget third) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
        const SizedBox(width: 10),
        Expanded(child: third),
      ],
    );
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
                child: AdminSectionHeader(
                  title: 'Shadowing topics',
                  subtitle: 'Quan ly topic, segment va vocabulary cho bai shadowing.',
                ),
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  value: (_selectedLessonId == null || _selectedLessonId == -1 || _lessons.any((l) => l['id'] == _selectedLessonId)) ? _selectedLessonId : null,
                  decoration: const InputDecoration(
                    labelText: 'Loc theo lesson',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tat ca topic'),
                    ),
                    const DropdownMenuItem<int?>(
                      value: -1,
                      child: Text('Topic doc lap (Khong thuoc lesson)'),
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
                    setState(() {
                      _selectedLessonId = value;
                      _applyFilter();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              AdminPrimaryButton(
                label: 'Them topic',
                onPressed: _openTopicDialog,
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

    if (_topics.isEmpty) {
      return const AdminEmptyState(
        title: 'Chua co topic shadowing nao',
        subtitle: 'Them topic moi de nguoi hoc co noi dung luyen nghe noi.',
      );
    }

    return ListView.separated(
      itemCount: _topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final topic = _topics[index];
        final segments = (topic['segments'] as List?) ?? const [];

        return Container(
          decoration: BoxDecoration(
            color: AdminPalette.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AdminPalette.borderSoft),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AdminPalette.topicSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: AdminPalette.topicAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (topic['title'] ?? 'Khong ten').toString(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AdminPalette.textPrimary,
                            ),
                          ),
                        ),
                        _badge('JLPT ${topic['level'] ?? 'N/A'}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _metaChip(Icons.layers_rounded,
                            'Lesson ${topic['lesson_id'] ?? '-'}'),
                        _metaChip(Icons.list_alt_rounded,
                            '${segments.length} segments'),
                        _metaChip(Icons.schedule_rounded,
                            '${topic['total_duration'] ?? '-'}'),
                      ],
                    ),
                    if ((topic['full_script_ja'] ?? '')
                        .toString()
                        .isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        (topic['full_script_ja'] ?? '').toString(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AdminPalette.textSecondary, height: 1.5),
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
                    onPressed: () => _openTopicDialog(topic),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Xoa',
                    onPressed: () => _deleteTopic(topic),
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

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AdminPalette.topicSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AdminPalette.topicAccent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AdminPalette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminPalette.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AdminPalette.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AdminPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemEditorCard extends StatelessWidget {
  const _ItemEditorCard({
    required this.title,
    required this.child,
    this.onRemove,
  });

  final String title;
  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminPalette.borderSoft),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
