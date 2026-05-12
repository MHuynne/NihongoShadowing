import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';
import 'package:file_picker/file_picker.dart';

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
        _lessons = lessons;
        _allTopics = topics;
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
    final imageController = TextEditingController(
      text: (topic?['image_url'] ?? '').toString(),
    );
    final audioController = TextEditingController(
      text: (topic?['full_audio_url'] ?? '').toString(),
    );
    String? imageFileName = topic?['image_url']?.toString().split('/').last;
    if (imageFileName?.isEmpty ?? true) imageFileName = null;
    String? audioFileName = topic?['full_audio_url']?.toString().split('/').last;
    if (audioFileName?.isEmpty ?? true) audioFileName = null;
    List<int>? imageBytes; // để preview ảnh vừa chọn
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
                          isExpanded: true,
                          value: _lessons.any((l) => l['id'].toString() == lessonId) ? lessonId : null,
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
                                  overflow: TextOverflow.ellipsis,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Preview ảnh
                            if (imageBytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  Uint8List.fromList(imageBytes!),
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (imageController.text.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '${widget.api.baseUrl}${imageController.text}',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 140,
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 140,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.withValues(alpha: 0.05),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.image_outlined, size: 36, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Chua co anh', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            // Tên file + nút tải
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    imageFileName ?? 'Chua chon file anh',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: imageFileName != null ? Colors.white70 : Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final result = await FilePicker.pickFiles(
                                        type: FileType.image,
                                        withData: true,
                                      );
                                      if (result != null && result.files.single.bytes != null) {
                                        final bytes = result.files.single.bytes!;
                                        final url = await widget.api.uploadFile(
                                          bytes,
                                          result.files.single.name,
                                        );
                                        setDialogState(() {
                                          imageController.text = url;
                                          imageFileName = result.files.single.name;
                                          imageBytes = bytes;
                                        });
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loi tai anh: $e')));
                                    }
                                  },
                                  icon: const Icon(Icons.upload_file_rounded),
                                  label: const Text('Tai len'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  audioFileName ?? 'Chua chon file audio',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: audioFileName != null ? Colors.white : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final result = await FilePicker.pickFiles(
                                    type: FileType.audio,
                                    withData: true,
                                  );
                                  if (result != null && result.files.single.bytes != null) {
                                    final url = await widget.api.uploadFile(
                                      result.files.single.bytes!,
                                      result.files.single.name,
                                    );
                                    setDialogState(() {
                                      audioController.text = url;
                                      audioFileName = result.files.single.name;
                                    });
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loi tai audio: $e')));
                                }
                              },
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text('Tai len'),
                            ),
                          ],
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
