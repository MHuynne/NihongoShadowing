import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/core/utils/sample_audio_player.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/vocabulary_test_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final int topicId;
  const FlashcardScreen({super.key, required this.topicId});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<dynamic> _vocabularies = [];
  bool _isLoading = true;
  // Set of expanded card indices
  final Set<int> _expandedCards = {0}; // First card expanded by default

  @override
  void initState() {
    super.initState();
    _fetchVocab();
  }

  Future<void> _fetchVocab() async {
    String apiUrl = 'http://localhost:8000/shadowing/topics/${widget.topicId}';
    try {
      if (!kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          apiUrl = 'http://10.0.2.2:8000/shadowing/topics/${widget.topicId}';
        }
      }
    } catch (_) {}

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _vocabularies = data['vocabularies'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _vocabularies = _dummyVocab();
        _isLoading = false;
      });
    }
  }

  List<Map<String, String>> _dummyVocab() => [
    {
      'word': '希望',
      'reading': 'きぼう',
      'meaning': 'Hy vọng, kỳ vọng',
      'example_jp': '新しい仕事に希望を持っています。',
      'example_vn': 'Tôi có nhiều kỳ vọng vào công việc mới.',
      'level': 'N3',
    },
    {
      'word': '景色',
      'reading': 'けしき',
      'meaning': 'Phong cảnh, cảnh vật',
      'example_jp': '',
      'example_vn': '',
      'level': 'N3',
    },
    {
      'word': '準備',
      'reading': 'じゅんび',
      'meaning': 'Chuẩn bị',
      'example_jp': '',
      'example_vn': '',
      'level': 'N3',
    },
    {
      'word': '感動',
      'reading': 'かんどう',
      'meaning': 'Cảm động, xúc động',
      'example_jp': '',
      'example_vn': '',
      'level': 'N3',
    },
  ];

  void _toggleCard(int index) {
    setState(() {
      if (_expandedCards.contains(index)) {
        _expandedCards.remove(index);
      } else {
        _expandedCards.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.progressTeal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildHeading(),
            Expanded(
              child: _vocabularies.isEmpty
                  ? _buildEmptyState()
                  : _buildCardList(),
            ),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Kingo JP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          _QuickScanButton(),
        ],
      ),
    );
  }

  Widget _buildHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vocabulary Discovery',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Khám phá từ vựng mới qua bộ lọc thông minh mỗi ngày.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: _vocabularies.length,
      itemBuilder: (context, index) {
        final v = _vocabularies[index];
        final isExpanded = _expandedCards.contains(index);
        return _VocabCard(
          word: v['word'] ?? '',
          reading: v['reading'] ?? '',
          meaning: v['meaning'] ?? '',
          exampleJp: v['example_jp'] ?? '',
          exampleVn: v['example_vn'] ?? '',
          level: v['level'] ?? '',
          isExpanded: isExpanded,
          onTap: () => _toggleCard(index),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chưa có từ vựng cho bài học này',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bỏ qua
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text(
                'Bỏ qua',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Học ngay
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VocabularyTestScreen(
                      topicId: widget.topicId,
                      isReview: false,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text(
                'Học ngay',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.progressTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickScanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: AppColors.progressTeal,
          ),
          SizedBox(width: 5),
          Text(
            'QUICK SCAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.progressTeal,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VocabCard extends StatefulWidget {
  final String word;
  final String reading;
  final String meaning;
  final String exampleJp;
  final String exampleVn;
  final String level;
  final bool isExpanded;
  final VoidCallback onTap;

  const _VocabCard({
    required this.word,
    required this.reading,
    required this.meaning,
    required this.exampleJp,
    required this.exampleVn,
    required this.level,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_VocabCard> createState() => _VocabCardState();
}

class _VocabCardState extends State<_VocabCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(covariant _VocabCard old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded != old.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP ROW: level badge + audio icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.level.isNotEmpty) _LevelBadge(level: widget.level),
                _AudioButton(word: widget.word),
              ],
            ),
            const SizedBox(height: 10),

            // ── READING (furigana)
            if (widget.isExpanded && widget.reading.isNotEmpty)
              Text(
                widget.reading,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  letterSpacing: 1,
                ),
              ),

            // ── KANJI WORD
            Text(
              widget.word,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                height: 1.1,
              ),
            ),

            // ── EXPANDED CONTENT
            if (widget.isExpanded) ...[
              const SizedBox(height: 20),
              // Meaning section
              _SectionLabel(label: 'Ý NGHĨA'),
              const SizedBox(height: 4),
              Text(
                widget.meaning,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),

              // Example section
              if (widget.exampleJp.isNotEmpty ||
                  widget.exampleVn.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SectionLabel(label: 'VÍ DỤ'),
                const SizedBox(height: 4),
                if (widget.exampleJp.isNotEmpty)
                  _HighlightedText(
                    text: widget.exampleJp,
                    highlight: widget.word,
                  ),
                if (widget.exampleVn.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.exampleVn,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ] else ...[
              // ── COLLAPSED HINT
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _fadeAnim.drive(Tween<double>(begin: 1.0, end: 0.0)),
                child: Row(
                  children: const [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: AppColors.progressTeal,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'NHẤN ĐỂ XEM NGHĨA',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.progressTeal,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// SMALL HELPERS
// ──────────────────────────────────────────────────────
class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$level LEVEL',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.progressTeal,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _AudioButton extends StatefulWidget {
  final String word;
  const _AudioButton({required this.word});

  @override
  State<_AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<_AudioButton> {
  final SampleAudioPlayer _player = createSampleAudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _speak() async {
    if (widget.word.isEmpty) return;

    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);

    try {
      String apiUrl = 'http://localhost:8000/tts/sample';
      if (!kIsWeb) {
        try {
          if (defaultTargetPlatform == TargetPlatform.android) {
            apiUrl = 'http://10.0.2.2:8000/tts/sample';
          }
        } catch (_) {}
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': widget.word,
          'speed': 0.9,
          'voice_gender': 'female',
        }),
      );

      if (response.statusCode == 200) {
        await _player.play(
          response.bodyBytes,
          onComplete: () {
            if (mounted) setState(() => _isPlaying = false);
          },
        );
      } else {
        throw Exception('TTS API ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[FlashcardTTS] Error: $e');
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _speak,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _isPlaying
              ? AppColors.progressTeal.withValues(alpha: 0.15)
              : const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
          size: 19,
          color: _isPlaying ? AppColors.progressTeal : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Renders text with the [highlight] word in bold teal color.
class _HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;

  const _HighlightedText({required this.text, required this.highlight});

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty || !text.contains(highlight)) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF475569),
          height: 1.5,
        ),
      );
    }

    final parts = text.split(highlight);
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          TextSpan(
            text: highlight,
            style: const TextStyle(
              color: AppColors.progressTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF475569),
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}
