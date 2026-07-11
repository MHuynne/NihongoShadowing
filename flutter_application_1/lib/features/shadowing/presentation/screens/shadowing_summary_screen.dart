import 'package:flutter/material.dart';
import 'dart:math' as math;

const _kRed    = Color(0xFFFF4D6D);
const _kGold   = Color(0xFFFFB800);
const _kGreen  = Color(0xFF16A34A);
const _kBg     = Color(0xFFF8F9FE);
const _kDark   = Color(0xFF1E293B);
const _kGray   = Color(0xFF94A3B8);


class SentenceResult {
  final String kanji;
  final int accuracy;
  final int fluency;
  final int prosody;
  final bool passed;

  const SentenceResult({
    required this.kanji,
    required this.accuracy,
    required this.fluency,
    required this.prosody,
    required this.passed,
  });
}


class ShadowingSummaryScreen extends StatefulWidget {
  final List<SentenceResult> results;
  final String topicTitle;

  const ShadowingSummaryScreen({
    super.key,
    required this.results,
    this.topicTitle = 'Shadowing',
  });

  @override
  State<ShadowingSummaryScreen> createState() => _ShadowingSummaryScreenState();
}

class _ShadowingSummaryScreenState extends State<ShadowingSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _countCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _countAnim;

  int get _passedCount => widget.results.where((r) => r.passed).length;
  int get _totalCount  => widget.results.length;
  double get _overallAccuracy =>
      widget.results.isEmpty ? 0 : widget.results.map((r) => r.accuracy).reduce((a, b) => a + b) / widget.results.length;
  double get _overallFluency =>
      widget.results.isEmpty ? 0 : widget.results.map((r) => r.fluency).reduce((a, b) => a + b) / widget.results.length;
  double get _overallProsody =>
      widget.results.isEmpty ? 0 : widget.results.map((r) => r.prosody).reduce((a, b) => a + b) / widget.results.length;

  int get _xpGained {
    final avg = _overallAccuracy;
    final failPenalty = (_totalCount - _passedCount) * 5;
    return ((avg / 100 * 80) + 20 - failPenalty).clamp(10, 100).toInt();
  }

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _countCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scaleAnim = CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
    _fadeAnim  = CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeIn));
    _countAnim = CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut);
    _mainCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _countCtrl.forward();
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPerfect = _passedCount == _totalCount;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5E8E9), Color(0xFFEEDFE1), Colors.white],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded, color: _kRed, size: 14),
                        const SizedBox(width: 6),
                        const Text('TỔNG KẾT SHADOWING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _kRed, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),


                ScaleTransition(
                  scale: _scaleAnim,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: (isPerfect ? _kGold : _kRed).withValues(alpha: 0.25), blurRadius: 40, spreadRadius: 10)],
                        ),
                        child: Icon(
                          isPerfect ? Icons.emoji_events_rounded : Icons.star_rounded,
                          size: 80,
                          color: isPerfect ? _kGold : _kRed,
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kRed,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text('+$_xpGained XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),


                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        isPerfect ? 'Hoàn Hảo! 🎌' : 'Rất Tốt! 🌸',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: isPerfect ? _kGold : _kRed),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.topicTitle,
                        style: const TextStyle(fontSize: 14, color: _kGray, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),


                FadeTransition(
                  opacity: _fadeAnim,
                  child: Row(
                    children: [
                      Expanded(child: _buildStatCard(Icons.mic_rounded,      'Phát âm',  _overallAccuracy.round(), _kRed)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatCard(Icons.volume_up_rounded, 'Ngắt nghỉ', _overallFluency.round(),  Colors.orange)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatCard(Icons.music_note_rounded,'Ngữ điệu', _overallProsody.round(), Colors.purple)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),


                FadeTransition(
                  opacity: _fadeAnim,
                  child: AnimatedBuilder(
                    animation: _countAnim,
                    builder: (_, __) {
                      final displayPassed = (_countAnim.value * _passedCount).round();
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: _kRed.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCountBadge(displayPassed, 'CÂU ĐẠT', _kGreen),
                            const SizedBox(width: 32),
                            _buildCountBadge(_totalCount - displayPassed, 'CẦN CẢI THIỆN', _kRed),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),


                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chi tiết từng câu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kDark)),
                      const SizedBox(height: 12),
                      ...List.generate(widget.results.length, (i) => _buildSentenceRow(i, widget.results[i])),
                    ],
                  ),
                ),

                const SizedBox(height: 32),


                FadeTransition(
                  opacity: _fadeAnim,
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 58),
                      elevation: 6,
                      shadowColor: _kRed.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('VỀ TRANG CHỦ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGray)),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, String label, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildSentenceRow(int index, SentenceResult r) {
    final color = r.passed ? _kGreen : _kRed;
    final icon  = r.passed ? Icons.check_circle_rounded : Icons.cancel_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              r.kanji.isEmpty ? '(câu ${index + 1})' : r.kanji,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          Row(
            children: [
              _miniScore('${r.accuracy}', Colors.blue),
              const SizedBox(width: 6),
              _miniScore('${r.prosody}', Colors.purple),
            ],
          ),
          const SizedBox(width: 8),
          Icon(icon, color: color, size: 22),
        ],
      ),
    );
  }

  Widget _miniScore(String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}