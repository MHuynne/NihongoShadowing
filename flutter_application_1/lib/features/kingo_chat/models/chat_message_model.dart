class ChatFuriganaWord {
  final String text;
  final String? furigana;

  const ChatFuriganaWord(this.text, {this.furigana});
}

class ChatMessageModel {
  final String id;
  final bool isUser;
  final DateTime timestamp;
  final List<ChatFuriganaWord>? furiganaText;
  final String? translation;
  final String? plainText;

  const ChatMessageModel({
    required this.id,
    required this.isUser,
    required this.timestamp,
    this.furiganaText,
    this.translation,
    this.plainText,
  });
}
