import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/chat_bubble.dart';
import '../widgets/roleplay_mic_button.dart';
import '../widgets/grammar_feedback_box.dart';
import '../roleplay_service.dart';
import '../../../core/theme/app_colors.dart';

class RoleplayChatScreen extends StatefulWidget {
  final String title;
  final String description;
  final String mode; // 'keigo' hoặc 'plain'

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

  // Speech to Text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechInitialized = false;
  bool _isRecording = false;
  String _currentVoiceText = '';
  String _textBeforeCurrentSegment =
      ''; // Lưu trữ văn bản cũ trước khi bắt đầu lượt nghe mới

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
          // Nếu hệ thống tự ngắt mà mình vẫn muốn ghi âm (_isRecording)
          // thì tự động kích hoạt lại vòng lặp nghe sau một khoảng nghỉ ngắn
          if ((status == 'done' || status == 'notListening') && _isRecording) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (_isRecording && !_speech.isListening) {
              _startListening();
            }
          }
        },
        onError: (error) {
          print('STT Error detail: $error');

          // Các lỗi nên bỏ qua để đảm bảo tính liên tục:
          // error_no_match (không nghe thấy tiếng)
          // error_speech_timeout (hết thời gian chờ)
          if (error.errorMsg.contains('no_match') ||
              error.errorMsg.contains('timeout')) {
            print(
                'STT: Ignored minor error (${error.errorMsg}), continuing loop...');
            return;
          }

          // Ngăn chặn việc hiện SnackBar quá nhiều với các lỗi không cần thiết
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
        // Kiểm tra xem ja_JP có hỗ trợ không
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

    // Tắt mic và xóa bộ nhớ tạm của giọng nói khi bắt đầu gửi tin nhắn
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
        // Hiển thị câu trả lời của AI
        _addMessage(response['ai_reply'], false);

        // Hiển thị feedback ngữ pháp nếu có
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
          content: Text(
              'AI đang quá tải, thử lại sau $_remainingCooldownSeconds giây.'),
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
    // Nếu đang nghe rồi thì không làm gì cả
    if (_speech.isListening) return;

    print('STT: _startListening called');
    try {
      if (_isSpeechInitialized) {
        print('STT: Mic is available, starting to listen...');
        setState(() {
          _isRecording = true;
          _textBeforeCurrentSegment =
              _textController.text; // Giữ lại nội dung cũ
          // Nếu ô chat đã có chữ thì thêm dấu cách để nối từ cho đẹp
          if (_textBeforeCurrentSegment.isNotEmpty &&
              !_textBeforeCurrentSegment.endsWith(' ')) {
            _textBeforeCurrentSegment += ' ';
          }
          _currentVoiceText = '';
        });

        /* 
        // 2. Visual feedback (Đã xóa theo yêu cầu)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('👂 Đang nghe... Hãy nói tiếng Nhật!'),
              duration: Duration(seconds: 2),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        */

        // 3. Select locale
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

        print('STT: Final target locale: $targetLocaleId');

        // 4. Start listening với cấu hình tối ưu nhất
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
          // Sử dụng các tùy chọn nâng cao để tăng độ ổn định
          listenFor: const Duration(minutes: 20),
          pauseFor: const Duration(seconds: 60),
          onDevice:
              false, // Tắt chế độ offline để tránh lỗi language_unavailable
          cancelOnError: false,
          partialResults: true,
        );

        print('STT: _speech.listen() has been called and is running.');
      } else {
        print('STT: Initialization failed or permission denied.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Lỗi: Không thể khởi động Mic. Hãy kiểm tra quyền truy cập!')),
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
            content: Text(
                '✅ Đã nhận diện xong. Bạn có thể chỉnh sửa trước khi gửi!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không nghe thấy nội dung. Hãy thử lại!')),
        );
      }
    }
  }

  Future<void> _endConversation() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết thúc cuộc trò chuyện?'),
        content: const Text('Bạn sẽ quay lại màn hình thiết lập roleplay.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
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
      backgroundColor: AppColors.scaffoldBackground(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface(context),
        foregroundColor: AppColors.primaryText(context),
        centerTitle: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI Sensei Online',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText(context),
                          fontWeight: FontWeight.normal,
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
          IconButton(
            tooltip: 'Kết thúc cuộc trò chuyện',
            icon: const Icon(Icons.call_end_rounded),
            color: AppColors.errorRed,
            onPressed: _endConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.primary,
                backgroundColor: Colors.transparent),

          // Mode Indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              border: Border(
                  bottom:
                      BorderSide(color: AppColors.border(context), width: 1)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_fix_high,
                    size: 16, color: AppColors.primary.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  'Chế độ: ',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.secondaryText(context)),
                ),
                Text(
                  widget.mode == 'keigo'
                      ? "Lịch sự / Kính ngữ"
                      : "Thân mật / Plain",
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          if (_isRateLimited)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.orange.withOpacity(0.12),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI đang bị rate limit. Vui lòng thử lại sau $_remainingCooldownSeconds giây.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryText(context),
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

          /*
          // Debug Status (Đã xóa theo yêu cầu)
          Container(
            color: Colors.black,
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            child: Text(
              'DEBUG: Mic: ${_isSpeechInitialized ? "OK" : "FAIL"} | Text: "$_currentVoiceText"',
              style: const TextStyle(color: Colors.green, fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
          */
          // Input Area
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow(context),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Mic Button
                RoleplayMicButton(
                  isRecording: _isRecording,
                  onTap:
                      (_isLoading || _isRateLimited) ? () {} : _toggleRecording,
                ),
                const SizedBox(width: 12),
                // Text Field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputFill(context),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      readOnly: _isLoading || _isRateLimited,
                      style: TextStyle(
                          fontSize: 15, color: AppColors.primaryText(context)),
                      maxLines: null, // Cho phép tự co giãn theo nội dung
                      keyboardType:
                          TextInputType.multiline, // Hỗ trợ nhập nhiều dòng
                      decoration: InputDecoration(
                        hintText: 'Nhận xét bằng tiếng Nhật...',
                        hintStyle:
                            TextStyle(color: AppColors.tertiaryText(context)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: (_isLoading || _isRateLimited)
                                ? AppColors.tertiaryText(context)
                                : AppColors.primary,
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
    );
  }
}
