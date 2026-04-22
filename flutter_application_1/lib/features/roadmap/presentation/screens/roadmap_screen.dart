import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/features/roadmap/models/roadmap_model.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/chapter_section.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/roadmap_header.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  late Future<RoadmapModel> futureRoadmap;

  @override
  void initState() {
    super.initState();
    futureRoadmap = fetchRoadmap();
  }

  Future<RoadmapModel> fetchRoadmap() async {
    try {
      String apiUrl = 'http://localhost:8000/shadowing/topics/';
      try {
        if (!kIsWeb) {
          if (defaultTargetPlatform == TargetPlatform.android) {
            apiUrl = 'http://10.0.2.2:8000/shadowing/topics/';
          }
        }
      } catch (_) {}

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));

        Map<String, List<LessonModel>> groupedLessons = {};

        for (int i = 0; i < data.length; i++) {
          final jsonItem = data[i];
          final String level = jsonItem['level']?.toString() ?? 'Khác';
          final String topicTitle =
              jsonItem['title']?.toString() ?? 'Chưa có tên';
          final String id = jsonItem['id'].toString();

          // Assign statuses for demo: tiến tới học khóa 6
          LessonStatus status;
          final lessonsInLevel = groupedLessons[level]?.length ?? 0;
          if (lessonsInLevel < 5) {
            status = LessonStatus.completed; // Đã hoàn thành Bài 1 -> 5
          } else if (lessonsInLevel == 5) {
            status = LessonStatus.inProgress; // Đang học Bài 6
          } else {
            status = LessonStatus.locked; // Khóa các bài còn lại
          }

          final LessonModel lesson = LessonModel(
            id: id,
            title: topicTitle,
            subtitle: 'BÀI ${i + 1}',
            icon: _getIconForIndex(i),
            status: status,
          );

          if (!groupedLessons.containsKey(level)) {
            groupedLessons[level] = [];
          }
          groupedLessons[level]!.add(lesson);
        }

        List<ChapterModel> fetchedChapters = [];
        groupedLessons.forEach((level, lessons) {
          final completed =
              lessons.where((l) => l.status == LessonStatus.completed).length;
          fetchedChapters.add(
            ChapterModel(
              id: 'level_$level',
              title: 'Chặng $level – Sơ cấp',
              statusBadge: '$completed/${lessons.length} hoàn thành',
              isLocked: false,
              lessons: lessons,
            ),
          );
        });

        fetchedChapters.sort((a, b) => b.title.compareTo(a.title));

        final totalLessons = fetchedChapters
            .expand((c) => c.lessons)
            .length;
        final completedLessons = fetchedChapters
            .expand((c) => c.lessons)
            .where((l) => l.status == LessonStatus.completed)
            .length;

        return RoadmapModel(
          title: 'Chặng 1: N5 – Sơ cấp',
          totalProgress:
              totalLessons == 0 ? 0 : completedLessons / totalLessons,
          completedLessons: completedLessons,
          totalLessons: totalLessons,
          chapters: fetchedChapters,
        );
      } else {
        throw Exception('Failed to load lessons: ${response.statusCode}');
      }
    } catch (e) {
      return _getDummyRoadmap();
    }
  }

  IconData _getIconForIndex(int i) {
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
      title: 'Chặng 1: N5 – Sơ cấp',
      totalProgress: 0.35,
      completedLessons: 2,
      totalLessons: 6,
      chapters: [
        ChapterModel(
          id: 'n5',
          title: 'Chặng 1: N5 – Sơ cấp',
          statusBadge: '2/6 hoàn thành',
          isLocked: false,
          lessons: [
            LessonModel(
              id: '1',
              title: 'Chào hỏi cơ bản',
              subtitle: 'BÀI 1',
              icon: Icons.waving_hand_rounded,
              status: LessonStatus.completed,
            ),
            LessonModel(
              id: '2',
              title: 'Bảng chữ cái Hiragana',
              subtitle: 'BÀI 2',
              icon: Icons.menu_book_rounded,
              status: LessonStatus.completed,
            ),
            LessonModel(
              id: '3',
              title: 'Luyện nghe Shadowing',
              subtitle: 'BÀI 3',
              icon: Icons.headphones_rounded,
              status: LessonStatus.inProgress,
            ),
            LessonModel(
              id: '4',
              title: 'Giới thiệu bản thân',
              subtitle: 'BÀI 4',
              icon: Icons.people_rounded,
              status: LessonStatus.locked,
            ),
            LessonModel(
              id: '5',
              title: 'Ôn tập N5 Level 1',
              subtitle: 'BÀI 5',
              icon: Icons.quiz_rounded,
              status: LessonStatus.locked,
            ),
            LessonModel(
              id: '6',
              title: 'Kiểm tra từ vựng',
              subtitle: 'BÀI 6',
              icon: Icons.translate_rounded,
              status: LessonStatus.locked,
            ),
          ],
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
          // Background Light Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color(0xFFF3E5E7), // Soft dusty pink
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingView();
              } else if (snapshot.hasError) {
                return _ErrorView(error: snapshot.error.toString());
              } else if (!snapshot.hasData) {
                return const Center(child: Text('Không có dữ liệu'));
              }
    
              final roadmap = snapshot.data!;
              return CustomScrollView(
                slivers: [
                  // Sticky gradient header
                  SliverToBoxAdapter(
                    child: RoadmapHeader(
                      title: roadmap.title,
                      progress: roadmap.totalProgress,
                      completed: roadmap.completedLessons,
                      total: roadmap.totalLessons,
                    ),
                  ),
    
                  // Chapters list
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ChapterSection(
                              chapter: roadmap.chapters[index]);
                        },
                        childCount: roadmap.chapters.length,
                      ),
                    ),
                  ),
    
                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
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
            Text(
              'Đang tải lộ trình...',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
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
            const Text(
              'Không thể kết nối',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
