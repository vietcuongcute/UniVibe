import 'chat_message.dart';
import 'user_profile.dart';

class ChatRoom {
  final String id;
  final List<String> userIds;
  final UserProfile otherUser;
  final String lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatRoom({
    required this.id,
    required this.userIds,
    required this.otherUser,
    required this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  ChatRoom copyWith({
    String? lastMessage,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatRoom(
      id: id,
      userIds: userIds,
      otherUser: otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}
