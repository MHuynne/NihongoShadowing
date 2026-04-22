class ShadowingSentenceModel {
  final String kanji;
  final String furiganaHtml; // Using a simple format or just assume UI handles it
  final String romaji;
  final String hanViet;
  final String meaning;
  
  ShadowingSentenceModel({
    required this.kanji,
    required this.furiganaHtml,
    required this.romaji,
    required this.hanViet,
    required this.meaning,
  });
}

class WordAnalysisModel {
  final String text;
  final bool isCorrect;

  WordAnalysisModel({required this.text, required this.isCorrect});

  factory WordAnalysisModel.fromJson(Map<String, dynamic> json) {
    return WordAnalysisModel(
      text: json['text'] ?? '',
      isCorrect: json['is_correct'] ?? false,
    );
  }
}

class ShadowingFeedbackModel {
  final int accuracy;
  final int fluency;
  final int prosody;
  final int rhythm;       // điểm nhịp ngắt (Shadowing mode)
  final String feedbackHtml;
  final String tip;
  final List<WordAnalysisModel> wordsAnalysis;

  ShadowingFeedbackModel({
    required this.accuracy,
    this.fluency = 0,
    this.prosody = 0,
    this.rhythm = 0,
    required this.feedbackHtml,
    required this.tip,
    this.wordsAnalysis = const [],
  });
}
