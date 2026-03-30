import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/chat_message_model.dart';
import '../components/chat_bubble.dart';
import '../components/chat_input_bar.dart';
import '../components/keigo_suggestion_card.dart';

class KingoChatScreen extends StatefulWidget {
  const KingoChatScreen({super.key});

  @override
  State<KingoChatScreen> createState() => _KingoChatScreenState();
}

class _KingoChatScreenState extends State<KingoChatScreen> {
  final List<ChatMessageModel> _messages = [
    ChatMessageModel(
      id: '1',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      furiganaText: const [
        ChatFuriganaWord('初', furigana: 'はじ'),
        ChatFuriganaWord('めまして、'),
        ChatFuriganaWord('私', furigana: 'わたし'),
        ChatFuriganaWord('\nはキンゴです。'),
      ],
      translation: 'Rất vui được gặp bạn, tôi là Kingo. / Nice to meet you, I\'m Kingo.',
    ),
    ChatMessageModel(
      id: '2',
      isUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      plainText: 'こんにちは、キンゴさん。私は学生です。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.slate800),
          onPressed: () {},
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.slate200,
                  radius: 20,
                  child: const Icon(Icons.person, color: AppColors.slate400),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Kingo Chat',
                  style: TextStyle(
                    color: AppColors.slate900,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ONLINE',
                  style: TextStyle(
                    color: AppColors.progressTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.slate800),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.slate200,
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              children: [
                // Today Label
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.progressTeal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        color: AppColors.progressTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                ..._messages.map((m) => ChatBubble(message: m)).toList(),
                
                // Keigo Suggestion
                KeigoSuggestionCard(onApply: () {
                  // Implement functionality to apply suggestion
                }),
              ],
            ),
          ),
          const ChatInputBar(),
        ],
      ),
    );
  }
}
