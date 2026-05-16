class ShadowingSentenceModel {
  final String title;
  final String kanji;
  final String furiganaHtml;
  final String romaji;
  final String hanViet;
  final String meaning;
  final double startTime; // start_time của segment (giây)
  final double endTime;   // end_time của segment (giây)

  ShadowingSentenceModel({
    this.title = '',
    required this.kanji,
    required this.furiganaHtml,
    required this.romaji,
    required this.hanViet,
    required this.meaning,
    this.startTime = 0.0,
    this.endTime = 0.0,
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

// ─── Error Type ─────────────────────────────────────────────────────────────
class ErrorTypes {
  final List<String> pronunciation;
  final List<String> prosody;
  final List<String> pitchAccent;
  final List<String> rhythm;

  const ErrorTypes({
    this.pronunciation = const [],
    this.prosody = const [],
    this.pitchAccent = const [],
    this.rhythm = const [],
  });

  factory ErrorTypes.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ErrorTypes();
    return ErrorTypes(
      pronunciation: List<String>.from(json['pronunciation'] ?? []),
      prosody: List<String>.from(json['prosody'] ?? []),
      pitchAccent: List<String>.from(json['pitch_accent'] ?? []),
      rhythm: List<String>.from(json['rhythm'] ?? []),
    );
  }

  bool get hasAnyError =>
      pronunciation.isNotEmpty ||
      prosody.isNotEmpty ||
      pitchAccent.isNotEmpty ||
      rhythm.isNotEmpty;
}

// ─── Action Plan từ RecommendationEngine ─────────────────────────────────────
enum ActionType {
  showHanVietMode,
  openVocabulary,
  activateSlowMode,
  showPitchGuide,
  celebrate,
  retry,
}

class ActionPlan {
  final String message;
  final ActionType action;
  final String? targetWord;
  final int severity; // 0=OK, 1=nhẹ, 2=trung bình, 3=nghiêm trọng

  const ActionPlan({
    required this.message,
    required this.action,
    this.targetWord,
    this.severity = 1,
  });

  factory ActionPlan.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ActionPlan(
        message: 'Tiếp tục luyện tập nhé! 💪',
        action: ActionType.celebrate,
      );
    }
    final actionStr = json['action'] as String? ?? 'celebrate';
    final action = _parseAction(actionStr);
    return ActionPlan(
      message: json['message'] ?? '',
      action: action,
      targetWord: json['target_word'] as String?,
      severity: json['severity'] as int? ?? 1,
    );
  }

  static ActionType _parseAction(String raw) {
    switch (raw) {
      case 'show_han_viet_mode':  return ActionType.showHanVietMode;
      case 'open_vocabulary':     return ActionType.openVocabulary;
      case 'activate_slow_mode':  return ActionType.activateSlowMode;
      case 'show_pitch_guide':    return ActionType.showPitchGuide;
      case 'retry':               return ActionType.retry;
      default:                    return ActionType.celebrate;
    }
  }
}

// ─── Feedback Model tổng hợp ─────────────────────────────────────────────────
class ShadowingFeedbackModel {
  final int accuracy;
  final int fluency;
  final int prosody;
  final int rhythm;
  final String feedbackHtml;
  final String tip;
  final List<WordAnalysisModel> wordsAnalysis;
  final List<String> misprnouncedWords;
  final ErrorTypes errorTypes;
  final ActionPlan? actionPlan;

  ShadowingFeedbackModel({
    required this.accuracy,
    this.fluency = 0,
    this.prosody = 0,
    this.rhythm = 0,
    required this.feedbackHtml,
    required this.tip,
    this.wordsAnalysis = const [],
    this.misprnouncedWords = const [],
    this.errorTypes = const ErrorTypes(),
    this.actionPlan,
  });
}
