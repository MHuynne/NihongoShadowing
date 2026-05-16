import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

class AdminLessonsPage extends StatefulWidget {
  const AdminLessonsPage({
    super.key,
    required this.api,
    required this.onNavigateToVocab,
    required this.onNavigateToTopic,
  });

  final AdminApiService api;
  final ValueChanged<int> onNavigateToVocab;
  final ValueChanged<int> onNavigateToTopic;

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
        _lessons = lessons..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
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
    final isEditing = lesson != null;

    // ─── Bước 1: Thông tin bài học ────────────────────────────────
    final chapterController = TextEditingController(
        text: (lesson?['chapter_name'] ?? '').toString());
    String? level = lesson?['level']?.toString();

    // ─── Bước 2: Từ vựng ─────────────────────────────────────────
    final vocabs = <Map<String, String>>[
      {'word': '', 'reading': '', 'meaning': '', 'example': ''},
    ];

    // ─── Bước 3: Shadowing ───────────────────────────────────────
    final shadowTitleController = TextEditingController();
    final shadowScriptController = TextEditingController();
    final shadowAudioController = TextEditingController();
    String? shadowAudioFileName;
    String? shadowLevel = level;
    final segments = <Map<String, String>>[];

    int currentStep = 0;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDS) {
          // ── helper ──
          Widget _field(TextEditingController c, String label, {int maxLines = 1, TextInputType? kb}) =>
              TextField(
                controller: c,
                maxLines: maxLines,
                keyboardType: kb,
                decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
              );

          // ── Step 1: Bài học ──────────────────────────────────────
          Widget step1 = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(chapterController, 'Ten bai hoc'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: level,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Cap do', border: OutlineInputBorder()),
                items: ['N5', 'N4', 'N3', 'N2', 'N1']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setDS(() => level = v),
              ),
            ],
          );

          // ── Step 2: Từ vựng ──────────────────────────────────────
          Widget step2 = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Danh sach tu vung', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const Spacer(),
                  if (!isEditing)
                    TextButton.icon(
                      onPressed: () => setDS(() => vocabs.add({'word': '', 'reading': '', 'meaning': '', 'example': ''})),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Them tu'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(vocabs.length, (i) {
                final v = vocabs[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: TextField(
                        onChanged: (val) => v['word'] = val,
                        decoration: const InputDecoration(labelText: 'Tu / Kanji', border: OutlineInputBorder(), isDense: true),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(
                        onChanged: (val) => v['reading'] = val,
                        decoration: const InputDecoration(labelText: 'Reading', border: OutlineInputBorder(), isDense: true),
                      )),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (val) => v['meaning'] = val,
                      decoration: const InputDecoration(labelText: 'Nghia', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextField(
                        onChanged: (val) => v['example'] = val,
                        decoration: const InputDecoration(labelText: 'Vi du', border: OutlineInputBorder(), isDense: true),
                      )),
                      if (vocabs.length > 1)
                        IconButton(
                          onPressed: () => setDS(() => vocabs.removeAt(i)),
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        ),
                    ]),
                  ]),
                );
              }),
              if (!isEditing)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('* Co the bo qua buoc nay neu chua co tu vung', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
            ],
          );

          // ── Step 3: Shadowing ─────────────────────────────────────
          Widget step3 = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(shadowTitleController, 'Tieu de bai Shadowing'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: shadowLevel,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Cap do', border: OutlineInputBorder()),
                items: ['N5', 'N4', 'N3', 'N2', 'N1']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setDS(() => shadowLevel = v),
              ),
              const SizedBox(height: 12),
              _field(shadowScriptController, 'Script tieng Nhat', maxLines: 3),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.amber),
                  const SizedBox(width: 6),
                  const Text('Tao Audio AI tu Script', style: TextStyle(color: Colors.amber, fontSize: 12)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final script = shadowScriptController.text.trim();
                      if (script.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhap Script truoc!')));
                        return;
                      }
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Dang tao Audio AI...'),
                          duration: Duration(seconds: 15),
                        ));
                        final url = await widget.api.generateShadowingAudio(script: script);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        setDS(() {
                          shadowAudioController.text = url;
                          shadowAudioFileName = url.split('/').last;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tao audio thanh cong!')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loi: $e')));
                      }
                    },
                    icon: const Icon(Icons.record_voice_over_rounded, size: 14),
                    label: const Text('Tao ngay', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(
                  shadowAudioFileName ?? 'Chua co audio',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: shadowAudioFileName != null ? Colors.white70 : Colors.grey, fontSize: 12),
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                const Text('Segments', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setDS(() => segments.add({
                    'order_index': '${segments.length + 1}',
                    'start_time': '', 'end_time': '',
                    'kanji_content': '', 'furigana': '',
                    'romaji': '', 'sino_vietnamese': '', 'translation_vi': '',
                  })),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Them segment'),
                ),
              ]),
              ...List.generate(segments.length, (i) {
                final s = segments[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: TextField(onChanged: (v) => s['start_time'] = v,
                        decoration: const InputDecoration(labelText: 'Start (s)', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(onChanged: (v) => s['end_time'] = v,
                        decoration: const InputDecoration(labelText: 'End (s)', border: OutlineInputBorder(), isDense: true))),
                      IconButton(
                        onPressed: () => setDS(() => segments.removeAt(i)),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    TextField(onChanged: (v) => s['kanji_content'] = v,
                      decoration: const InputDecoration(labelText: 'Kanji / Noi dung', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: TextField(onChanged: (v) => s['romaji'] = v,
                        decoration: const InputDecoration(labelText: 'Romaji', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(onChanged: (v) => s['translation_vi'] = v,
                        decoration: const InputDecoration(labelText: 'Nghia', border: OutlineInputBorder(), isDense: true))),
                    ]),
                  ]),
                );
              }),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('* Co the bo qua buoc nay neu chua co shadowing', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          );

          final steps = [
            ('Thong tin bai hoc', step1),
            ('Tu vung', step2),
            ('Shadowing', step3),
          ];
          final isLast = currentStep == steps.length - 1;

          return AlertDialog(
            title: Text(isEditing ? 'Chinh sua bai hoc' : 'Tao bai hoc moi'),
            content: SizedBox(
              width: 680,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step indicator
                  Row(
                    children: List.generate(steps.length, (i) {
                      final active = i == currentStep;
                      final done = i < currentStep;
                      return Expanded(
                        child: Row(children: [
                          if (i > 0) Expanded(child: Divider(color: done ? Colors.deepPurpleAccent : Colors.white24, thickness: 2)),
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? Colors.deepPurpleAccent : done ? Colors.deepPurpleAccent.withValues(alpha: 0.5) : Colors.white12,
                            ),
                            child: Center(child: done
                                ? const Icon(Icons.check, size: 16)
                                : Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ]),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: steps.map((s) => Text(s.$1, style: const TextStyle(fontSize: 11, color: Colors.grey))).toList(),
                  ),
                  const SizedBox(height: 16),
                  Flexible(child: SingleChildScrollView(child: steps[currentStep].$2)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Huy'),
              ),
              if (currentStep > 0)
                OutlinedButton(
                  onPressed: () => setDS(() => currentStep--),
                  child: const Text('Quay lai'),
                ),
              FilledButton(
                onPressed: () {
                  if (isLast) {
                    Navigator.of(dialogContext).pop(true);
                  } else {
                    setDS(() => currentStep++);
                  }
                },
                child: Text(isLast ? 'Hoan tat & Luu' : 'Tiep theo'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    try {
      // Bước 1: Tạo / cập nhật bài học
      final lessonPayload = {
        'chapter_name': chapterController.text.trim(),
        'level': level,
        'vocabularies': <dynamic>[],
      };

      Map<String, dynamic> savedLesson;
      if (isEditing) {
        savedLesson = await widget.api.updateLesson(lesson['id'] as int, lessonPayload);
      } else {
        savedLesson = await widget.api.createLesson(lessonPayload);
      }
      final lessonId = savedLesson['id'] as int;

      // Bước 2: Tạo từ vựng (chỉ khi tạo mới, bỏ qua khi edit)
      if (!isEditing) {
        for (final v in vocabs) {
          if ((v['word'] ?? '').trim().isEmpty) continue;
          await widget.api.createVocabulary({
            'lesson_id': lessonId,
            'word': v['word']!.trim(),
            'reading': v['reading']!.trim().isEmpty ? null : v['reading']!.trim(),
            'meaning': v['meaning']!.trim(),
            'example': v['example']!.trim().isEmpty ? null : v['example']!.trim(),
          });
        }
      }

      // Bước 3: Tạo Shadowing Topic (nếu có tiêu đề)
      if (!isEditing && shadowTitleController.text.trim().isNotEmpty) {
        await widget.api.createTopic({
          'title': shadowTitleController.text.trim(),
          'level': shadowLevel,
          'lesson_id': lessonId,
          'full_audio_url': shadowAudioController.text.trim().isEmpty ? null : shadowAudioController.text.trim(),
          'full_script_ja': shadowScriptController.text.trim().isEmpty ? null : shadowScriptController.text.trim(),
          'segments': segments.where((s) => (s['kanji_content'] ?? '').trim().isNotEmpty).map((s) => {
            'order_index': int.tryParse(s['order_index'] ?? '') ?? 1,
            'start_time': double.tryParse(s['start_time'] ?? ''),
            'end_time': double.tryParse(s['end_time'] ?? ''),
            'kanji_content': s['kanji_content'],
            'furigana': s['furigana'],
            'romaji': s['romaji'],
            'sino_vietnamese': s['sino_vietnamese'],
            'translation_vi': s['translation_vi'],
          }).toList(),
        });
      }

      await _loadLessons();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Da luu bai hoc thanh cong!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Khong the luu: $e')),
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
            style: FilledButton.styleFrom(backgroundColor: AdminPalette.errorRed),
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
              Text(_error!, style: const TextStyle(color: AdminPalette.errorRed)));
    }

    if (_lessons.isEmpty) {
      return const AdminEmptyState(
        title: 'Chua co bai hoc nao',
        subtitle: 'Tao bai hoc dau tien de bat dau quan tri lo trinh hoc.',
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
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
                            tooltip: 'Tu vung',
                            onPressed: () => widget.onNavigateToVocab(lesson['id'] as int),
                            icon: const Icon(Icons.translate_rounded),
                          ),
                          IconButton(
                            tooltip: 'Shadowing',
                            onPressed: () => widget.onNavigateToTopic(lesson['id'] as int),
                            icon: const Icon(Icons.graphic_eq_rounded),
                          ),
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
      ),
    );
  }
}
