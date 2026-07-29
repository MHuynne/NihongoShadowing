import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/features/roadmap/models/roadmap_model.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/chapter_section.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/roadmap_header.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';
import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:flutter_application_1/core/services/user_prefs_service.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  Future<RoadmapModel>? futureRoadmap;
  String? _userLevel;
  bool _levelUpShown = false;

  static const _levelOrder = ['N5', 'N4', 'N3', 'N2', 'N1'];

  static String get _base => ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _initRoadmap();
  }

  Future<void> _initRoadmap() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final level = await UserPrefsService().getLevel(uid);
      if (mounted) {
        setState(() => _userLevel = level ?? 'N5');
      }
    } else {
      _userLevel = 'N5';
    }
    if (mounted) {
      setState(() {
        futureRoadmap = _fetchRoadmap();
      });
    }
  }

  String? _nextLevel(String current) {
    final idx = _levelOrder.indexOf(current);
    if (idx == -1 || idx == _levelOrder.length - 1) return null;
    return _levelOrder[idx + 1];
  }

  Future<void> _showLevelUpDialog(String currentLevel, String nextLevel) async {
    if (!mounted || _levelUpShown) return;
    _levelUpShown = true;

    final levelNames = {
      'N5': 'N5 (Sơ cấp)',
      'N4': 'N4 (Tiền trung cấp)',
      'N3': 'N3 (Trung cấp)',
      'N2': 'N2 (Thượng trung cấp)',
      'N1': 'N1 (Cao cấp)',
    };

    final shouldAdvance = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E0F38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: SNJ.borderNeon, width: 1.5),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: SNJ.sakura.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => SNJ.sakuraGradient.createShader(bounds),
                child: const Text('🌸', style: TextStyle(fontSize: 64)),
              ),
              const SizedBox(height: 16),
              Text(
                'Hoàn thành ${levelNames[currentLevel] ?? currentLevel}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bạn đã chinh phục toàn bộ bài học $currentLevel. Tiếp tục hành trình với ${levelNames[nextLevel] ?? nextLevel} nhé!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFCCB8D8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: SNJ.sakuraGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: SNJ.sakura.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'Chuyển sang ${levelNames[nextLevel] ?? nextLevel} 🚀',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Ôn lại bài cũ',
                  style: TextStyle(
                    color: Color(0xFF8877A0),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldAdvance == true && mounted) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await UserPrefsService().saveLevel(uid, nextLevel);
      }
      setState(() {
        _userLevel = nextLevel;
        _levelUpShown = false;
        futureRoadmap = _fetchRoadmap();
      });
    } else {
      _levelUpShown = false;
    }
  }

  Future<RoadmapModel> _fetchRoadmap() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'mock_user_id';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Firebase-UID': uid,
      };

      final results = await Future.wait([
        http.get(Uri.parse('$_base/lessons/?limit=200'), headers: headers),
        http.get(Uri.parse('$_base/progress/'), headers: headers),
      ]);

      final lessonsResp = results[0];
      final progressResp = results[1];

      if (lessonsResp.statusCode != 200) {
        throw Exception('Lessons API error ${lessonsResp.statusCode}');
      }

      final List<dynamic> lessonsData =
          json.decode(utf8.decode(lessonsResp.bodyBytes));

      Map<int, Map<String, dynamic>> progressMap = {};
      if (progressResp.statusCode == 200) {
        final List<dynamic> progList =
            json.decode(utf8.decode(progressResp.bodyBytes));
        for (final p in progList) {
          progressMap[p['lesson_id'] as int] = p as Map<String, dynamic>;
        }
      }

      const levelOrder = ['N5', 'N4', 'N3', 'N2', 'N1'];
      Map<String, List<LessonModel>> grouped = {};

      final sortedLessons = [...lessonsData];
      sortedLessons.sort((a, b) {
        final aRaw = a as Map<String, dynamic>;
        final bRaw = b as Map<String, dynamic>;
        final aLevel = levelOrder.indexOf(aRaw['level']?.toString() ?? '');
        final bLevel = levelOrder.indexOf(bRaw['level']?.toString() ?? '');
        if (aLevel != bLevel) return aLevel.compareTo(bLevel);
        final aOrder = aRaw['order_index'] as int? ?? 0;
        final bOrder = bRaw['order_index'] as int? ?? 0;
        return aOrder.compareTo(bOrder);
      });

      for (int i = 0; i < sortedLessons.length; i++) {
        final raw = sortedLessons[i] as Map<String, dynamic>;
        final lessonId = raw['id'] as int;
        final level = raw['level']?.toString() ?? 'Khác';
        final chapterName = raw['chapter_name']?.toString() ?? 'Bài ${i + 1}';
        final orderIndex = raw['order_index'] as int? ?? i;

        final topics = raw['shadowing_topics'] as List<dynamic>? ?? [];
        final topicId = topics.isNotEmpty
            ? (topics.first['id'] as int? ?? 0)
            : 0;

        final prog = progressMap[lessonId];
        LessonStatus status;
        double? progress;
        bool flashcardDone = false;
        bool testPassed = false;

        if (prog == null) {
          final lessonsInLevel = grouped[level]?.length ?? 0;
          status = lessonsInLevel == 0 ? LessonStatus.inProgress : LessonStatus.locked;
        } else if (prog['lesson_completed'] == true) {
          status = LessonStatus.completed;
          progress = 1.0;
          flashcardDone = true;
          testPassed = true;
        } else {
          status = LessonStatus.inProgress;
          flashcardDone = prog['flashcard_done'] == true;
          testPassed = prog['test_passed'] == true;
          int steps = 0;
          if (flashcardDone) steps++;
          if (testPassed) steps++;
          if (prog['shadowing_passed'] == true) steps++;
          progress = steps / 3.0;
        }

        if (status == LessonStatus.locked) {
          final prevLessons = grouped[level] ?? [];
          if (prevLessons.isNotEmpty &&
              prevLessons.last.status == LessonStatus.completed) {
            status = LessonStatus.inProgress;
          }
        }

        grouped.putIfAbsent(level, () => []).add(LessonModel(
          id: lessonId.toString(),
          lessonId: lessonId,
          topicId: topicId,
          title: chapterName,
          subtitle: 'BÀI $orderIndex',
          icon: _iconForIndex(i),
          status: status,
          progress: progress,
          flashcardDone: flashcardDone,
          testPassed: testPassed,
        ));
      }

      List<ChapterModel> chapters = [];

      final selectedLevel = _userLevel;
      final filteredLevels = selectedLevel != null
          ? [selectedLevel]
          : levelOrder.where((l) => grouped.containsKey(l)).toList();

      final sortedLevels = filteredLevels
          .where((l) => grouped.containsKey(l))
          .toList();

      for (final level in sortedLevels) {
        final lessons = grouped[level]!;
        final completed =
            lessons.where((l) => l.status == LessonStatus.completed).length;
        chapters.add(ChapterModel(
          id: 'level_$level',
          title: 'Chặng $level',
          statusBadge: '$completed/${lessons.length} hoàn thành',
          isLocked: lessons.every((l) => l.status == LessonStatus.locked),
          lessons: lessons,
        ));
      }

      final totalLessons = chapters.expand((c) => c.lessons).length;
      final completedLessons = chapters
          .expand((c) => c.lessons)
          .where((l) => l.status == LessonStatus.completed)
          .length;

      if (_userLevel != null && chapters.isNotEmpty && !_levelUpShown) {
        final currentChapter = chapters.first;
        final allCompleted = currentChapter.lessons.isNotEmpty &&
            currentChapter.lessons
                .every((l) => l.status == LessonStatus.completed);
        final next = _nextLevel(_userLevel!);
        if (allCompleted && next != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showLevelUpDialog(_userLevel!, next);
          });
        }
      }

      return RoadmapModel(
        title: 'Lộ trình học tiếng Nhật',
        totalProgress: totalLessons == 0 ? 0 : completedLessons / totalLessons,
        completedLessons: completedLessons,
        totalLessons: totalLessons,
        chapters: chapters,
      );
    } catch (e) {
      debugPrint('[RoadmapScreen] fetchRoadmap error: $e');
      return _getDummyRoadmap();
    }
  }

  IconData _iconForIndex(int i) {
    const icons = [
      Icons.waving_hand_rounded,
      Icons.menu_book_rounded,
      Icons.headphones_rounded,
      Icons.people_rounded,
      Icons.quiz_rounded,
      Icons.translate_rounded,
      Icons.record_voice_over_rounded,
      Icons.star_rounded,
    ];
    return icons[i % icons.length];
  }

  RoadmapModel _getDummyRoadmap() {
    return RoadmapModel(
      title: 'Lộ trình học tiếng Nhật',
      totalProgress: 0,
      completedLessons: 0,
      totalLessons: 0,
      chapters: [
        ChapterModel(
          id: 'n5',
          title: 'Chặng N5 – Sơ cấp',
          statusBadge: '0/0 hoàn thành',
          isLocked: false,
          lessons: const [],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SakuraNightBackground(
        child: FutureBuilder<RoadmapModel>(
          future: futureRoadmap,
          builder: (context, snapshot) {
            if (futureRoadmap == null ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingView();
            } else if (snapshot.hasError) {
              return _ErrorView(error: snapshot.error.toString());
            } else if (!snapshot.hasData) {
              return const Center(
                child: Text(
                  'Không có dữ liệu',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final roadmap = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                await _initRoadmap();
              },
              color: SNJ.sakura,
              backgroundColor: const Color(0xFF1E0F38),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: RoadmapHeader(
                      title: roadmap.title,
                      progress: roadmap.totalProgress,
                      completed: roadmap.completedLessons,
                      total: roadmap.totalLessons,
                      levelBadge: _userLevel,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ChapterSection(
                            chapter: roadmap.chapters[index]),
                        childCount: roadmap.chapters.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: SNJ.sakura,
            backgroundColor: SNJ.sakuraSoft,
          ),
          const SizedBox(height: 20),
          const Text(
            'Đang tải lộ trình học...',
            style: TextStyle(
              color: Color(0xFFCCB8D8),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Color(0xFF8877A0),
            ),
            const SizedBox(height: 18),
            const Text(
              'Không thể kết nối',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFCCB8D8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}