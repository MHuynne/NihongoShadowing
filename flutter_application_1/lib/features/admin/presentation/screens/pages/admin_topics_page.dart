import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

class AdminTopicsPage extends StatefulWidget {
  const AdminTopicsPage({super.key, required this.api});

  final AdminApiService api;

  @override
  State<AdminTopicsPage> createState() => _AdminTopicsPageState();
}

class _AdminTopicsPageState extends State<AdminTopicsPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _topics = [];

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
      final topics = await widget.api.fetchTopics();
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _topics = topics;
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
    final imageController = TextEditingController(
      text: (topic?['image_url'] ?? '').toString(),
    );
    final audioController = TextEditingController(
      text: (topic?['full_audio_url'] ?? '').toString(),
    );
    final scriptController = TextEditingController(
      text: (topic?['full_script_ja'] ?? '').toString(),
    );
    final durationController = TextEditingController(
      text: (topic?['total_duration'] ?? '').toString(),
    );

    String? level = topic?['level']?.toString();
    String? lessonId = topic?['lesson_id']?.toString();
    final segments = _normalizeRows(
      topic?['segments'],
      [
        'order_index',
        'start_time',
        'end_time',
        'kanji_content',
        'furigana',
        'romaji',
        'sino_vietnamese',
        'translation_vi',
      ],
    );
    final vocabularies = _normalizeRows(
      topic?['vocabularies'],
      ['word', 'reading', 'meaning', 'example'],
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(topic == null
                  ? 'Them shadowing topic'
                  : 'Chinh sua shadowing topic'),
              content: SizedBox(
                width: 960,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _twoColumn(
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Tieu de',
                            border: OutlineInputBorder(),
                          ),
                        ),
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
                          onChanged: (value) =>
                              setDialogState(() => level = value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _twoColumn(
                        DropdownButtonFormField<String?>(
                          value: lessonId,
                          decoration: const InputDecoration(
                            labelText: 'Gan vao lesson',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Khong chon lesson'),
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
                              setDialogState(() => lessonId = value),
                        ),
                        TextField(
                          controller: durationController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Thoi luong',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _twoColumn(
                        TextField(
                          controller: imageController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextField(
                          controller: audioController,
                          decoration: const InputDecoration(
                            labelText: 'Audio URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: scriptController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Full script JA',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        'Segments',
                        onAdd: () => setDialogState(
                          () => segments.add(
                            {
                              'order_index': '${segments.length + 1}',
                              'start_time': '',
                              'end_time': '',
                              'kanji_content': '',
                              'furigana': '',
                              'romaji': '',
                              'sino_vietnamese': '',
                              'translation_vi': '',
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(segments.length, (index) {
                        final segment = segments[index];
                        return _ItemEditorCard(
                          title: 'Segment ${index + 1}',
                          onRemove: segments.length == 1
                              ? null
                              : () => setDialogState(
                                  () => segments.removeAt(index)),
                          child: Column(
                            children: [
                              _threeColumn(
                                _smallField(segment, 'order_index', 'Order'),
                                _smallField(segment, 'start_time', 'Start'),
                                _smallField(segment, 'end_time', 'End'),
                              ),
                              const SizedBox(height: 10),
                              _twoColumn(
                                _smallField(segment, 'kanji_content', 'Kanji'),
                                _smallField(segment, 'furigana', 'Furigana'),
                              ),
                              const SizedBox(height: 10),
                              _twoColumn(
                                _smallField(segment, 'romaji', 'Romaji'),
                                _smallField(
                                    segment, 'sino_vietnamese', 'Han Viet'),
                              ),
                              const SizedBox(height: 10),
                              _smallField(segment, 'translation_vi',
                                  'Nghia tieng Viet'),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      _sectionTitle(
                        'Vocabularies',
                        onAdd: () => setDialogState(
                          () => vocabularies.add(
                            {
                              'word': '',
                              'reading': '',
                              'meaning': '',
                              'example': '',
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(vocabularies.length, (index) {
                        final vocabulary = vocabularies[index];
                        return _ItemEditorCard(
                          title: 'Vocabulary ${index + 1}',
                          onRemove: vocabularies.length == 1
                              ? null
                              : () => setDialogState(
                                  () => vocabularies.removeAt(index)),
                          child: Column(
                            children: [
                              _twoColumn(
                                _smallField(vocabulary, 'word', 'Word'),
                                _smallField(vocabulary, 'reading', 'Reading'),
                              ),
                              const SizedBox(height: 10),
                              _smallField(vocabulary, 'meaning', 'Meaning'),
                              const SizedBox(height: 10),
                              _smallField(vocabulary, 'example', 'Example'),
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

    final payload = {
      'title': titleController.text.trim(),
      'level': level,
      'lesson_id': int.tryParse(lessonId ?? ''),
      'image_url': imageController.text.trim().isEmpty
          ? null
          : imageController.text.trim(),
      'full_audio_url': audioController.text.trim().isEmpty
          ? null
          : audioController.text.trim(),
      'full_script_ja': scriptController.text.trim().isEmpty
          ? null
          : scriptController.text.trim(),
      'total_duration': double.tryParse(durationController.text.trim()),
      'segments': segments
          .where(
              (segment) => (segment['kanji_content'] ?? '').trim().isNotEmpty)
          .map(
            (segment) => {
              'order_index': int.tryParse(segment['order_index'] ?? '') ?? 1,
              'start_time': double.tryParse(segment['start_time'] ?? ''),
              'end_time': double.tryParse(segment['end_time'] ?? ''),
              'kanji_content': _nullable(segment['kanji_content']),
              'furigana': _nullable(segment['furigana']),
              'romaji': _nullable(segment['romaji']),
              'sino_vietnamese': _nullable(segment['sino_vietnamese']),
              'translation_vi': _nullable(segment['translation_vi']),
            },
          )
          .toList(),
      'vocabularies': vocabularies
          .where((vocabulary) => (vocabulary['word'] ?? '').trim().isNotEmpty)
          .map(
            (vocabulary) => {
              'word': (vocabulary['word'] ?? '').trim(),
              'reading': _nullable(vocabulary['reading']),
              'meaning': (vocabulary['meaning'] ?? '').trim(),
              'example': _nullable(vocabulary['example']),
            },
          )
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
        SnackBar(content: Text('Khong the luu topic: $e')),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
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
            color: AppColors.textDark,
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
          AdminSectionHeader(
            title: 'Shadowing topics',
            subtitle: 'Quan ly topic, segment va vocabulary cho bai shadowing.',
            action: AdminPrimaryButton(
              label: 'Them topic',
              onPressed: _openTopicDialog,
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
        final vocabularies = (topic['vocabularies'] as List?) ?? const [];

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
                              color: AppColors.textDark,
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
                        _metaChip(Icons.translate_rounded,
                            '${vocabularies.length} vocab'),
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
                            color: AppColors.slate600, height: 1.5),
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
          Icon(icon, size: 14, color: AppColors.slate500),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate600,
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
                  color: AppColors.textDark,
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
