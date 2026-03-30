import 'package:flutter/material.dart';
import '../../models/chat_message_model.dart';

class FuriganaText extends StatelessWidget {
  final List<ChatFuriganaWord> words;
  final Color textColor;

  const FuriganaText({
    super.key,
    required this.words,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 0.0,
      runSpacing: 4.0,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: words.map((w) {
        if (w.text == '\n') {
          return const SizedBox(width: double.infinity, height: 4); // basic line break
        }
        
        if (w.furigana == null || w.furigana!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(
              w.text,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                height: 1.2,
              ),
            ),
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                w.furigana!,
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withOpacity(0.8),
                  height: 1.0,
                ),
              ),
              Text(
                w.text,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  height: 1.2,
                ),
              ),
            ],
          );
        }
      }).toList(),
    );
  }
}
