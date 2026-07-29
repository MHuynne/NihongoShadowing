import 'package:flutter/material.dart';
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

  Future<void> _openTopicDialog([Map<String, dynamic>? topic]) async {
    final titleController = TextEditingController(
      text: (topic?['title'] ?? '').toString(),
    );
    String? level = topic?['level']?.toString();
    String? lessonId = topic?['lesson_id']?.toString();

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
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              backgroundColor: AdminPalette.surfaceMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
              ),
              content: SizedBox(
                width: 760,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _twoColumn(
                        TextField(
                          controller: titleController,
                          decoration: _inputDeco('Tên chủ đề'),
                        ),
                        DropdownButtonFormField<String>(
                          value: level,
                          decoration: _inputDeco('Cấp độ JLPT'),
                          dropdownColor: AdminPalette.surfaceMuted,
                          items: const ['N5', 'N4', 'N3', 'N2', 'N1']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) => setDialogState(() => level = v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: _lessons.any((l) => l['id'].toString() == lessonId) ? lessonId : null,
                        decoration: _inputDeco('Gán vào Lesson (tuỳ chọn)'),
                        dropdownColor: AdminPalette.surfaceMuted,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Không chọn bài học'),
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
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text(
                            'Các câu Shadowing',
                            style: TextStyle(
                              fontSize: 15,
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
                            icon: const Icon(Icons.add_rounded, size: 16, color: AdminPalette.topicAccent),
                            label: const Text('Thêm câu', style: TextStyle(color: AdminPalette.topicAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(segments.length, (index) {
                        final seg = segments[index];
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
                                    'Câu ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (segments.length > 1)
                                    IconButton(
                                      onPressed: () => setDialogState(() => segments.removeAt(index)),
                                      icon: const Icon(Icons.delete_outline_rounded, color: AdminPalette.errorRed, size: 18),
                                      tooltip: 'Xóa câu này',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                initialValue: seg['kanji_content'],
                                onChanged: (v) => seg['kanji_content'] = v,
                                decoration: _inputDeco('漢字 — Câu gốc (có Kanji)'),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                initialValue: seg['furigana'],
                                onChanged: (v) => seg['furigana'] = v,
                                decoration: _inputDeco('Furigana — Phiên âm Hiragana'),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                initialValue: seg['translation_vi'],
                                onChanged: (v) => seg['translation_vi'] = v,
                                decoration: _inputDeco('Dịch nghĩa tiếng Việt'),
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
                  child: const Text('Hủy'),
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
        title: const Text('Xóa topic?'),
        content: Text(
          'Topic "${topic['title'] ?? ''}" sẽ bị xóa cùng các segment và vocabulary liên quan.',
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
      await widget.api.deleteTopic(topic['id'] as int);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa topic: $e')),
      );
    }
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
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
                  title: 'Shadowing Topics',
                  subtitle: 'Quản lý topic, segment và vocabulary cho bài Shadowing.',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<int?>(
                  isExpanded: true,
                  value: (_selectedLessonId == null || _selectedLessonId == -1 || _lessons.any((l) => l['id'] == _selectedLessonId)) ? _selectedLessonId : null,
                  decoration: _inputDeco('Lọc theo bài học', isDense: true),
                  dropdownColor: AdminPalette.surfaceMuted,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả bài học'),
                    ),
                    const DropdownMenuItem<int?>(
                      value: -1,
                      child: Text('Topic độc lập'),
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
                    setState(() {
                      _selectedLessonId = value;
                      _applyFilter();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              AdminPrimaryButton(
                label: 'Thêm topic',
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

    if (_topics.isEmpty) {
      return const AdminEmptyState(
        title: 'Chưa có topic shadowing nào',
        subtitle: 'Thêm topic mới để người học có nội dung luyện nghe nói.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final topic = _topics[index];
        final segments = (topic['segments'] as List?) ?? const [];

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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AdminPalette.topicSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminPalette.topicAccent.withOpacity(0.2), width: 0.8),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: AdminPalette.topicAccent,
                  size: 24,
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
                            (topic['title'] ?? 'Không tên').toString(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AdminPalette.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        _badge('JLPT ${topic['level'] ?? 'N/A'}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _metaChip(Icons.layers_rounded, 'Mã Lesson: ${topic['lesson_id'] ?? 'Không'}'),
                        _metaChip(Icons.list_alt_rounded, '${segments.length} câu'),
                        if (topic['total_duration'] != null)
                          _metaChip(Icons.schedule_rounded, '${topic['total_duration']}s'),
                      ],
                    ),
                    if ((topic['full_script_ja'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        (topic['full_script_ja'] ?? '').toString(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AdminPalette.textSecondary,
                          height: 1.5,
                          fontSize: 13,
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
                    onPressed: () => _openTopicDialog(topic),
                    icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: () => _deleteTopic(topic),
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

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AdminPalette.topicSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminPalette.topicAccent.withOpacity(0.2), width: 0.8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AdminPalette.topicAccent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.8),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}