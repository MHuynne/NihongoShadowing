import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/chat_message_model.dart';
import 'furigana_text.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('h:mm a').format(message.timestamp);
    
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 16.0, left: 64.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.progressTeal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                message.plainText ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeString,
              style: const TextStyle(
                color: AppColors.slate400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 64.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bot Avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.slate800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.furiganaText != null)
                          FuriganaText(words: message.furiganaText!, textColor: AppColors.textDark)
                        else if (message.plainText != null)
                          Text(message.plainText!, style: const TextStyle(fontSize: 16, color: AppColors.textDark, height: 1.5)),
                        
                        if (message.translation != null) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.slate300),
                          const SizedBox(height: 12),
                          Text(
                            message.translation!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.slate600,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
