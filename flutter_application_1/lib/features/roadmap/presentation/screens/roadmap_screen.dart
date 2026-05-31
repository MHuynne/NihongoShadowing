import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/features/roadmap/models/roadmap_model.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/chapter_section.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/roadmap_header.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:flutter_application_1/core/services/user_prefs_service.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  Future<RoadmapModel>? futureRoadmap;
  String? _userLevel; // level đã chọn khi onboarding
  bool _levelUpShown = false; // tránh hiện dialog nhiều lần

  static const _levelOrder = ['N5', 'N4', 'N3', 'N2', 'N1'];

  static String get _base => ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _initRoadmap();
  }

  Future<void> _initRoadmap() async {
    // Load level trước, rồi mới fetch roadmap
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

  // Trả về level tiếp theo (N5→N4→N3→N2→N1), null nếu đã là N1
  String? _nextLevel(String current) {
    final idx = _levelOrder.indexOf(current);
    if (idx == -1 || idx == _levelOrder.length - 1) return null;
    return _levelOrder[idx + 1];
  }

  // Hiện dialog chúc mừng và hỏi có muốn lên cấp không
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(
                'Hoàn thành ${levelNames[currentLevel] ?? currentLevel}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bạn đã chinh phục toàn bộ bài học $currentLevel. Tiếp tục chinh phục ${levelNames[nextLevel] ?? nextLevel} nhé!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D6D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    'Chuyển sang ${levelNames[nextLevel] ?? nextLevel} 🚀',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Ôn lại bài cũ',
                  style: TextStyle(
                      color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
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
      // ── Firebase UID ──────────────────────────────────────────────────
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'mock_user_id';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Firebase-UID': uid,
      };

      // ── Gọi song song: danh sách lessons + tiến độ user ──────────────
      final results = await Future.wait([
        http.get(Uri.parse('$_base/lessons/?limit=200'), headers: headers),
        http.get(Uri.parse('$_base/progress/'), headers: headers),
      ]);

      final lessonsResp  = results[0];
      final progressResp = results[1];

      if (lessonsResp.statusCode != 200) {
        throw Exception('Lessons API error ${lessonsResp.statusCode}');
      }

      final List<dynamic> lessonsData =
          json.decode(utf8.decode(lessonsResp.bodyBytes));

      // Map lessonId → progress record
      Map<int, Map<String, dynamic>> progressMap = {};
      if (progressResp.statusCode == 200) {
        final List<dynamic> progList =
            json.decode(utf8.decode(progressResp.bodyBytes));
        for (final p in progList) {
          progressMap[p['lesson_id'] as int] = p as Map<String, dynamic>;
        }
      }

      // ── Build grouped lessons ─────────────────────────────────────────
      const levelOrder = ['N5', 'N4', 'N3', 'N2', 'N1'];
      Map<String, List<LessonModel>> grouped = {};

      // ━━ Sort theo level rồi order_index trước khi build (phòng ngừa API trả sai thứ tự)
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
        final lessonId    = raw['id'] as int;
        final level       = raw['level']?.toString() ?? 'Khác';
        final chapterName = raw['chapter_name']?.toString() ?? 'Bài ${i + 1}';
        final orderIndex  = raw['order_index'] as int? ?? i;

        // Lấy topicId từ shadowing_topics đầu tiên của lesson
        final topics = raw['shadowing_topics'] as List<dynamic>? ?? [];
        final topicId = topics.isNotEmpty
            ? (topics.first['id'] as int? ?? 0)
            : 0;

        // Xác định trạng thái từ progress
        final prog = progressMap[lessonId];
        LessonStatus status;
        double? progress;

        if (prog == null) {
          // Chưa có record — chỉ bài đầu tiên mỗi level được mở
          final lessonsInLevel = grouped[level]?.length ?? 0;
          status = lessonsInLevel == 0 ? LessonStatus.inProgress : LessonStatus.locked;
        } else if (prog['lesson_completed'] == true) {
          status = LessonStatus.completed;
          progress = 1.0;
        } else {
          // Đang học dở: tính % tiến độ 3 bước
          status = LessonStatus.inProgress;
          int steps = 0;
          if (prog['flashcard_done'] == true) steps++;
          if (prog['test_passed'] == true) steps++;
          if (prog['shadowing_passed'] == true) steps++;
          progress = steps / 3.0;
        }

        // Mở khoá bài kế tiếp nếu bài trước đã completed
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
        ));
      }

      // ── Build chapters ────────────────────────────────────────────────
      List<ChapterModel> chapters = [];

      // Chỉ lấy các level mà user đã chọn
      final selectedLevel = _userLevel;
      final filteredLevels = selectedLevel != null
          ? [selectedLevel]  // chỉ hiển thị đúng level đã chọn
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

      final totalLessons    = chapters.expand((c) => c.lessons).length;
      final completedLessons = chapters
          .expand((c) => c.lessons)
          .where((l) => l.status == LessonStatus.completed)
          .length;

      // ── Kiểm tra hoàn thành cấp độ để đề xuất lên cấp ─────────────────
      if (_userLevel != null && chapters.isNotEmpty && !_levelUpShown) {
        final currentChapter = chapters.first;
        final allCompleted = currentChapter.lessons.isNotEmpty &&
            currentChapter.lessons
                .every((l) => l.status == LessonStatus.completed);
        final next = _nextLevel(_userLevel!);
        if (allCompleted && next != null) {
          // Hiện dialog sau khi build xong
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color(0xFFF3E5E7),
                    Color(0xFFEBDDE0),
                    Colors.white,
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          FutureBuilder<RoadmapModel>(
            future: futureRoadmap,
            builder: (context, snapshot) {
              if (futureRoadmap == null ||
                  snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingView();
              } else if (snapshot.hasError) {
                return _ErrorView(error: snapshot.error.toString());
              } else if (!snapshot.hasData) {
                return const Center(child: Text('Không có dữ liệu'));
              }

              final roadmap = snapshot.data!;
              return RefreshIndicator(
                onRefresh: () async {
                  await _initRoadmap();
                },
                color: AppColors.toriiRed,
                child: CustomScrollView(
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
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.toriiRed, const Color(0xFFE57373)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Đang tải lộ trình...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
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
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('Không thể kết nối',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}
