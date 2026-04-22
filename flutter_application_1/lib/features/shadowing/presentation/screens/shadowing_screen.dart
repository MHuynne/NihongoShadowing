import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/utils/sample_audio_player.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/shadowing/models/shadowing_model.dart';
import 'package:flutter_application_1/features/shadowing/presentation/components/shadowing_card.dart';
import 'package:flutter_application_1/features/shadowing/presentation/components/shadowing_controls.dart';
import 'package:flutter_application_1/features/shadowing/presentation/components/shadowing_header.dart';
import 'package:flutter_application_1/features/shadowing/presentation/components/waveform_visualizer.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/vocabulary_test_screen.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/lesson_summary_screen.dart';

class ShadowingScreen extends StatefulWidget {
  final int topicId;
  final int testErrors;
  const ShadowingScreen({super.key, required this.topicId, this.testErrors = 0});

  @override
  State<ShadowingScreen> createState() => _ShadowingScreenState();
}

class _ShadowingScreenState extends State<ShadowingScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  List<ShadowingSentenceModel> _sentences = [];
  int _currentIndex = 0;
  
  bool _isBlindMode = false;
  bool _isRecording = false;
  bool _isEvaluating = false;
  bool _showFeedback = false;
  bool _isPlayingSample = false;   // đang phát audio mẫu
  double _currentSpeed = 1.0;
  final Set<int> _failedSentences = {};

  final _audioRecorder = AudioRecorder();
  final _audioPlayer  = createSampleAudioPlayer();  // Web: dart:html | Native: audioplayers
  String? _recordedFilePath;

  ShadowingFeedbackModel? _dynamicFeedback;
  String _errorWord = "";

  @override
  void initState() {
    super.initState();
    _fetchTopicData();
  }

  Future<void> _fetchTopicData() async {
    try {
      String apiUrl = 'http://localhost:8000/shadowing/topics/${widget.topicId}';
      try {
        if (!kIsWeb) {
          if (defaultTargetPlatform == TargetPlatform.android) {
             apiUrl = 'http://10.0.2.2:8000/shadowing/topics/${widget.topicId}';
          }
        }
      } catch (_) {}

      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> segmentsData = data['segments'] ?? [];
        
        segmentsData.sort((a, b) => (a['order_index'] ?? 0).compareTo(b['order_index'] ?? 0));
        
        List<ShadowingSentenceModel> parsedSentences = segmentsData.map((seg) {
          return ShadowingSentenceModel(
            kanji: seg['kanji_content'] ?? '',
            furiganaHtml: seg['furigana'] ?? '',
            romaji: seg['romaji'] ?? '',
            hanViet: seg['sino_vietnamese'] ?? '',
            meaning: seg['translation_vi'] ?? '',
          );
        }).toList();

        if (parsedSentences.isEmpty) {
          parsedSentences.add(ShadowingSentenceModel(
             kanji: 'ごめんなさい！',
             furiganaHtml: '',
             romaji: 'Gomen nasai',
             hanViet: '',
             meaning: 'Bài học này chưa được nhập liệu câu nào trên admin nhé!',
          ));
        }

        setState(() {
          _sentences = parsedSentences;
          _isLoading = false;
        });

      } else {
        setState(() {
          _errorMessage = "Lỗi tải dữ liệu. HTTP ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Không thể kết nối API: $e";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Play Sample (theo tốc độ hiện tại) ─────────────────────────────────────
  Future<void> _playSample() async {
    final speed = _currentSpeed;
    if (_isPlayingSample) {
      // Đang phát → bấm lại thì dừng
      await _audioPlayer.stop();
      setState(() => _isPlayingSample = false);
      return;
    }

    final sentence = _sentences[_currentIndex];
    final text = sentence.kanji.isNotEmpty ? sentence.kanji : sentence.romaji;
    if (text.isEmpty) return;

    setState(() => _isPlayingSample = true);

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
        body: jsonEncode({'text': text, 'speed': speed, 'voice_gender': 'female'}),
      );

      if (response.statusCode == 200) {
        final mp3Bytes = response.bodyBytes;

        // SampleAudioPlayer tự chọn đúng implementation theo platform
        await _audioPlayer.play(
          mp3Bytes,
          onComplete: () {
            if (mounted) setState(() => _isPlayingSample = false);
          },
        );
      } else {
        throw Exception('TTS API ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[PlaySample] Error: $e');
      if (mounted) {
        setState(() => _isPlayingSample = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể phát audio mẫu: $e'),
            backgroundColor: AppColors.sunRed,
          ),
        );
      }
    }
  }

  // ── Đổi tốc độ phát ─────────────────────────────────────────────────
  void _toggleSpeed() {
    setState(() {
      if (_currentSpeed == 1.0) {
        _currentSpeed = 0.75;
      } else if (_currentSpeed == 0.75) {
        _currentSpeed = 0.5;
      } else {
        _currentSpeed = 1.0;
      }
    });
  }

  Future<void> _toggleRecording() async {
    setState(() {
      if (_showFeedback) _showFeedback = false;
    });

    try {
      if (!_isRecording) {
        if (await _audioRecorder.hasPermission()) {
          String? path;
          if (!kIsWeb) {
             final tempDir = await getTemporaryDirectory();
             path = '${tempDir.path}/shadowing_record.ogg';
          }

          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.opus, sampleRate: 16000, numChannels: 1), 
            path: path ?? ''
          );
          setState(() => _isRecording = true);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng cấp quyền Microphone để ghi âm!')));
          }
        }
      } else {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);

        // Trên Web: stop() trả về blob URL dạng "blob:http://..."
        // Trên Mobile/Desktop: stop() trả về đường dẫn file thực
        if (path != null && path.isNotEmpty) {
           _recordedFilePath = path;
           _uploadToAIAndGetResult();
        } else {
           debugPrint("Không lấy được đường dẫn file ghi âm.");
        }
      }
    } catch (e) {
      debugPrint("Lỗi ghi âm: $e");
      setState(() => _isRecording = false);
    }
  }

  Future<void> _uploadToAIAndGetResult() async {
     setState(() => _isEvaluating = true);
     final sentence = _sentences[_currentIndex];
     String apiUrl = 'http://localhost:8000/evaluate/shadowing';
      if (!kIsWeb) {
        try {
          if (defaultTargetPlatform == TargetPlatform.android) {
             apiUrl = 'http://10.0.2.2:8000/evaluate/shadowing';
          }
        } catch (_) {}
      }
      
      try {
        var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
        request.fields['expected_text'] = sentence.kanji.isNotEmpty ? sentence.kanji : sentence.romaji;
        if (sentence.romaji.isNotEmpty) {
           request.fields['romaji'] = sentence.romaji;
        }
        
        if (_recordedFilePath != null) {
           if (kIsWeb) {
              try {
                final blobResponse = await http.get(Uri.parse(_recordedFilePath!));
                request.files.add(http.MultipartFile.fromBytes('audio', blobResponse.bodyBytes, filename: 'record.ogg'));
              } catch (e) {
                debugPrint("Web blob load error: $e");
              }
           } else {
              if (File(_recordedFilePath!).existsSync()) {
                 request.files.add(await http.MultipartFile.fromPath('audio', _recordedFilePath!));
              }
           }
        }
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
           final data = json.decode(utf8.decode(response.bodyBytes));
           setState(() {
              _dynamicFeedback = ShadowingFeedbackModel(
                accuracy: data['accuracy'] ?? 0,
                fluency: data['fluency'] ?? 0,
                prosody: data['prosody'] ?? 0,
                rhythm: data['rhythm'] ?? 0,         // điểm nhịp ngắt mới
                feedbackHtml: data['recognized_text'] ?? '',
                tip: data['tip'] ?? '',
                wordsAnalysis: (data['words_analysis'] as List<dynamic>?)
                        ?.map((e) => WordAnalysisModel.fromJson(e as Map<String, dynamic>))
                        .toList() ??
                    [],
              );
              _errorWord = data['error_word'] ?? '';
              
              // Tracking lỗi dựa trên Accuracy hoặc mảng phân tích từ mới của AI
              bool hasWordError = _dynamicFeedback!.wordsAnalysis.any((w) => !w.isCorrect);
              if ((data['accuracy'] ?? 0) < 90 || hasWordError || _errorWord.isNotEmpty) {
                _failedSentences.add(_currentIndex);
              }

              _isEvaluating = false;
              _showFeedback = true;
           });
        }
      } catch (e) {
         setState(() {
            _isEvaluating = false;
            _dynamicFeedback = ShadowingFeedbackModel(accuracy: 0, feedbackHtml: "", tip: "Lỗi kết nối AI: $e");
            _showFeedback = true;
         });
      }
  }

  void _toggleMode(bool isBlind) {
    setState(() {
      _isBlindMode = isBlind;
      _showFeedback = false; 
    });
  }
  
  void _nextSentence() {
    setState(() {
      if (_currentIndex < _sentences.length - 1) {
        _currentIndex++;
        _isBlindMode = false;
        _showFeedback = false;
      } else {
        // Luồng mới: Học xong Shadowing thì tới bài Tổng kết
        Navigator.pushReplacement(
           context,
           MaterialPageRoute(
             builder: (context) => LessonSummaryScreen(
               testErrors: widget.testErrors,
               shadowingErrors: _failedSentences.length,
             ),
           ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
       return Scaffold(
         backgroundColor: Colors.white,
         body: Center(child: CircularProgressIndicator(color: AppColors.toriiRed)),
       );
    }

    if (_errorMessage != null) {
       return Scaffold(
         body: Center(
           child: Padding(
             padding: const EdgeInsets.all(20.0),
             child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
           ),
         ),
       );
    }

    final currentSentence = _sentences[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Soft Sakura gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color(0xFFF5E8E9),
                    Color(0xFFEEDFE1),
                    Colors.white,
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                ShadowingHeader(
              currentIndex: _currentIndex + 1,
              totalCount: _sentences.length,
              isBlindMode: _isBlindMode,
              onModeChanged: _toggleMode,
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    
                    if (!_isBlindMode && !_showFeedback) 
                      const WaveformVisualizer(
                        isUser: false, 
                        isRecording: true, 
                      ),
                    
                    if (!_isBlindMode) const SizedBox(height: 32),
                    
                    ShadowingCard(
                      sentence: currentSentence, 
                      isBlindMode: _isBlindMode,
                    ),

                    const SizedBox(height: 32),

                    if (_isEvaluating) ...[
                      const Center(child: CircularProgressIndicator(color: AppColors.sunRed)),
                      const SizedBox(height: 12),
                      const Text('AI đang chấm điểm phát âm...', style: TextStyle(color: AppColors.slate500)),
                      const SizedBox(height: 32),
                    ] else if (_showFeedback) ...[
                      _buildFeedbackCard(currentSentence),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if ((_dynamicFeedback?.accuracy ?? 0) < 50) {
                                // Ép đọc lại
                                _showFeedback = false;
                              } else if (!_isBlindMode) {
                                _isBlindMode = true;
                                _showFeedback = false;
                              } else {
                                _nextSentence();
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ((_dynamicFeedback?.accuracy ?? 0) < 50) ? Colors.orange : AppColors.sunRed,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            elevation: 4,
                            shadowColor: (((_dynamicFeedback?.accuracy ?? 0) < 50) ? Colors.orange : AppColors.sunRed).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            ((_dynamicFeedback?.accuracy ?? 0) < 50) ? 'Chưa Pass: Cần đọc lại thử thách' :
                            (!_isBlindMode ? 'Bước tiếp theo: Đọc ẩn chữ' : 
                               (_currentIndex < _sentences.length - 1 ? 'Câu tiếp theo' : 'Hoàn thành bài học')),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ] else if (_isBlindMode || _isRecording) ...[
                      const Text('USER VOICE',style: TextStyle(color: AppColors.sunRed, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_isRecording ? 'Đang ghi âm...' : 'Sẵn sàng đọc...', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            if (_isRecording)
                              Row(children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.sunRed, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                const Text('LIVE', style: TextStyle(color: AppColors.sunRed, fontWeight: FontWeight.bold, fontSize: 10)),
                              ])
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      WaveformVisualizer(isUser: true, isRecording: _isRecording),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('0.0S', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.bold, fontSize: 10)),
                            Text('1.5S', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.bold, fontSize: 10)),
                            Text('3.0S', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            
            ShadowingControls(
              isRecording: _isRecording,
              isPlayingSample: _isPlayingSample,
              onRecordPressed: _toggleRecording,
              onPlaySample: _playSample,
              onSpeedToggle: _toggleSpeed,
              currentSpeed: _currentSpeed,
            ),
            const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(ShadowingSentenceModel sent) {
    if (_dynamicFeedback == null) return const SizedBox.shrink();
    final feedback = _dynamicFeedback!;
    final bool isFailed = feedback.accuracy < 50;
    final bool allCorrect = feedback.accuracy >= 80 && _errorWord.isEmpty && !isFailed;

    Color boxColor = allCorrect ? AppColors.successGreenLight : (isFailed ? Colors.orange.shade50 : Colors.red.shade50);
    Color statusColor = allCorrect ? AppColors.successGreen : (isFailed ? Colors.orange : AppColors.sunRed);
    IconData statusIcon = allCorrect ? Icons.check_circle_rounded : (isFailed ? Icons.warning_rounded : Icons.cancel_rounded);
    String statusText = allCorrect ? 'Phát âm chính xác!' : (isFailed ? 'Chưa Pass (Cải thiện thêm nhé)' : 'Có từ chưa chuẩn');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.sunRed.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.sunRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Trí tuệ nhân tạo (Azure Speech)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Score pills ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScorePill('Phát âm',  feedback.accuracy),
              _buildScorePill('Ngắt nghỉ', feedback.fluency),
              _buildScorePill('Ngữ điệu', feedback.prosody),
            ],
          ),

          const SizedBox(height: 16),

          // ── Nhận diện + màu chữ ──────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, size: 18, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.6),
                    children: _buildWordsAnalysisText(feedback.wordsAnalysis, sent.kanji.isNotEmpty ? sent.kanji : sent.romaji),
                  ),
                ),
              ],
            ),
          ),

          // ── AI gợi ý (Gemini) — duy nhất, luôn hiện ──────
          if (feedback.tip.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildAiTipBox(feedback.tip, allCorrect),
          ],
        ],
      ),
    );
  }

  /// Hộp gợi ý AI (Gemini) — hiển thị sau mỗi lần shadowing
  Widget _buildAiTipBox(String tip, bool isGood) {
    final bgColor   = isGood ? const Color(0xFFECFDF5) : const Color(0xFFF5F3FF);
    final iconColor = isGood ? AppColors.successGreen   : const Color(0xFF7C3AED);
    final textColor = isGood ? const Color(0xFF065F46)  : const Color(0xFF4C1D95);
    final icon      = isGood ? Icons.auto_awesome_rounded : Icons.tips_and_updates_rounded;
    final label     = isGood ? 'Nhận xét của AI ✨' : 'Gợi ý cải thiện từ AI ✨';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tip,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  /// Chỉ ra vị trí ngắt âm đúng trong câu mẫu
  Widget _buildRhythmHint(String text) {
    // Tìm các vị trí ngắt (、。！？)
    final pauseChars = ['、', '。', '！', '？', '!', '?'];
    final hasPause = pauseChars.any((c) => text.contains(c));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.music_note_rounded, size: 16, color: Colors.orange),
              SizedBox(width: 6),
              Text(
                'Nhịp ngắt chưa khớp mẫu',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasPause) ...[
            const Text(
              'Hãy ngắt hơi đúng tại các ký hiệu «▼» bên dưới:',
              style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
            ),
            const SizedBox(height: 6),
            // Hiển thị câu với ▼ đánh dấu chỗ ngắt
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF1E293B)),
                children: _buildPauseMarkedText(text),
              ),
            ),
          ] else
            const Text(
              'Câu này không có dấu ngắt rõ ràng. Hãy luyện nói đều hơi liền mạch từ đầu đến cuối.',
              style: TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.4),
            ),
        ],
      ),
    );
  }

  /// Tạo RichText đánh dấu ▼ tại vị trí ngắt (、。！？)
  List<TextSpan> _buildPauseMarkedText(String text) {
    final markers = RegExp(r'[、。！？!?]');
    final spans = <TextSpan>[];
    int last = 0;
    for (final m in markers.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(TextSpan(
        text: text[m.start],
        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
      ));
      spans.add(const TextSpan(
        text: ' ▼ ',
        style: TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return spans;
  }

  /// Recommend về ngữ điệu (Pitch-accent)
  Widget _buildProsodyRecommend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.record_voice_over_rounded, size: 16, color: Colors.purple),
              SizedBox(width: 6),
              Text(
                'Gợi ý cải thiện Ngữ điệu',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _prosodyTip('🎵', 'Tiếng Nhật dùng Pitch-accent (âm cao-thấp), không phải nhấn âm mạnh/yếu như tiếng Việt.'),
          _prosodyTip('🔄', 'Thường: trợ từ は・が・を có xu hướng xuống giọng sau đỉnh cao.'),
          _prosodyTip('🎧', 'Nghe lại mẫu chậm 0.75× nhiều lần, chú ý chỗ giọng lên và xuống.'),
          _prosodyTip('🗣️', 'Nhái nguyên âm điệu của người đọc mẫu, không chỉ nhái từ ngữ.'),
        ],
      ),
    );
  }

  Widget _prosodyTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4C1D95), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildWordsAnalysisText(List<WordAnalysisModel> words, String originalText) {
    if (words.isEmpty) {
      return [TextSpan(text: originalText, style: const TextStyle(color: AppColors.successGreen))];
    }
    
    return words.map((wordObj) {
      if (wordObj.isCorrect) {
        return TextSpan(
          text: wordObj.text, 
          style: const TextStyle(color: AppColors.successGreen)
        );
      } else {
        return TextSpan(
          text: wordObj.text,
          style: const TextStyle(
            color: AppColors.sunRed,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.sunRed,
          ),
        );
      }
    }).toList();
  }


  Widget _buildScorePill(String label, int score) {
    Color color = score >= 80 ? AppColors.successGreen : (score >= 60 ? Colors.orange : AppColors.sunRed);
    Color bgColor = score >= 80 ? AppColors.successGreenLight : (score >= 60 ? Colors.orange.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1));
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.2))),
          child: Text('$score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }
}
