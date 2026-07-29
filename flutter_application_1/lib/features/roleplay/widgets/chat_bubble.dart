import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: (isUser ? SNJ.sakura : Colors.black).withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: isUser ? SNJ.sakuraGradient : null,
          color: isUser ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: Border.all(
            color: isUser ? Colors.transparent : SNJ.border,
            width: isUser ? 0 : 0.8,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : SNJ.textPrimary,
            fontSize: 15,
            fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}