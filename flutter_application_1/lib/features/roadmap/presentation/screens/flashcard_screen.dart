import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:flutter_application_1/core/utils/sample_audio_player.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/vocabulary_test_screen.dart';
import 'package:flutter_application_1/features/roadmap/services/progress_service.dart';
import 'package:flutter_application_1/core/config/api_config.dart';

const _kPrimary = Color(0xFFFF4D6D);
const _kPrimaryGradient = LinearGradient(
  colors: [Color(0xFFFF6B4A), Color(0xFFFF4D6D)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const _kPrimaryLight = Color(0xFFFFEBF0);
const _kBg = Color(0xFFF8F9FE);
const _kTextDark = Color(0xFF1E293B);
const _kTextGray = Color(0xFF94A3B8);

class FlashcardScreen extends StatefulWidget {
  final int topicId;
  final int lessonId; 
  const FlashcardScreen({
    super.key,
    required this.topicId,
    required this.lessonId,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<dynamic> _vocabularies = [];
  List<dynamic> _learningQueue = [];
  int _totalVocab = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVocab();
  }

  Future<void> _fetchVocab() async {
    String apiUrl = '${ApiConfig.baseUrl}/vocabularies/?lesson_id=${widget.lessonId}';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _vocabularies = data;
          _learningQueue = List.from(_vocabularies);
          _totalVocab = _vocabularies.length;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _vocabularies = _dummyVocab();
        _learningQueue = List.from(_vocabularies);
        _totalVocab = _vocabularies.length;
        _isLoading = false;
      });
    }
  }

  List<Map<String, String>> _dummyVocab() => [
    {
      'word': '学習',
      'reading': 'がくしゅう (Gakushū)',
      'meaning': 'Học tập',
      'level': 'N3',
    },
    {
      'word': '希望',
      'reading': 'きぼう (Kibō)',
      'meaning': 'Hy vọng, kỳ vọng',
      'level': 'N3',
    },
    {
      'word': '景色',
      'reading': 'けしき (Keshiki)',
      'meaning': 'Phong cảnh',
      'level': 'N3',
    },
  ];

  void _markNotMemorized() {
    if (_learningQueue.isEmpty) return;
    setState(() {
      // Đưa từ hiện tại xuống cuối danh sách để học lại
      final current = _learningQueue.removeAt(0);
      _learningQueue.add(current);
    });
  }

  void _markMemorized() {
    if (_learningQueue.isEmpty) return;
    setState(() {
      // Loại bỏ từ đã thuộc khỏi danh sách học
      _learningQueue.removeAt(0);
      
      // Nếu đã thuộc hết thì chuyển sang Test
      if (_learningQueue.isEmpty) {
        _startTest();
      }
    });
  }

  void _startTest() async {
    await ProgressService.markFlashcardDone(widget.lessonId);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VocabularyTestScreen(
          topicId: widget.topicId,
          lessonId: widget.lessonId,
          isReview: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _kBg,
        body: const Center(
          child: CircularProgressIndicator(color: _kPrimary),
        ),
      );
    }

    if (_totalVocab == 0 && !_isLoading) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: Center(
          child: Text(
            'Chưa có từ vựng cho bài học này',
            style: TextStyle(color: _kTextGray, fontSize: 16),
          ),
        ),
      );
    }

    if (_learningQueue.isEmpty) {
      return Scaffold(backgroundColor: _kBg, body: const Center(child: CircularProgressIndicator()));
    }
    final vocab = _learningQueue[0];

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _buildFlashcard(vocab),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTestButton(),
            ),
            const SizedBox(height: 24),
            _buildBottomControls(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: _kTextDark),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'Học từ vựng',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _kTextDark,
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final learned = _totalVocab - _learningQueue.length;
    final progress = _totalVocab == 0 ? 0.0 : learned / _totalVocab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TIẾN ĐỘ HÔM NAY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _kTextGray,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '$learned/$_totalVocab',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _kPrimary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(Map<String, dynamic> v) {
    final word = v['word']?.toString() ?? '';
    final reading = v['reading']?.toString() ?? '';
    final meaning = v['meaning']?.toString() ?? '';
    final level = v['level']?.toString() ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 64),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        word,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: _kTextDark,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (reading.isNotEmpty)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          reading,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7A6A6A),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Container(
                      width: 48,
                      height: 2,
                      color: _kPrimaryLight,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      meaning,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom Left: Level
          if (level.isNotEmpty)
            Positioned(
              left: 24,
              bottom: 24,
              child: Text(
                'JLPT $level',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _kTextGray,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          // Bottom Right: Audio Button
          Positioned(
            right: 16,
            bottom: 16,
            child: _AudioButton(word: word),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _kPrimaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _startTest,
        icon: const Icon(Icons.style_rounded, size: 20),
        label: const Text(
          'Bắt đầu Test Nhớ Từ Vựng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(
          icon: Icons.close_rounded,
          color: const Color(0xFF64748B),
          label: 'CHƯA THUỘC',
          onTap: _markNotMemorized,
        ),
        const SizedBox(width: 48),
        _buildCircleButton(
          icon: Icons.favorite_border_rounded,
          color: _kPrimary,
          label: 'ĐÃ THUỘC',
          onTap: _markMemorized,
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: color),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
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
      String apiUrl = '${ApiConfig.baseUrl}/tts/sample';

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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _isPlaying ? _kPrimaryLight : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
          size: 24,
          color: _kPrimary,
        ),
      ),
    );
  }
}
