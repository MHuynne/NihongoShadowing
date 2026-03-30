class SrsProgressModel {
  final int completedWords;
  final int totalWords;

  SrsProgressModel({
    required this.completedWords,
    required this.totalWords,
  });

  double get progressPercentage => totalWords > 0 ? completedWords / totalWords : 0;
  String get progressString => "${(progressPercentage * 100).toInt()}%";
}
