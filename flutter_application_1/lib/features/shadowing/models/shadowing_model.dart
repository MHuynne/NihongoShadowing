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

class ShadowingFeedbackModel {
  final int accuracy;
  final String feedbackHtml; // e.g. "Kyou wa <span style='color:red'>tenki</span> ga ii desu ne"
  final String tip;

  ShadowingFeedbackModel({
    required this.accuracy,
    required this.feedbackHtml,
    required this.tip,
  });
}
