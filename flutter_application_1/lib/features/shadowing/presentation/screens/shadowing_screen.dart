import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
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
import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:flutter_application_1/features/shadowing/presentation/components/recommendation_bottom_sheet.dart';
import 'package:flutter_application_1/features/roadmap/presentation/screens/lesson_summary_screen.dart';
import 'package:flutter_application_1/features/roadmap/services/progress_service.dart';
import 'package:flutter_application_1/features/shadowing/presentation/screens/shadowing_summary_screen.dart';

class ShadowingScreen extends StatefulWidget {
  final int? segmentId;
  final int? topicId;
  final int? segmentTopicId;
  final int lessonId;
  final int testErrors;

  const ShadowingScreen({
    super.key,
    this.segmentId,
    this.topicId,
    this.segmentTopicId,
    this.lessonId = 0,
    this.testErrors = 0,
  }) : assert(segmentId != null || topicId != null || segmentTopicId != null,
           'Phải truyền segmentId, topicId hoặc segmentTopicId');

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
  bool _isPlayingSample = false;
  double _currentSpeed = 1.0;
  final Set<int> _failedSentences = {};

  final _audioRecorder = AudioRecorder();
  final _audioPlayer  = createSampleAudioPlayer();
  String? _recordedFilePath;
  String _topicAudioUrl = '';

  ShadowingFeedbackModel? _dynamicFeedback;
  String _errorWord = "";
  ActionPlan? _lastActionPlan;
  final List<SentenceResult> _sentenceResults = [];

  @override
  void initState() {
    super.initState();
    _fetchTopicData();
  }

  Future<void> _fetchTopicData() async {
    try {
      final String apiUrl;

      if (widget.segmentId != null) {

        apiUrl = '${_baseUrl()}/shadowing/segments/${widget.segmentId}';
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final seg = json.decode(utf8.decode(response.bodyBytes));
          setState(() {
            _sentences = [
              ShadowingSentenceModel(
                title: seg['title'] ?? '',
                kanji: seg['kanji_content'] ?? '',
                furiganaHtml: seg['furigana'] ?? '',
                romaji: seg['romaji'] ?? '',
                hanViet: seg['sino_vietnamese'] ?? '',
                meaning: seg['translation_vi'] ?? '',
              )
            ];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Lỗi tải dữ liệu. HTTP ${response.statusCode}';
            _isLoading = false;
          });
        }
      } else if (widget.segmentTopicId != null) {

        apiUrl = '${_baseUrl()}/segment-topics/${widget.segmentTopicId}';
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final List<dynamic> segmentsData = data['segments'] ?? [];
          segmentsData.sort((a, b) =>
              (a['id'] ?? 0).compareTo(b['id'] ?? 0));

          List<ShadowingSentenceModel> parsed = segmentsData.map((seg) {
            return ShadowingSentenceModel(
              title: seg['title'] ?? '',
              kanji: seg['kanji_content'] ?? '',
              furiganaHtml: seg['furigana'] ?? '',
              romaji: seg['romaji'] ?? '',
              hanViet: seg['sino_vietnamese'] ?? '',
              meaning: seg['translation_vi'] ?? '',
              startTime: (seg['start_time'] as num?)?.toDouble() ?? 0.0,
              endTime: (seg['end_time'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();

          _topicAudioUrl = '';

          if (parsed.isEmpty) {
            parsed.add(ShadowingSentenceModel(
              kanji: 'ごめんなさい！',
              furiganaHtml: '',
              romaji: 'Gomen nasai',
              hanViet: '',
              meaning: 'Chủ đề này chưa được nhập liệu câu nào!',
            ));
          }
          setState(() {
            _sentences = parsed;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Lỗi tải dữ liệu. HTTP ${response.statusCode}';
            _isLoading = false;
          });
        }
      } else {

        apiUrl = '${_baseUrl()}/shadowing/topics/${widget.topicId}';
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final List<dynamic> segmentsData = data['segments'] ?? [];
          segmentsData.sort((a, b) =>
              (a['order_index'] ?? 0).compareTo(b['order_index'] ?? 0));

          List<ShadowingSentenceModel> parsed = segmentsData.map((seg) {
            return ShadowingSentenceModel(
              title: seg['title'] ?? '',
              kanji: seg['kanji_content'] ?? '',
              furiganaHtml: seg['furigana'] ?? '',
              romaji: seg['romaji'] ?? '',
              hanViet: seg['sino_vietnamese'] ?? '',
              meaning: seg['translation_vi'] ?? '',
              startTime: (seg['start_time'] as num?)?.toDouble() ?? 0.0,
              endTime: (seg['end_time'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();


          final rawUrl = (data['full_audio_url'] ?? '').toString();
          _topicAudioUrl = rawUrl.startsWith('http') ? rawUrl
              : (rawUrl.isEmpty ? '' : '${_baseUrl()}$rawUrl');

          if (parsed.isEmpty) {
            parsed.add(ShadowingSentenceModel(
              kanji: 'ごめんなさい！',
              furiganaHtml: '',
              romaji: 'Gomen nasai',
              hanViet: '',
              meaning: 'Bài học này chưa được nhập liệu câu nào!',
            ));
          }
          setState(() {
            _sentences = parsed;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Lỗi tải dữ liệu. HTTP ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể kết nối API: $e';
        _isLoading = false;
      });
    }
  }

  String _baseUrl() {
    return ApiConfig.baseUrl;
  }

  Widget _buildSegmentProgressBar() {
    if (_sentences.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        children: List.generate(_sentences.length, (index) {
          Color color;
          if (index < _currentIndex) {
            if (_failedSentences.contains(index)) {
              color = Colors.orange;
            } else {
              color = const Color(0xFF16A34A);
            }
          } else if (index == _currentIndex) {
            color = AppColors.sunRed;
          } else {
            color = const Color(0xFFE2E8F0);
          }

          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }


  Future<void> _playSample() async {
    final speed = _currentSpeed;
    if (_isPlayingSample) {
      await _audioPlayer.stop();
      setState(() => _isPlayingSample = false);
      return;
    }

    final sentence = _sentences[_currentIndex];
    final text = sentence.kanji.isNotEmpty ? sentence.kanji : sentence.romaji;
    if (text.isEmpty && _topicAudioUrl.isEmpty) return;

    setState(() => _isPlayingSample = true);

    try {

      if (_topicAudioUrl.isNotEmpty) {
        await _audioPlayer.playUrlFromTo(
          _topicAudioUrl,
          sentence.startTime,
          sentence.endTime,
          onComplete: () {
            if (mounted) setState(() => _isPlayingSample = false);
          },
        );
        return;
      }


      if (text.isEmpty) return;
      final response = await http.post(
        Uri.parse('${_baseUrl()}/tts/sample'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'speed': speed, 'voice_gender': 'female'}),
      );
      if (response.statusCode == 200) {
        await _audioPlayer.play(
          response.bodyBytes,
          onComplete: () {
            if (mounted) setState(() => _isPlayingSample = false);
          },
        );
      } else {
        throw Exception('TTS API');
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
             path = '${tempDir.path}/shadowing_record.wav';
          }

          await _audioRecorder.start(
            RecordConfig(
              encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.wav,
              sampleRate: 16000,
              numChannels: 1
            ),
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
     String apiUrl = '${ApiConfig.baseUrl}/evaluate/shadowing';

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
                request.files.add(http.MultipartFile.fromBytes('audio', blobResponse.bodyBytes, filename: 'record.webm'));
              } catch (e) {
                debugPrint("Web blob load error: $e");
              }
           } else {
              if (File(_recordedFilePath!).existsSync()) {
                 request.files.add(await http.MultipartFile.fromPath('audio', _recordedFilePath!));
              }
           }
        }

        debugPrint('--- SHADOWING EVALUATE API REQUEST ---');
        debugPrint('URL: ${request.method} ${request.url}');
        debugPrint('Fields: ${request.fields}');
        for (var file in request.files) {
          debugPrint('File: ${file.field} - ${file.filename} (length: ${file.length})');
        }
        debugPrint('--------------------------------------');


        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 90),
          onTimeout: () => throw Exception('Hết thời gian chờ AI chấm điểm (>90s). Vui lòng thử lại.'),
        );
        final response = await http.Response.fromStream(streamedResponse);


        if (response.statusCode == 200) {
           final data = json.decode(utf8.decode(response.bodyBytes));
           setState(() {
              _dynamicFeedback = ShadowingFeedbackModel(
                accuracy: data['accuracy'] ?? 0,
                fluency: data['fluency'] ?? 0,
                prosody: data['prosody'] ?? 0,
                rhythm: data['rhythm'] ?? 0,
                feedbackHtml: data['recognized_text'] ?? '',
                tip: data['tip'] ?? '',
                wordsAnalysis: (data['words_analysis'] as List<dynamic>?)
                        ?.map((e) => WordAnalysisModel.fromJson(e as Map<String, dynamic>))
                        .toList() ??
                    [],
                misprnouncedWords: List<String>.from(
                  data['mispronounced_words'] ?? [],
                ),
                errorTypes: ErrorTypes.fromJson(
                  data['error_types'] as Map<String, dynamic>?,
                ),
                actionPlan: ActionPlan.fromJson(
                  data['action_plan'] as Map<String, dynamic>?,
                ),
              );
              _errorWord = data['error_word'] ?? '';
              _lastActionPlan = _dynamicFeedback!.actionPlan;


              bool hasWordError = _dynamicFeedback!.wordsAnalysis.any((w) => !w.isCorrect);
              final acc = data['accuracy'] ?? 0;
              final passed = acc >= 50 && !hasWordError && _errorWord.isEmpty;
              if (!passed) {
                _failedSentences.add(_currentIndex);
              } else {
                _failedSentences.remove(_currentIndex);
              }


              final sentence = _sentences[_currentIndex];
              final resultEntry = SentenceResult(
                kanji: sentence.kanji.isNotEmpty ? sentence.kanji : sentence.romaji,
                accuracy: acc,
                fluency: data['fluency'] ?? 0,
                prosody: data['prosody'] ?? 0,
                passed: passed,
              );

              if (_currentIndex < _sentenceResults.length) {
                _sentenceResults[_currentIndex] = resultEntry;
              } else {
                while (_sentenceResults.length < _currentIndex) {
                  _sentenceResults.add(SentenceResult(kanji: '', accuracy: 0, fluency: 0, prosody: 0, passed: false));
                }
                _sentenceResults.add(resultEntry);
              }

              _isEvaluating = false;
              _showFeedback = true;
           });
        }
      } catch (e) {
         String errorMsg;
         final errStr = e.toString();
         if (errStr.contains('Hết thời gian')) {
           errorMsg = errStr;
         } else if (errStr.contains('SocketException') || errStr.contains('Connection')) {
           errorMsg = 'Không thể kết nối server. Kiểm tra server có đang chạy không.';
         } else {
           errorMsg = 'Lỗi kết nối AI: $e';
         }
         setState(() {
            _isEvaluating = false;
            _dynamicFeedback = ShadowingFeedbackModel(accuracy: 0, feedbackHtml: "", tip: errorMsg);
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
    if (_currentIndex < _sentences.length - 1) {

      setState(() {
        _currentIndex++;
        _isBlindMode = false;
        _showFeedback = false;
      });
    } else {

      final plan = _lastActionPlan ?? ActionPlan(
        message: 'Bạn đã hoàn thành bài học! Tiếp tục luyện tập mỗi ngày nhé 🌸',
        action: ActionType.celebrate,
        severity: 0,
      );
      final feedback = _dynamicFeedback;

      RecommendationBottomSheet.show(
        context: context,
        actionPlan: plan,
        errorTypes: feedback?.errorTypes ?? const ErrorTypes(),
        misprnouncedWords: feedback?.misprnouncedWords ?? [],
        accuracy: feedback?.accuracy ?? 0,
        fluency: feedback?.fluency ?? 0,
        prosody: feedback?.prosody ?? 0,
        onActionPressed: _handleActionPlanPress,
        onContinue: _navigateToSummary,
      );
    }
  }


  void _handleActionPlanPress() {
    final plan = _lastActionPlan;
    if (plan == null) return;

    switch (plan.action) {
      case ActionType.activateSlowMode:

        setState(() => _currentSpeed = 0.75);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏱️ Đã bật chế độ 0.75x cho lần phát tiếp theo!'),
            backgroundColor: Color(0xFFFF6B9D),
          ),
        );
        break;

      case ActionType.showHanVietMode:

        setState(() {
          _isBlindMode = false;
          _showFeedback = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌸 Đã bật chế độ Hiện Hán-Việt!'),
            backgroundColor: Color(0xFFFF6B9D),
          ),
        );
        break;

      case ActionType.openVocabulary:

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📖 Mở từ: ${plan.targetWord ?? "kho từ vựng"}'),
            backgroundColor: const Color(0xFFFF6B9D),
          ),
        );
        break;

      default:
        break;
    }
  }


  Future<void> _navigateToSummary() async {
    final totalSentences = _sentences.length;
    final failedCount = _failedSentences.length;

    final double shadowingScore;
    if (_sentenceResults.isNotEmpty) {
      final avgAcc = _sentenceResults
          .map((r) => r.accuracy as num)
          .reduce((a, b) => a + b) / _sentenceResults.length;
      shadowingScore = avgAcc.toDouble().clamp(0.0, 100.0);
    } else if (totalSentences == 0) {
      shadowingScore = 0.0;
    } else {
      shadowingScore = ((totalSentences - failedCount) / totalSentences) * 100.0;
    }

    if (widget.lessonId != 0) {
      await ProgressService.saveShadowingResult(widget.lessonId, shadowingScore);
      await ProgressService.markLessonCompleted(widget.lessonId);
    }

    if (!mounted) return;

    if (widget.lessonId == 0) {


      while (_sentenceResults.length < _sentences.length) {
        _sentenceResults.add(SentenceResult(
          kanji: _sentences[_sentenceResults.length].kanji,
          accuracy: 0, fluency: 0, prosody: 0, passed: false,
        ));
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ShadowingSummaryScreen(
            results: _sentenceResults,
            topicTitle: _sentences.isNotEmpty ? _sentences[0].title : 'Shadowing',
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LessonSummaryScreen(
            testErrors: widget.testErrors,
            shadowingErrors: failedCount,
            lessonId: widget.lessonId,
            shadowingScore: shadowingScore,
          ),
        ),
      );
    }
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
                  segmentTitle: _sentences.isNotEmpty
                      ? _sentences[_currentIndex].title
                      : null,
                ),
                _buildSegmentProgressBar(),
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


          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScorePill('Phát âm',  feedback.accuracy),
              _buildScorePill('Ngắt nghỉ', feedback.fluency),
              _buildScorePill('Ngữ điệu', feedback.prosody),
            ],
          ),

          const SizedBox(height: 16),


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


          if (feedback.tip.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildAiTipBox(feedback.tip, allCorrect),
          ],
        ],
      ),
    );
  }


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


  Widget _buildRhythmHint(String text) {

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