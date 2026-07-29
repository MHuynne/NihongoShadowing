import 'package:flutter/material.dart';
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
        const levelWeights = {'N5': 1, 'N4': 2, 'N3': 3, 'N2': 4, 'N1': 5};
        _lessons = lessons..sort((a, b) {
          final lvlA = a['level']?.toString() ?? 'N5';
          final lvlB = b['level']?.toString() ?? 'N5';
          final weightA = levelWeights[lvlA] ?? 99;
          final weightB = levelWeights[lvlB] ?? 99;
          if (weightA != weightB) {
            return weightA.compareTo(weightB);
          }
          final orderA = a['order_index'] as int? ?? 99999;
          final orderB = b['order_index'] as int? ?? 99999;
          if (orderA != orderB) {
            return orderA.compareTo(orderB);
          }
          return (a['id'] as int).compareTo(b['id'] as int);
        });
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


    final chapterController = TextEditingController(
        text: (lesson?['chapter_name'] ?? '').toString());
    String? level = lesson?['level']?.toString();
    final orderController = TextEditingController(
        text: (lesson?['order_index'] ?? '').toString());


    final vocabs = <Map<String, String>>[];


    final shadowTitleController = TextEditingController();
    final shadowScriptController = TextEditingController();
    final shadowAudioController = TextEditingController();
    String? shadowAudioFileName;
    String? shadowLevel = level;
    final segments = <Map<String, String>>[];

    if (isEditing) {

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            color: AdminPalette.surface,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AdminPalette.sidebarSelectedForeground),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải dữ liệu bài học...',
                    style: TextStyle(color: AdminPalette.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final lessonId = lesson['id'] as int;
        final results = await Future.wait([
          widget.api.fetchVocabularies(lessonId: lessonId),
          widget.api.fetchTopics(),
        ]);

        final loadedVocabs = results[0] as List;
        final loadedTopics = results[1] as List;


        if (mounted) {
          Navigator.of(context).pop();
        }

        if (loadedVocabs.isNotEmpty) {
          for (final v in loadedVocabs) {
            vocabs.add({
              'word': (v['word'] ?? '').toString(),
              'reading': (v['reading'] ?? '').toString(),
              'meaning': (v['meaning'] ?? '').toString(),
              'example': (v['example'] ?? '').toString(),
            });
          }
        } else {
          vocabs.add({'word': '', 'reading': '', 'meaning': '', 'example': ''});
        }

        final existingTopic = loadedTopics.firstWhere(
          (t) => t['lesson_id'] == lessonId,
          orElse: () => <String, dynamic>{},
        );

        if (existingTopic.isNotEmpty) {
          shadowTitleController.text = (existingTopic['title'] ?? '').toString();
          shadowScriptController.text = (existingTopic['full_script_ja'] ?? '').toString();
          shadowAudioController.text = (existingTopic['full_audio_url'] ?? '').toString();
          if (shadowAudioController.text.isNotEmpty) {
            shadowAudioFileName = shadowAudioController.text.split('/').last;
          }
          shadowLevel = (existingTopic['level'] ?? lesson['level'])?.toString();

          final rawSegs = existingTopic['segments'];
          if (rawSegs is List && rawSegs.isNotEmpty) {
            for (final s in rawSegs) {
              final m = Map<String, dynamic>.from(s as Map);
              segments.add({
                'order_index': (m['order_index'] ?? '').toString(),
                'start_time': (m['start_time'] ?? '').toString(),
                'end_time': (m['end_time'] ?? '').toString(),
                'kanji_content': (m['kanji_content'] ?? '').toString(),
                'furigana': (m['furigana'] ?? '').toString(),
                'romaji': (m['romaji'] ?? '').toString(),
                'sino_vietnamese': (m['sino_vietnamese'] ?? '').toString(),
                'translation_vi': (m['translation_vi'] ?? '').toString(),
              });
            }
          }
        }
      } catch (e) {

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải dữ liệu bài học: $e')),
          );
        }
        return;
      }
    } else {
      vocabs.add({'word': '', 'reading': '', 'meaning': '', 'example': ''});
    }

    int currentStep = 0;

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDS) {

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

          Widget buildField(TextEditingController c, String label, {int maxLines = 1, TextInputType? kb}) =>
              TextField(
                controller: c,
                maxLines: maxLines,
                keyboardType: kb,
                decoration: _inputDeco(label),
              );

          bool isGeneratingAudio = false;

          Widget step1 = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildField(chapterController, 'Tên bài học'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: level,
                isExpanded: true,
                decoration: _inputDeco('Cấp độ'),
                dropdownColor: AdminPalette.surfaceMuted,
                items: ['N5', 'N4', 'N3', 'N2', 'N1']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setDS(() => level = v),
              ),
              const SizedBox(height: 16),
              buildField(orderController, 'Thứ tự hiển thị', kb: TextInputType.number),
            ],
          );

          Widget step2 = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Danh sách từ vựng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setDS(() => vocabs.add({'word': '', 'reading': '', 'meaning': '', 'example': ''})),
                    icon: const Icon(Icons.add_rounded, size: 16, color: AdminPalette.vocabularyAccent),
                    label: const Text('Thêm từ', style: TextStyle(color: AdminPalette.vocabularyAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...List.generate(vocabs.length, (i) {
                final v = vocabs[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.015),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: TextFormField(
                        initialValue: v['word'],
                        onChanged: (val) => v['word'] = val,
                        decoration: _inputDeco('Từ / Kanji', isDense: true),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(
                        initialValue: v['reading'],
                        onChanged: (val) => v['reading'] = val,
                        decoration: _inputDeco('Reading', isDense: true),
                      )),
                    ]),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: v['meaning'],
                      onChanged: (val) => v['meaning'] = val,
                      decoration: _inputDeco('Nghĩa', isDense: true),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextFormField(
                        initialValue: v['example'],
                        onChanged: (val) => v['example'] = val,
                        decoration: _inputDeco('Ví dụ', isDense: true),
                      )),
                      if (vocabs.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setDS(() => vocabs.removeAt(i)),
                          icon: const Icon(Icons.delete_outline_rounded, color: AdminPalette.errorRed, size: 20),
                        ),
                      ],
                    ]),
                  ]),
                );
              }),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('* Có thể bỏ qua hoặc để trống nếu chưa có từ vựng', style: TextStyle(color: AdminPalette.textMuted, fontSize: 12)),
              ),
            ],
          );

          Widget step3 = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildField(shadowTitleController, 'Tiêu đề bài Shadowing'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: shadowLevel,
                isExpanded: true,
                decoration: _inputDeco('Cấp độ'),
                dropdownColor: AdminPalette.surfaceMuted,
                items: ['N5', 'N4', 'N3', 'N2', 'N1']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setDS(() => shadowLevel = v),
              ),
              const SizedBox(height: 16),
              buildField(shadowScriptController, 'Script tiếng Nhật', maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Text('Tạo Audio AI từ Script', style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (isGeneratingAudio)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SoundwaveVisualizer(),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        final script = shadowScriptController.text.trim();
                        final scMessenger = ScaffoldMessenger.of(context);
                        if (script.isEmpty) {
                          scMessenger.showSnackBar(const SnackBar(content: Text('Nhập Script trước!')));
                          return;
                        }
                        try {
                          setDS(() => isGeneratingAudio = true);
                          final url = await widget.api.generateShadowingAudio(script: script);
                          setDS(() {
                            shadowAudioController.text = url;
                            shadowAudioFileName = url.split('/').last;
                            isGeneratingAudio = false;
                          });
                          scMessenger.showSnackBar(const SnackBar(content: Text('Tạo audio thành công!')));
                        } catch (e) {
                          setDS(() => isGeneratingAudio = false);
                          scMessenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                        }
                      },
                      icon: const Icon(Icons.record_voice_over_rounded, size: 14, color: Colors.white),
                      label: const Text('Tạo ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Text(
                  shadowAudioFileName ?? 'Chưa có file audio',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: shadowAudioFileName != null ? Colors.white70 : AdminPalette.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                )),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                const Text('Phân đoạn câu (Segments)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setDS(() => segments.add({
                    'order_index': '${segments.length + 1}',
                    'start_time': '', 'end_time': '',
                    'kanji_content': '', 'furigana': '',
                    'romaji': '', 'sino_vietnamese': '', 'translation_vi': '',
                  })),
                  icon: const Icon(Icons.add_rounded, size: 15, color: AdminPalette.topicAccent),
                  label: const Text('Thêm câu', style: TextStyle(fontSize: 12, color: AdminPalette.topicAccent, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 8),
              ...List.generate(segments.length, (i) {
                final s = segments[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.015),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: TextFormField(
                        initialValue: s['kanji_content'],
                        onChanged: (v) => s['kanji_content'] = v,
                        decoration: _inputDeco('Kanji / Nội dung', isDense: true))),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setDS(() => segments.removeAt(i)),
                        icon: const Icon(Icons.delete_outline_rounded, color: AdminPalette.errorRed, size: 18),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(
                        initialValue: s['romaji'],
                        onChanged: (v) => s['romaji'] = v,
                        decoration: _inputDeco('Romaji', isDense: true))),
                      const SizedBox(width: 10),
                      Expanded(child: TextFormField(
                        initialValue: s['translation_vi'],
                        onChanged: (v) => s['translation_vi'] = v,
                        decoration: _inputDeco('Nghĩa tiếng Việt', isDense: true))),
                    ]),
                  ]),
                );
              }),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('* Có thể bỏ qua bước này nếu chưa có Shadowing', style: TextStyle(color: AdminPalette.textMuted, fontSize: 12)),
              ),
            ],
          );

          final steps = [
            ('Thông tin bài học', step1),
            ('Từ vựng', step2),
            ('Shadowing', step3),
          ];
          final isLast = currentStep == steps.length - 1;

          return AlertDialog(
            title: Text(
              isEditing ? 'Chỉnh sửa bài học' : 'Tạo bài học mới',
              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            backgroundColor: AdminPalette.surfaceMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
            ),
            content: SizedBox(
              width: 680,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: List.generate(steps.length, (i) {
                      final active = i == currentStep;
                      final done = i < currentStep;
                      final stepColor = active
                          ? AdminPalette.sidebarSelectedForeground
                          : done
                              ? AdminPalette.sidebarSelectedForeground.withOpacity(0.5)
                              : Colors.white12;
                      return Expanded(
                        child: Row(children: [
                          if (i > 0)
                            Expanded(
                              child: Divider(
                                color: done ? AdminPalette.sidebarSelectedForeground : Colors.white10,
                                thickness: 2,
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? AdminPalette.sidebarSelectedForeground : Colors.transparent,
                              border: Border.all(
                                color: stepColor,
                                width: 2,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: AdminPalette.sidebarSelectedForeground.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: done
                                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: active ? Colors.white : Colors.white54,
                                      ),
                                    ),
                            ),
                          ),
                        ]),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: steps.map((s) => Text(s.$1, style: const TextStyle(fontSize: 11, color: AdminPalette.textMuted, fontWeight: FontWeight.w600))).toList(),
                  ),
                  const SizedBox(height: 20),
                  Flexible(child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: steps[currentStep].$2)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Hủy'),
              ),
              if (currentStep > 0)
                OutlinedButton(
                  onPressed: () => setDS(() => currentStep--),
                  child: const Text('Quay lại'),
                ),
              FilledButton(
                onPressed: () {
                  if (currentStep == 0) {
                    if (chapterController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập tên bài học!')),
                      );
                      return;
                    }
                    if (level == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn cấp độ cho bài học!')),
                      );
                      return;
                    }
                  } else if (currentStep == 1) {

                    for (int i = 0; i < vocabs.length; i++) {
                      final v = vocabs[i];
                      final word = (v['word'] ?? '').trim();
                      final reading = (v['reading'] ?? '').trim();
                      final meaning = (v['meaning'] ?? '').trim();
                      final example = (v['example'] ?? '').trim();
                      final hasAnyInput = word.isNotEmpty || reading.isNotEmpty || meaning.isNotEmpty || example.isNotEmpty;

                      if (hasAnyInput) {
                        if (word.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Vui lòng nhập Từ/Kanji ở dòng số ${i + 1}!')),
                          );
                          return;
                        }
                        if (meaning.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Vui lòng nhập Nghĩa ở dòng số ${i + 1}!')),
                          );
                          return;
                        }
                      }
                    }
                  }

                  if (isLast) {
                    Navigator.of(dialogContext).pop(true);
                  } else {
                    setDS(() => currentStep++);
                  }
                },
                child: Text(isLast ? 'Hoàn tất & Lưu' : 'Tiếp theo'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    try {

      final lessonPayload = {
        'chapter_name': chapterController.text.trim(),
        'level': level,
        'order_index': int.tryParse(orderController.text.trim()),
        'vocabularies': <dynamic>[],
      };

      Map<String, dynamic> savedLesson;
      if (isEditing) {
        savedLesson = await widget.api.updateLesson(lesson['id'] as int, lessonPayload);
      } else {
        savedLesson = await widget.api.createLesson(lessonPayload);
      }
      final lessonId = savedLesson['id'] as int;


      if (isEditing) {
        final existingVocabs = await widget.api.fetchVocabularies(lessonId: lessonId);
        for (final ev in existingVocabs) {
          await widget.api.deleteVocabulary(ev['id'] as int);
        }
      }

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


      if (isEditing) {
        final loadedTopics = await widget.api.fetchTopics();
        final existingTopic = loadedTopics.firstWhere(
          (t) => t['lesson_id'] == lessonId,
          orElse: () => <String, dynamic>{},
        );

        if (existingTopic.isEmpty) {
          if (shadowTitleController.text.trim().isNotEmpty) {
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
        } else {
          await widget.api.updateTopic(existingTopic['id'] as int, {
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
      } else {
        if (shadowTitleController.text.trim().isNotEmpty) {
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
      }

      await _loadLessons();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu bài học thành công!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu: $e')),
      );
    }
  }

  Future<void> _deleteLesson(Map<String, dynamic> lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài học?'),
        content: Text(
          'Bài học "${lesson['chapter_name'] ?? 'Không tên'}" sẽ bị xóa khỏi hệ thống.',
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
      await widget.api.deleteLesson(lesson['id'] as int);
      await _loadLessons();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa bài học: $e')),
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
            title: 'Bài học',
            subtitle: 'Thêm, sửa và xóa lesson đang lưu trong MySQL Laragon.',
            action: AdminPrimaryButton(
              label: 'Thêm bài học',
              onPressed: _openLessonDialog,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(String level) {
    Color color = Colors.grey;
    Color bg = Colors.grey.withOpacity(0.1);
    switch (level) {
      case 'N5':
        color = const Color(0xFF10B981);
        bg = const Color(0x1F10B981);
        break;
      case 'N4':
        color = const Color(0xFF3B82F6);
        bg = const Color(0x1F3B82F6);
        break;
      case 'N3':
        color = const Color(0xFFEC4899);
        bg = const Color(0x1FEC4899);
        break;
      case 'N2':
        color = const Color(0xFFF59E0B);
        bg = const Color(0x1FF59E0B);
        break;
      case 'N1':
        color = const Color(0xFFEF4444);
        bg = const Color(0x1FEF4444);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        level,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800),
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

    if (_lessons.isEmpty) {
      return const AdminEmptyState(
        title: 'Chưa có bài học nào',
        subtitle: 'Tạo bài học đầu tiên để bắt đầu quản trị lộ trình học.',
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
                columnSpacing: 36,
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Tên bài học')),
                  DataColumn(label: Text('Cấp độ')),
                  DataColumn(label: Text('Thứ tự')),
                  DataColumn(label: Text('Hành động')),
                ],
                rows: _lessons
                    .map(
                      (lesson) => DataRow(
                        cells: [
                          DataCell(Text('${lesson['id']}', style: const TextStyle(color: AdminPalette.textMuted))),
                          DataCell(Text((lesson['chapter_name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white))),
                          DataCell(_buildLevelBadge((lesson['level'] ?? 'N/A').toString())),
                          DataCell(Text('${lesson['order_index'] ?? '-'}')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Từ vựng',
                                  onPressed: () => widget.onNavigateToVocab(lesson['id'] as int),
                                  icon: const Icon(Icons.translate_rounded, color: AdminPalette.vocabularyAccent, size: 19),
                                ),
                                IconButton(
                                  tooltip: 'Shadowing',
                                  onPressed: () => widget.onNavigateToTopic(lesson['id'] as int),
                                  icon: const Icon(Icons.graphic_eq_rounded, color: AdminPalette.topicAccent, size: 19),
                                ),
                                IconButton(
                                  tooltip: 'Sửa',
                                  onPressed: () => _openLessonDialog(lesson),
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 19),
                                ),
                                IconButton(
                                  tooltip: 'Xóa',
                                  onPressed: () => _deleteLesson(lesson),
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