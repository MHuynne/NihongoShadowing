import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_application_1/core/theme/app_colors.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isUser; // true = Red, false = Pink
  final bool isRecording;

  const WaveformVisualizer({
    super.key,
    required this.isUser,
    required this.isRecording,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int barCount = 15;
  final RandomWaveGenerator _generator = RandomWaveGenerator();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.isRecording) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WaveformVisualizer oldWidget) {
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0.2); // Settle down
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isUser ? AppColors.sunRed : AppColors.sakuraPink;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isUser)
            Text(
              'AI VOICE ANALYZING...',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: color,
              ),
            ),
          if (!widget.isUser) const SizedBox(height: 12),
          SizedBox(
            height: widget.isUser ? 80 : 60,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(barCount, (index) {
                    final height = widget.isRecording 
                        ? math.max(10.0, _generator.getHeight(index, _controller.value) * (widget.isUser ? 80 : 60))
                        : 10.0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: widget.isUser ? 8 : 6,
                      height: height,
                      decoration: BoxDecoration(
                        color: widget.isUser && widget.isRecording ? color : color.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RandomWaveGenerator {
  final math.Random random = math.Random(42); // fixed seed for predictable look
  final List<double> baseHeights = [];

  RandomWaveGenerator() {
    for (int i = 0; i < 15; i++) {
      // Create a nice envelope that is taller in the middle
      double envelope = math.sin((i / 14) * math.pi); 
      baseHeights.add(envelope * 0.8 + 0.2); 
    }
  }

  double getHeight(int index, double animationValue) {
    // Make the bars bounce slightly out of phase
    double phaseOffset = index * 0.5;
    double animatedMultiplier = (math.sin(animationValue * math.pi * 2 + phaseOffset) + 1) / 2; // 0 to 1
    return baseHeights[index] * (0.4 + 0.6 * animatedMultiplier);
  }
}
