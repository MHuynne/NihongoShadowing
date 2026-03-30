import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/roadmap/models/roadmap_model.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/chapter_section.dart';
import 'package:flutter_application_1/features/roadmap/presentation/components/roadmap_header.dart';

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
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/lessons/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        
        // Nhóm các bài học (lessons từ API) vào 1 danh sách
        List<LessonModel> fetchedLessons = data.map((json) {
          return LessonModel(
            id: json['id'].toString(),
            title: json['chapter_name'] ?? 'Không có tên bài',
            subtitle: 'Level: ${json['level'] ?? 'N/A'}',
            icon: Icons.menu_book_rounded,
            status: LessonStatus.completed, 
          );
        }).toList();

        return RoadmapModel(
          title: 'Lộ trình chi tiết',
          totalProgress: 0.5,
          completedLessons: fetchedLessons.length, 
          totalLessons: fetchedLessons.length,
          chapters: [
            ChapterModel(
              id: 'c1',
              title: 'Bài học từ Database',
              statusBadge: 'API 연동',
              isLocked: false,
              lessons: fetchedLessons,
            )
          ],
        );
      } else {
        throw Exception('Failed to load lessons: ${response.statusCode}');
      }
    } catch (e) {
      // Dữ liệu dự phòng nếu chưa có API chạy
      return _getDummyRoadmap();
    }
  }

  RoadmapModel _getDummyRoadmap() {
    return RoadmapModel(
      title: 'Lộ trình chi tiết (Máy ảo / Lỗi API)',
      totalProgress: 0.0,
      completedLessons: 0,
      totalLessons: 0,
      chapters: [
        ChapterModel(
          id: 'error',
          title: 'Không tải được bài học',
          isLocked: false,
          lessons: [],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: FutureBuilder<RoadmapModel>(
          future: futureRoadmap,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Không có dữ liệu'));
            }

            final roadmap = snapshot.data!;

            return Column(
              children: [
                RoadmapHeader(
                  title: roadmap.title,
                  progress: roadmap.totalProgress,
                  completed: roadmap.completedLessons,
                  total: roadmap.totalLessons,
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: roadmap.chapters.length,
                    itemBuilder: (context, index) {
                      return ChapterSection(chapter: roadmap.chapters[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
