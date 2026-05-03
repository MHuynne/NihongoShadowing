import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
               BoxShadow(
                 color: Colors.black.withValues(alpha: 0.05),
                 blurRadius: 10,
                 offset: const Offset(0, 4),
               ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.mic, color: AppColors.progressTeal),
              ),
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: AppColors.slate400, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   IconButton(
                     onPressed: () {},
                     icon: const Icon(Icons.translate, color: AppColors.slate400),
                   ),
                   Container(
                     margin: const EdgeInsets.only(right: 6),
                     decoration: const BoxDecoration(
                       color: AppColors.progressTeal,
                       shape: BoxShape.circle,
                     ),
                     child: IconButton(
                       onPressed: () {},
                       icon: const Icon(Icons.send, color: Colors.white, size: 18),
                     ),
                   ),
                 ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
