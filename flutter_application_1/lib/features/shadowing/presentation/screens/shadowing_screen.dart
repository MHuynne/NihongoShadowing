import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/shadowing/models/shadowing_model.dart';
import 'package:flutter_application_1/features/shadowing/presentation/components/shadowing_card.dart';
import 'package:flutter_application_1/features/shadowing/presentation/components/shadowing_controls.dart';
import 'package:flutter_application_1/features/shadowing/presentation/components/shadowing_header.dart';
import 'package:flutter_application_1/features/shadowing/presentation/components/waveform_visualizer.dart';

class ShadowingScreen extends StatefulWidget {
  const ShadowingScreen({super.key});

  @override
  State<ShadowingScreen> createState() => _ShadowingScreenState();
}

class _ShadowingScreenState extends State<ShadowingScreen> {
  // Mock State
  bool _isBlindMode = false;
  bool _isRecording = false;
  bool _showFeedback = false;

  final _dummySentence = ShadowingSentenceModel(
    kanji: '今日は天気がいいですね',
    furiganaHtml: '',
    romaji: 'Kyō wa tenki ga ii desu ne',
    hanViet: 'Kim nhật thiên khí lương hằng',
    meaning: 'Hôm nay thời tiết đẹp nhỉ',
  );

  final _dummyFeedback = ShadowingFeedbackModel(
    accuracy: 85,
    feedbackHtml: '', // Simplified via RichText below
    tip: 'Mẹo: Cố gắng nhấn mạnh âm "te" trong "tenki" rõ hơn một chút.',
  );

  void _toggleRecording() {
    setState(() {
      if (_showFeedback) {
        _showFeedback = false;
      }
      _isRecording = !_isRecording;
      if (!_isRecording) {
        // Simulate completing a recording and showing feedback
        _showFeedback = true;
      }
    });
  }

  void _toggleMode(bool isBlind) {
    setState(() {
      _isBlindMode = isBlind;
      _showFeedback = false; // reset feedback on mode switch
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            ShadowingHeader(
              currentIndex: 3,
              totalCount: 10,
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
                        isRecording: true, // Auto play AI voice conceptually
                      ),
                    
                    if (!_isBlindMode) const SizedBox(height: 32),
                    
                    // Main Content Card
                    ShadowingCard(
                      sentence: _dummySentence,
                      isBlindMode: _isBlindMode,
                    ),

                    const SizedBox(height: 32),

                    // Dependent States Below Card
                    if (_showFeedback) ...[
                      _buildFeedbackCard(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (!_isBlindMode) {
                                // Transition to blind mode automatically
                                _isBlindMode = true;
                                _showFeedback = false;
                              } else {
                                // Move to next sentence in a real app, here we loop back
                                _isBlindMode = false;
                                _showFeedback = false;
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sunRed,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            elevation: 4,
                            shadowColor: AppColors.sunRed.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            !_isBlindMode ? 'Bước tiếp theo: Đọc ẩn chữ' : 'Hoàn thành / Câu tiếp theo',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ] else if (_isBlindMode || _isRecording) ...[
                      const Text(
                        'USER VOICE',
                        style: TextStyle(color: AppColors.sunRed, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isRecording ? 'Đang ghi âm...' : 'Sẵn sàng đọc...',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            if (_isRecording)
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.sunRed,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('LIVE', style: TextStyle(color: AppColors.sunRed, fontWeight: FontWeight.bold, fontSize: 10)),
                                ],
                              ),
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
            
            // Bottom Controls
            ShadowingControls(
              isRecording: _isRecording,
              onRecordPressed: _toggleRecording,
              onPlaySample: () {
                // Future Implementation: play AI sample again
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.itemBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    'AI Analysis',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Accuracy: ${_dummyFeedback.accuracy}%',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
                    children: [
                      TextSpan(text: 'Kyou wa ', style: TextStyle(color: AppColors.successGreen)),
                      TextSpan(
                        text: 'tenki', 
                        style: TextStyle(
                          color: AppColors.sunRed, 
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.wavy,
                          decorationColor: AppColors.sunRed,
                        ),
                      ),
                      TextSpan(text: ' ga ii desu ne', style: TextStyle(color: AppColors.successGreen)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _dummyFeedback.tip,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate500, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
