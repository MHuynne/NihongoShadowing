import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/chat_bubble.dart';
import '../widgets/roleplay_mic_button.dart';
import '../widgets/grammar_feedback_box.dart';
import '../roleplay_service.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';

class RoleplayChatScreen extends StatefulWidget {
  final String title;
  final String description;
  final String mode;

  const RoleplayChatScreen({
    super.key,
    required this.title,
    required this.description,
    required this.mode,
  });

  @override
  State<RoleplayChatScreen> createState() => _RoleplayChatScreenState();
}

class _RoleplayChatScreenState extends State<RoleplayChatScreen> {
  final RoleplayService _apiService = RoleplayService();
  int? _sessionId;
  bool _isLoading = false;
  DateTime? _rateLimitUntil;
  Timer? _cooldownTimer;

  final List<Widget> _chatItems = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechInitialized = false;
  bool _isRecording = false;
  String _currentVoiceText = '';
  String _textBeforeCurrentSegment = '';

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isSpeechInitialized = await _speech.initialize(
        onStatus: (status) async {
          print('STT Status: $status');
          if ((status == 'done' || status == 'notListening') && _isRecording) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (_isRecording && !_speech.isListening) {
              _startListening();
            }
          }
        },
        onError: (error) {
          print('STT Error detail: $error');
          if (error.errorMsg.contains('no_match') ||
              error.errorMsg.contains('timeout')) {
            print('STT: Ignored minor error (${error.errorMsg}), continuing loop...');
            return;
          }
          if (error.errorMsg.contains('error_busy')) return;

          if (mounted && _isRecording) {
            setState(() => _isRecording = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mic đã dừng: ${error.errorMsg}'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
      );
      if (_isSpeechInitialized) {
        var locales = await _speech.locales();
        bool hasJapanese = locales.any((l) => l.localeId.contains('ja'));
        if (!hasJapanese) {
          print('STT: Japanese locale not found on this device');
        }
      }
      setState(() {});
    } catch (e) {
      print('STT Init Exception: $e');
    }
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      final scenarioId = await _apiService.getOrCreateScenario(
          widget.title, widget.description);
      final sessionId =
          await _apiService.createSession(scenarioId, widget.mode);

      setState(() {
        _sessionId = sessionId;
        _isLoading = false;
        _addMessage(
            'Sensei: Xin chào! Bối cảnh đã sẵn sàng. Mời bạn bắt đầu hội thoại.',
            false);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _addMessage(
          'Lỗi kết nối Server: Hãy chắc chắn bạn đã chạy Backend Python!',
          false);
    }
  }

  int get _remainingCooldownSeconds {
    final until = _rateLimitUntil;
    if (until == null) return 0;

    final remaining = until.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  bool get _isRateLimited => _remainingCooldownSeconds > 0;

  void _startCooldown(int seconds) {
    if (seconds <= 0) return;

    _cooldownTimer?.cancel();
    setState(() {
      _rateLimitUntil = DateTime.now().add(Duration(seconds: seconds));
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingCooldownSeconds <= 0) {
        timer.cancel();
        setState(() {
          _rateLimitUntil = null;
        });
        return;
      }

      setState(() {});
    });
  }

  void _addMessage(String text, bool isUser) {
    if (!mounted) return;
    setState(() {
      _chatItems.add(ChatBubble(text: text, isUser: isUser));
    });
    _scrollToBottom();
  }

  void _addGrammarFeedback(Map<String, dynamic> feedback) {
    setState(() {
      _chatItems.add(GrammarFeedbackBox(
        error: feedback['error'],
        correction: feedback['correction'],
        explanation: feedback['explanation'],
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendText(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty ||
        _sessionId == null ||
        _isLoading ||
        _isRateLimited) return;

    if (_isRecording) {
      _stopListening();
    }
    _currentVoiceText = '';
    _textBeforeCurrentSegment = '';

    _addMessage(trimmedText, true);
    _textController.clear();
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.chatWithAI(_sessionId!, trimmedText);
      final retryAfterSeconds = response['retry_after_seconds'] as int?;
      if (retryAfterSeconds != null && retryAfterSeconds > 0) {
        _startCooldown(retryAfterSeconds);
      }

      setState(() {
        _isLoading = false;
        _addMessage(response['ai_reply'], false);

        if (response['grammar_correction'] != null) {
          _addGrammarFeedback(response['grammar_correction']);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _addMessage('Lỗi AI: Không thể nhận phản hồi từ Sensei.', false);
      }
    }
  }

  void _toggleRecording() {
    if (_isRateLimited) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI đang quá tải, thử lại sau $_remainingCooldownSeconds giây.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isRecording) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_speech.isListening) return;
    try {
      if (_isSpeechInitialized) {
        setState(() {
          _isRecording = true;
          _textBeforeCurrentSegment = _textController.text;

          if (_textBeforeCurrentSegment.isNotEmpty &&
              !_textBeforeCurrentSegment.endsWith(' ')) {
            _textBeforeCurrentSegment += ' ';
          }
          _currentVoiceText = '';
        });

        var locales = await _speech.locales();
        String? targetLocaleId;
        for (var l in locales) {
          if (l.localeId.contains('ja')) {
            targetLocaleId = l.localeId;
            break;
          }
        }

        if (targetLocaleId == null && locales.isNotEmpty) {
          targetLocaleId = locales.first.localeId;
        }

        await _speech.listen(
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty) {
              setState(() {
                _currentVoiceText = result.recognizedWords;
                _textController.text =
                    _textBeforeCurrentSegment + _currentVoiceText;
                _textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _textController.text.length),
                );
              });
            }
          },
          localeId: targetLocaleId,
          listenFor: const Duration(minutes: 20),
          pauseFor: const Duration(seconds: 60),
          onDevice: false,
          cancelOnError: false,
          partialResults: true,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Lỗi: Không thể khởi động Mic. Hãy kiểm tra quyền truy cập!')),
          );
        }
      }
    } catch (e) {
      print('STT Exception in _startListening: $e');
    }
  }

  Future<void> _stopListening() async {
    setState(() => _isRecording = false);
    await _speech.stop();

    if (_currentVoiceText.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã nhận diện xong. Bạn có thể chỉnh sửa trước khi gửi!'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không nghe thấy nội dung. Hãy thử lại!')),
        );
      }
    }
  }

  Future<void> _endConversation() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E0F38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: SNJ.border, width: 1.2),
        ),
        title: const Text(
          'Kết thúc cuộc trò chuyện?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn sẽ quay lại màn hình thiết lập roleplay.',
          style: TextStyle(color: SNJ.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy', style: TextStyle(color: SNJ.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );

    if (shouldEnd != true || !mounted) return;

    if (_isRecording) {
      setState(() => _isRecording = false);
      await _speech.stop();
    }

    _cooldownTimer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: SNJ.bgDeep.withOpacity(0.55),
                border: const Border(
                  bottom: BorderSide(color: SNJ.border, width: 0.8),
                ),
              ),
            ),
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: false,
        leadingWidth: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: SNJ.sakuraGlow, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: SNJ.sakura.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: SNJ.sakuraSoft,
                child: const Text('🌸', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'AI Sensei Online',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: _endConversation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25), width: 1),
                  ),
                  child: const Icon(
                    Icons.call_end_rounded,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SakuraNightBackground(
        child: Column(
          children: [
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: SNJ.sakura,
                backgroundColor: Colors.transparent,
              ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                border: const Border(
                  bottom: BorderSide(color: SNJ.border, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_fix_high, size: 16, color: SNJ.sakura),
                  const SizedBox(width: 8),
                  const Text(
                    'Chế độ: ',
                    style: TextStyle(fontSize: 13, color: SNJ.textSecondary),
                  ),
                  Text(
                    widget.mode == 'keigo' ? "Lịch sự / Kính ngữ" : "Thân mật / Plain",
                    style: const TextStyle(
                      fontSize: 13,
                      color: SNJ.sakura,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (_isRateLimited)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                color: const Color(0xFFFEF3C7).withOpacity(0.15),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI đang bận. Vui lòng đợi $_remainingCooldownSeconds giây.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                itemCount: _chatItems.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _chatItems[index],
                  );
                },
              ),
            ),

            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: SNJ.bgDeep.withOpacity(0.85),
                border: const Border(
                  top: BorderSide(color: SNJ.border, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  RoleplayMicButton(
                    isRecording: _isRecording,
                    onTap: (_isLoading || _isRateLimited) ? () {} : _toggleRecording,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: SNJ.border, width: 0.8),
                      ),
                      child: TextField(
                        controller: _textController,
                        readOnly: _isLoading || _isRateLimited,
                        style: const TextStyle(fontSize: 15, color: Colors.white),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'Nhận xét bằng tiếng Nhật...',
                          hintStyle: const TextStyle(color: SNJ.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.send_rounded,
                              color: (_isLoading || _isRateLimited)
                                  ? SNJ.textMuted
                                  : SNJ.sakura,
                            ),
                            onPressed: (_isLoading || _isRateLimited)
                                ? null
                                : () => _handleSendText(_textController.text),
                          ),
                        ),
                        onSubmitted: (_isLoading || _isRateLimited)
                            ? null
                            : (val) => _handleSendText(val),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}