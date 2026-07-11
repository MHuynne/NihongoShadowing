import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:flutter_application_1/core/utils/sample_audio_player.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/vocabulary_test_screen.dart';
import 'package:flutter_application_1/features/roadmap/services/progress_service.dart';
import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
const _kGreen = Color(0xFF16A34A);

class FlashcardScreen extends StatefulWidget {
  final int topicId;
  final int lessonId;

  final bool isReviewMode;

  final List<dynamic> reviewWords;

  const FlashcardScreen({
    super.key,
    required this.topicId,
    required this.lessonId,
    this.isReviewMode = false,
    this.reviewWords = const [],
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _vocabularies = [];
  List<dynamic> _learningQueue = [];
  Set<int> _notMemorizedIndices = {};
  int _memorizedCount    = 0;
  int _notMemorizedCount = 0;
  int _totalVocab = 0;
  bool _isLoading = true;


  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFrontSide = true;



  bool _isInReviewPass = false;


  String get _prefKeyIndex => 'flashcard_idx_${widget.lessonId}';
  String get _prefKeyMemorized => 'flashcard_mem_${widget.lessonId}';
  String get _prefKeyNotMemorized => 'flashcard_notmem_${widget.lessonId}';
  String get _prefKeyIndices => 'flashcard_indices_${widget.lessonId}';
  String get _prefKeyInReview => 'flashcard_inreview_${widget.lessonId}';

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
    if (widget.isReviewMode && widget.reviewWords.isNotEmpty) {


      _vocabularies      = widget.reviewWords;
      _learningQueue     = List.from(_vocabularies);
      _totalVocab        = _vocabularies.length;
      _memorizedCount    = 0;
      _notMemorizedCount = _vocabularies.length;
      _isInReviewPass    = true;
      _isLoading         = false;
    } else {
      _fetchVocab();
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();

    if (!widget.isReviewMode && _vocabularies.isNotEmpty && _learningQueue.isNotEmpty) {
      _saveProgressLocally();
    }
    super.dispose();
  }

  Future<void> _saveProgressLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentIndex = _totalVocab - _learningQueue.length;
      await prefs.setInt(_prefKeyIndex, currentIndex);
      await prefs.setInt(_prefKeyMemorized, _memorizedCount);
      await prefs.setInt(_prefKeyNotMemorized, _notMemorizedCount);
      await prefs.setBool(_prefKeyInReview, _isInReviewPass);
      await prefs.setString(_prefKeyIndices, jsonEncode(_notMemorizedIndices.toList()));
      debugPrint('[Flashcard] Saved: card=$currentIndex/$_totalVocab');
    } catch (e) {
      debugPrint('[Flashcard] Save error: $e');
    }
  }

  Future<void> _clearLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyIndex);
      await prefs.remove(_prefKeyMemorized);
      await prefs.remove(_prefKeyNotMemorized);
      await prefs.remove(_prefKeyIndices);
      await prefs.remove(_prefKeyInReview);
    } catch (e) {
      debugPrint('[Flashcard] Clear error: $e');
    }
  }

  Future<void> _fetchVocab() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/vocabularies/?lesson_id=${widget.lessonId}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));


        final prefs = await SharedPreferences.getInstance();
        final savedIdx      = prefs.getInt(_prefKeyIndex) ?? 0;
        final savedMem      = prefs.getInt(_prefKeyMemorized) ?? 0;
        final savedNotMem   = prefs.getInt(_prefKeyNotMemorized) ?? 0;
        final savedInReview = prefs.getBool(_prefKeyInReview) ?? false;
        final indicesJson   = prefs.getString(_prefKeyIndices);
        Set<int> savedIndices = {};
        if (indicesJson != null) {
          savedIndices = (jsonDecode(indicesJson) as List<dynamic>).map((e) => e as int).toSet();
        }

        final hasResume = savedIdx > 0 && savedIdx < data.length;

        if (mounted) {
          setState(() {
            _vocabularies = data;
            _totalVocab   = data.length;
            if (hasResume) {

              _learningQueue       = List.from(data.sublist(savedIdx));
              _memorizedCount      = savedMem;
              _notMemorizedCount   = savedNotMem;
              _notMemorizedIndices = savedIndices;
              _isInReviewPass      = savedInReview;
            } else {
              _learningQueue     = List.from(data);
              _memorizedCount    = 0;
              _notMemorizedCount = 0;
            }
            _isLoading = false;
          });
        }

        if (hasResume && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.bookmark_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Tiep tuc tu tu $savedIdx/$_totalVocab',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              backgroundColor: _kPrimary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ));
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _vocabularies      = _dummyVocab();
        _learningQueue     = List.from(_vocabularies);
        _totalVocab        = _vocabularies.length;
        _memorizedCount    = 0;
        _notMemorizedCount = 0;
        _isLoading         = false;
      });
    }
  }

  List<Map<String, String>> _dummyVocab() => [
    {'word': '学習', 'reading': 'がくしゅう (Gakushū)', 'meaning': 'Học tập', 'level': 'N3'},
    {'word': '希望', 'reading': 'きぼう (Kibō)', 'meaning': 'Hy vọng, kỳ vọng', 'level': 'N3'},
    {'word': '景色', 'reading': 'けしき (Keshiki)', 'meaning': 'Phong cảnh', 'level': 'N3'},
  ];


  void _flipCard() {
    if (_flipCtrl.isAnimating) return;
    if (_isFrontSide) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
    setState(() => _isFrontSide = !_isFrontSide);
  }

  void _resetFlip() {
    _flipCtrl.reset();
    setState(() => _isFrontSide = true);
  }


  void _markNotMemorized() {
    if (_learningQueue.isEmpty) return;
    final current = _learningQueue[0];

    if (_isInReviewPass) {

      setState(() {
        _learningQueue.removeAt(0);
        _learningQueue.add(current);
      });
    } else {

      final idx = _vocabularies.indexOf(current);
      if (idx != -1) _notMemorizedIndices.add(idx);
      setState(() {
        _learningQueue.removeAt(0);
        _notMemorizedCount++;
      });
      if (_learningQueue.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleRoundComplete();
        });
      }
    }
    _resetFlip();
  }


  void _markMemorized() {
    if (_learningQueue.isEmpty) return;
    final current = _learningQueue[0];
    final idx = _vocabularies.indexOf(current);
    _notMemorizedIndices.remove(idx);

    setState(() {
      _learningQueue.removeAt(0);
      _memorizedCount++;

      if (_isInReviewPass && _notMemorizedCount > 0) _notMemorizedCount--;
    });

    if (_learningQueue.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleRoundComplete();
      });
    }
    _resetFlip();
  }


  void _handleRoundComplete() {
    if (!_isInReviewPass && _notMemorizedIndices.isNotEmpty) {

      _showReviewDialog();
    } else if (_isInReviewPass) {

      _showReviewCompleteDialog();
    } else {

      _startTest();
    }
  }

  void _showReviewCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: _kGreen, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn đã thuộc hết rồi! 🎉',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kTextDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Đã ghi nhớ $_memorizedCount / $_totalVocab từ trong vòng ôn này.',
                style: const TextStyle(fontSize: 13, color: _kTextGray, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Bạn muốn tiếp theo thế nào?',
                style: TextStyle(fontSize: 14, color: _kTextGray, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(context); _restartReviewRound(); },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Học lại từ đầu',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(context); _startTest(); },
                  icon: const Icon(Icons.style_rounded, size: 18),
                  label: const Text('Làm bài Test thôi! 💪',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restartReviewRound() {
    final reviewList = List.from(_vocabularies);
    setState(() {
      _learningQueue     = reviewList;
      _totalVocab        = reviewList.length;
      _memorizedCount    = 0;
      _notMemorizedCount = reviewList.length;

    });
    _resetFlip();
  }

  void _showReviewDialog() {
    final notCount = _notMemorizedIndices.length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.menu_book_rounded, color: _kPrimary, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Kết quả học từ vựng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kTextDark)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _dialogStat('Đã thuộc', _memorizedCount, _kGreen)),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogStat('Chưa thuộc', notCount, _kPrimary)),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Bạn muốn tiếp theo thế nào?',
                style: TextStyle(fontSize: 14, color: _kTextGray, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(context); _startReviewRound(); },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text('Ôn lại $notCount từ chưa thuộc',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(context); _restartAllWords(); },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Học lại từ đầu toàn bộ',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () { Navigator.pop(context); _startTest(); },
                child: const Text('Bỏ qua, sang Test luôn',
                  style: TextStyle(color: _kTextGray, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  void _startReviewRound() {
    final reviewList = _notMemorizedIndices.map((i) => _vocabularies[i]).toList();
    _notMemorizedIndices.clear();
    setState(() {
      _learningQueue     = reviewList;
      _totalVocab        = reviewList.length;
      _memorizedCount    = 0;
      _notMemorizedCount = reviewList.length;
      _isInReviewPass    = true;
    });
    _resetFlip();
  }

  void _restartAllWords() {
    _notMemorizedIndices.clear();
    final allWords = widget.isReviewMode ? widget.reviewWords : _vocabularies;
    setState(() {
      _vocabularies      = allWords;
      _learningQueue     = List.from(allWords);
      _totalVocab        = allWords.length;
      _memorizedCount    = 0;
      _notMemorizedCount = 0;
      _isInReviewPass    = false;
    });
    _resetFlip();
  }

  void _startTest() async {
    await _clearLocalProgress();
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
        body: const Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    if (_totalVocab == 0) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: Center(child: Text('Chưa có từ vựng cho bài học này', style: TextStyle(color: _kTextGray, fontSize: 16))),
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

            if (_isInReviewPass || widget.isReviewMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔄 Vòng ôn lại từ chưa thuộc',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _buildFlippableCard(vocab),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTestButton(),
            ),
            const SizedBox(height: 16),
            _buildBottomControls(),
            const SizedBox(height: 28),
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
      title: Text(
        widget.isReviewMode ? 'Ôn lại từ chưa thuộc' : 'Học từ vựng',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextDark),
      ),
    );
  }

  Widget _buildProgress() {
    final total = _totalVocab == 0 ? 1 : _totalVocab;
    final memorizedRatio    = _memorizedCount / total;
    final notMemorizedRatio = _notMemorizedCount / total;
    final remaining = _totalVocab - _memorizedCount - _notMemorizedCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TIẾN ĐỘ HÔM NAY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _kTextGray, letterSpacing: 1.2)),
              Text('$_totalVocab từ',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _kTextGray)),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const SizedBox(
                width: 72,
                child: Text('Đã thuộc',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: memorizedRatio,
                    backgroundColor: _kGreen.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(_kGreen),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text('$_memorizedCount',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _kGreen)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const SizedBox(
                width: 72,
                child: Text('Chưa thuộc',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: notMemorizedRatio,
                    backgroundColor: _kPrimary.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text('$_notMemorizedCount',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _kPrimary)),
              ),
            ],
          ),
          if (remaining > 0) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Còn $remaining từ chưa xem',
                style: const TextStyle(fontSize: 10, color: _kTextGray, fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildFlippableCard(Map<String, dynamic> v) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (_, __) {
          final angle = _flipAnim.value * math.pi;
          final isFront = angle < math.pi / 2;

          Widget cardFace;
          if (isFront) {
            cardFace = _buildCardFront(v);
          } else {

            cardFace = Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: _buildCardBack(v),
            );
          }

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: cardFace,
          );
        },
      ),
    );
  }

  Widget _buildCardFront(Map<String, dynamic> v) {
    final word    = v['word']?.toString()    ?? '';
    final reading = v['reading']?.toString() ?? '';
    final level   = v['level']?.toString()   ?? '';

    return _CardShell(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(word, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: _kTextDark, height: 1.1)),
                  ),
                  const SizedBox(height: 12),
                  if (reading.isNotEmpty)
                    Text(reading, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF7A6A6A))),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app_rounded, size: 16, color: _kTextGray),
                      const SizedBox(width: 4),
                      const Text('Chạm để xem nghĩa', style: TextStyle(fontSize: 12, color: _kTextGray, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (level.isNotEmpty)
            Positioned(left: 24, bottom: 24,
              child: Text('JLPT $level', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _kTextGray, letterSpacing: 1.5))),
          Positioned(right: 16, bottom: 16, child: _AudioButton(word: word)),
        ],
      ),
    );
  }

  Widget _buildCardBack(Map<String, dynamic> v) {
    final word    = v['word']?.toString()    ?? '';
    final meaning = v['meaning']?.toString() ?? '';
    final level   = v['level']?.toString()   ?? '';

    return _CardShell(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0F3), Color(0xFFFFE4EA)],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  Text(word, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _kTextGray)),
                  const SizedBox(height: 16),
                  Container(width: 48, height: 2, color: _kPrimary.withValues(alpha: 0.3)),
                  const SizedBox(height: 20),
                  Text(
                    meaning,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _kPrimary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app_rounded, size: 16, color: _kTextGray),
                      const SizedBox(width: 4),
                      const Text('Chạm để lật lại', style: TextStyle(fontSize: 12, color: _kTextGray, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (level.isNotEmpty)
            Positioned(left: 24, bottom: 24,
              child: Text('JLPT $level', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _kTextGray, letterSpacing: 1.5))),
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
        boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton.icon(
        onPressed: _startTest,
        icon: const Icon(Icons.style_rounded, size: 20),
        label: const Text('Bắt đầu Test Nhớ Từ Vựng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(icon: Icons.close_rounded, color: const Color(0xFF64748B), label: 'CHƯA THUỘC', onTap: _markNotMemorized),
        const SizedBox(width: 48),
        _buildCircleButton(icon: Icons.favorite_rounded, color: _kPrimary, label: 'ĐÃ THUỘC', onTap: _markMemorized),
      ],
    );
  }

  Widget _buildCircleButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Icon(icon, size: 28, color: color),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
      ],
    );
  }
}


class _CardShell extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  const _CardShell({required this.child, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: gradient == null ? Colors.white : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: _kPrimary.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: child,
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tts/sample'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': widget.word, 'speed': 0.9, 'voice_gender': 'female'}),
      );
      if (response.statusCode == 200) {
        await _player.play(response.bodyBytes, onComplete: () {
          if (mounted) setState(() => _isPlaying = false);
        });
      } else {
        throw Exception('TTS ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[FlashcardTTS] $e');
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
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: _isPlaying ? _kPrimaryLight : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Icon(_isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined, size: 24, color: _kPrimary),
      ),
    );
  }
}