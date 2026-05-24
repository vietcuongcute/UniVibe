class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });
}
