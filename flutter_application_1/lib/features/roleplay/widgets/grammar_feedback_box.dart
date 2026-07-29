import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';

class GrammarFeedbackBox extends StatelessWidget {
  final String error;
  final String correction;
  final String explanation;

  const GrammarFeedbackBox({
    super.key,
    required this.error,
    required this.correction,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SNJ.sakura.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: SNJ.sakura.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: SNJ.sakura,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: SNJ.sakura, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'AI Sensei Feedback',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: SNJ.sakura,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: SNJ.textSecondary,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: 'Sai: '),
                            TextSpan(
                              text: error,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: SNJ.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            const TextSpan(text: 'Sửa lại: '),
                            TextSpan(
                              text: correction,
                              style: const TextStyle(color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          explanation,
                          style: const TextStyle(
                            fontSize: 13,
                            color: SNJ.textSecondary,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}