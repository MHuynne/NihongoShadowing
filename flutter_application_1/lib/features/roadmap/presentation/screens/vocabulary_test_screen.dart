import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/flashcard_screen.dart';
import 'package:flutter_application_1/features/shadowing/presentation/screens/shadowing_screen.dart';

class VocabularyTestScreen extends StatefulWidget {
  final int topicId;
  final bool isReview;

  const VocabularyTestScreen({super.key, required this.topicId, required this.isReview});

  @override
  State<VocabularyTestScreen> createState() => _VocabularyTestScreenState();
}

class _VocabularyTestScreenState extends State<VocabularyTestScreen> {
  bool _isLoading = true;
  List<dynamic> _vocabularies = [];
  int _currentIndex = 0;
  int _score = 0;

  bool _isAnswered = false;
  String? _selectedAnswer;
  
  List<String> _currentOptions = [];

  // Từ vựng dự phòng để luôn đổ đủ 4 đáp án kể cả khi bài học có quá ít từ
  final List<String> _fallbackMeanings = [
    'Giám đốc', 'Sách vở', 'Thời tiết', 'Người yêu', 'Nhà hàng',
    'Chó mèo', 'Nhật Bản', 'Đi công tác', 'Ngủ nướng', 'Đại học',
    'Máy tính', 'Ô tô', 'Du lịch', 'Mệt mỏi', 'Vui vẻ'
  ];

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
            _vocabularies.shuffle(); // Đảo trộn list từ
            _isLoading = false;
          });
          if (_vocabularies.isNotEmpty) {
             _generateOptions();
          }
        }
      } catch (e) {
          setState(() => _isLoading = false);
      }
  }

  void _generateOptions() {
    if (_currentIndex >= _vocabularies.length) return;
    
    final correctMeaning = _vocabularies[_currentIndex]['meaning'];
    Set<String> optionsSet = {correctMeaning};
    
    // Gom các nghĩa khác từ chính list bài học này
    for (var v in _vocabularies) {
      optionsSet.add(v['meaning']);
    }
    
    // Nếu vẫn chưa đủ 4 lựa chọn, lấy từ list dự phòng
    _fallbackMeanings.shuffle();
    int fallbackIndex = 0;
    while (optionsSet.length < 4 && fallbackIndex < _fallbackMeanings.length) {
      optionsSet.add(_fallbackMeanings[fallbackIndex]);
      fallbackIndex++;
    }
    
    // Đảo danh sách cẩn thận và lưu Option
    _currentOptions = optionsSet.take(4).toList();
    _currentOptions.shuffle();
    _isAnswered = false;
    _selectedAnswer = null;
  }

  void _checkAnswer(String selected) {
    if (_isAnswered) return;
    setState(() {
      _selectedAnswer = selected;
      _isAnswered = true;
      if (selected == _vocabularies[_currentIndex]['meaning']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentIndex < _vocabularies.length - 1) {
        _currentIndex++;
        _generateOptions();
      } else {
        // Đã hoàn thành câu hỏi cuối cùng
        _currentIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.progressTeal)),
      );
    }

    if (_vocabularies.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: const Text('Test Từ vựng',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty_rounded, size: 64, color: AppColors.slate300),
              const SizedBox(height: 16),
              const Text('Chưa có từ vựng để Test!',
                  style: TextStyle(fontSize: 16, color: AppColors.slate500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: _buildNavigateNextButton(),
              ),
            ],
          ),
        ),
      );
    }

    // HIỂN THỊ KẾT QUẢ KHI LÀM XONG
    if (_currentIndex >= _vocabularies.length) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _score == _vocabularies.length ? Icons.emoji_events_rounded : Icons.verified_rounded, 
                    size: 100, 
                    color: _score == _vocabularies.length ? Colors.amber : const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 24),
                  const Text('Kết Quả Bài Test', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
                  const SizedBox(height: 16),
                  Text(
                    '$_score / ${_vocabularies.length}',
                    style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _score == _vocabularies.length ? 'Tuyệt vời, điểm Tối đa!' : 'Cố gắng cải thiện nhé học giả!',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                  ),
                  const SizedBox(height: 48),
                  _buildNavigateNextButton(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // HIỂN THỊ KHUNG QUIZ TRẮC NGHIỆM
    final currentVocab = _vocabularies[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
           widget.isReview ? 'Review: Câu ${_currentIndex + 1}/${_vocabularies.length}' : 'Test Từ Vựng (${_currentIndex + 1}/${_vocabularies.length})', 
           style: const TextStyle(fontSize: 16, color: AppColors.textDark, fontWeight: FontWeight.w800, letterSpacing: 0.5)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24, color: AppColors.slate500),
          tooltip: 'Thoát',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => FlashcardScreen(topicId: widget.topicId),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh tiến trình xịn xò
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentIndex) / _vocabularies.length,
                  backgroundColor: AppColors.slate200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.progressTeal),
                  minHeight: 10,
                ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Khung Hiển thị Câu hỏi mang tính Game
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Nghĩa của từ dưới đây là gì?', 
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate400, letterSpacing: 0.5)),
                          const SizedBox(height: 20),
                          Text(
                            currentVocab['word'] ?? '',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF0F4C75), height: 1.1),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          if (currentVocab['reading'] != null && currentVocab['reading'].toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(currentVocab['reading'], 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.slate500)),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Sinh ra các Đáp án
                    ..._currentOptions.map((option) {
                      Color bgColor = Colors.white;
                      Color textColor = AppColors.textDark;
                      Color borderColor = AppColors.slate200;
                      IconData? trailIcon;
                      
                      if (_isAnswered) {
                         if (option == currentVocab['meaning']) { // Luôn tô xanh đáp án đúng
                           bgColor = AppColors.successGreenLight;
                           textColor = AppColors.successGreen;
                           borderColor = AppColors.successGreen;
                           trailIcon = Icons.check_circle;
                         } else if (option == _selectedAnswer) { // Tô đỏ nếu đang chọn sai
                           bgColor = Colors.red.withValues(alpha: 0.1);
                           textColor = Colors.red;
                           borderColor = Colors.red;
                           trailIcon = Icons.cancel;
                         } else {
                           bgColor = AppColors.slate50;
                           textColor = AppColors.slate400;
                         }
                      }

                      return GestureDetector(
                        onTap: () => _checkAnswer(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor, width: _isAnswered && (option == currentVocab['meaning'] || option == _selectedAnswer) ? 2.5 : 2),
                            boxShadow: _isAnswered && (option == currentVocab['meaning'] || option == _selectedAnswer)
                                ? [BoxShadow(color: borderColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor),
                                ),
                              ),
                              if (trailIcon != null) Icon(trailIcon, color: textColor, size: 28),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Nút Chuyển câu + phản hồi (Chỉ hiện khi đã chọn đáp án)
            if (_isAnswered)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: _selectedAnswer == _vocabularies[_currentIndex]['meaning']
                      ? AppColors.successGreenLight
                      : Colors.red.shade50,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedAnswer == _vocabularies[_currentIndex]['meaning']
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: _selectedAnswer == _vocabularies[_currentIndex]['meaning']
                              ? AppColors.successGreen
                              : Colors.red,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedAnswer == _vocabularies[_currentIndex]['meaning']
                              ? 'Chính xác! 🎉'
                              : 'Đáp án đúng: ${_vocabularies[_currentIndex]['meaning']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _selectedAnswer == _vocabularies[_currentIndex]['meaning']
                                ? AppColors.successGreen
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedAnswer == _vocabularies[_currentIndex]['meaning']
                            ? AppColors.progressTeal
                            : Colors.red.shade400,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _nextQuestion,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentIndex < _vocabularies.length - 1
                                ? 'Câu tiếp theo'
                                : 'Xem kết quả',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _currentIndex < _vocabularies.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.flag_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Nút chuyển hướng
  Widget _buildNavigateNextButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.textDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        elevation: 8,
        shadowColor: AppColors.textDark.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        if (widget.isReview) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          int testErrors = _vocabularies.length - _score;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ShadowingScreen(
                topicId: widget.topicId,
                testErrors: testErrors,
              ),
            ),
          );
        }
      },
      child: Text(
        widget.isReview ? 'HOÀN THÀNH BÀI HỌC' : 'SANG Luyện Giọng 👋', 
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)
      ),
    );
  }
}
