// ── Dictionary Models — Từ điển Nhật - Việt ─────────────────────────────────

class DictionaryEntry {
  final String word;
  final String reading;
  final bool isCommon;
  final List<String> jlpt;
  final List<DictionarySense> senses;
  final List<Map<String, dynamic>> japanese;

  const DictionaryEntry({
    required this.word,
    required this.reading,
    required this.isCommon,
    required this.jlpt,
    required this.senses,
    required this.japanese,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      word: json['word'] as String? ?? '',
      reading: json['reading'] as String? ?? '',
      isCommon: json['is_common'] as bool? ?? false,
      jlpt: List<String>.from(json['jlpt'] ?? []),
      senses: (json['senses'] as List<dynamic>? ?? [])
          .map((s) => DictionarySense.fromJson(s as Map<String, dynamic>))
          .toList(),
      japanese: List<Map<String, dynamic>>.from(
        (json['japanese'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e)),
      ),
    );
  }

  /// Ưu tiên hiển thị kanji, nếu không có thì dùng reading
  String get displayWord => word.isNotEmpty ? word : reading;

  /// JLPT label: "jlpt-n3" → "N3"
  String get jlptLabel {
    if (jlpt.isEmpty) return '';
    return jlpt.first.replaceAll('jlpt-', '').toUpperCase();
  }
}

class DictionarySense {
  /// Từ loại tiếng Việt (Danh từ, Động từ nhóm 2, ...)
  final List<String> partsOfSpeechVi;

  /// Từ loại tiếng Anh (gốc từ Jisho)
  final List<String> partsOfSpeechEn;

  /// Nghĩa tiếng Việt (đã dịch qua Google Translate)
  final List<String> viDefinitions;

  /// Nghĩa tiếng Anh gốc
  final List<String> englishDefinitions;

  final List<String> tags;
  final List<String> info;
  final List<String> seeAlso;
  final List<String> restrictions;

  const DictionarySense({
    required this.partsOfSpeechVi,
    required this.partsOfSpeechEn,
    required this.viDefinitions,
    required this.englishDefinitions,
    required this.tags,
    required this.info,
    required this.seeAlso,
    required this.restrictions,
  });

  factory DictionarySense.fromJson(Map<String, dynamic> json) {
    return DictionarySense(
      partsOfSpeechVi:
          List<String>.from(json['parts_of_speech_vi'] ?? []),
      partsOfSpeechEn:
          List<String>.from(json['parts_of_speech_en'] ?? json['parts_of_speech'] ?? []),
      viDefinitions:
          List<String>.from(json['vi_definitions'] ?? []),
      englishDefinitions:
          List<String>.from(json['english_definitions'] ?? []),
      tags:         List<String>.from(json['tags']         ?? []),
      info:         List<String>.from(json['info']         ?? []),
      seeAlso:      List<String>.from(json['see_also']     ?? []),
      restrictions: List<String>.from(json['restrictions'] ?? []),
    );
  }

  /// Trả về nghĩa hiển thị: ưu tiên tiếng Việt, fallback tiếng Anh
  List<String> get displayDefinitions =>
      viDefinitions.isNotEmpty ? viDefinitions : englishDefinitions;

  /// Từ loại hiển thị: ưu tiên tiếng Việt
  List<String> get displayPos =>
      partsOfSpeechVi.isNotEmpty ? partsOfSpeechVi : partsOfSpeechEn;
}

class KanjiDetail {
  final String kanji;
  final int? grade;
  final int? strokeCount;
  final List<String> meaningsVi;
  final List<String> meaningsEn;
  final List<String> kunReadings;
  final List<String> onReadings;
  final String? jlpt;

  const KanjiDetail({
    required this.kanji,
    this.grade,
    this.strokeCount,
    required this.meaningsVi,
    required this.meaningsEn,
    required this.kunReadings,
    required this.onReadings,
    this.jlpt,
  });

  factory KanjiDetail.fromJson(Map<String, dynamic> json) {
    return KanjiDetail(
      kanji:       json['kanji']        as String? ?? '',
      grade:       json['grade']        as int?,
      strokeCount: json['stroke_count'] as int?,
      meaningsVi:  List<String>.from(json['meanings_vi'] ?? json['meanings'] ?? []),
      meaningsEn:  List<String>.from(json['meanings_en'] ?? json['meanings'] ?? []),
      kunReadings: List<String>.from(json['kun_readings'] ?? []),
      onReadings:  List<String>.from(json['on_readings']  ?? []),
      jlpt:        json['jlpt']?.toString(),
    );
  }

  List<String> get displayMeanings =>
      meaningsVi.isNotEmpty ? meaningsVi : meaningsEn;
}

class DictionarySearchResult {
  final String keyword;
  final int page;
  final int total;
  final List<DictionaryEntry> entries;

  const DictionarySearchResult({
    required this.keyword,
    required this.page,
    required this.total,
    required this.entries,
  });

  factory DictionarySearchResult.fromJson(Map<String, dynamic> json) {
    return DictionarySearchResult(
      keyword: json['keyword'] as String? ?? '',
      page:    json['page']    as int?    ?? 1,
      total:   json['total']   as int?    ?? 0,
      entries: (json['entries'] as List<dynamic>? ?? [])
          .map((e) => DictionaryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
