import 'package:flutter/material.dart';

class LessonModel {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final LessonStatus status;
  final double? progress; // e.g. 0.4 for 40%

  LessonModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    this.progress,
  });
}

enum LessonStatus {
  completed,
  inProgress,
  locked,
}

class ChapterModel {
  final String id;
  final String title;
  final String? statusBadge; // e.g. "80% Hoàn thành" or "Khóa"
  final bool isLocked;
  final List<LessonModel> lessons;

  ChapterModel({
    required this.id,
    required this.title,
    this.statusBadge,
    required this.isLocked,
    required this.lessons,
  });
}

class RoadmapModel {
  final String title;
  final double totalProgress;
  final int completedLessons;
  final int totalLessons;
  final List<ChapterModel> chapters;

  RoadmapModel({
    required this.title,
    required this.totalProgress,
    required this.completedLessons,
    required this.totalLessons,
    required this.chapters,
  });
}
