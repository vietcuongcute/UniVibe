import 'chat_message.dart';
import 'user_profile.dart';

class BlindChat {
  final String id;
  final UserProfile currentUser;
  final UserProfile otherUser;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool currentUserWantsReveal;
  final bool otherUserWantsReveal;
  final List<ChatMessage> messages;

  BlindChat({
    required this.id,
    required this.currentUser,
    required this.otherUser,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.currentUserWantsReveal,
    required this.otherUserWantsReveal,
    required this.messages,
  });

  BlindChat copyWith({
    String? status,
    bool? currentUserWantsReveal,
    bool? otherUserWantsReveal,
    List<ChatMessage>? messages,
  }) {
    return BlindChat(
      id: id,
      currentUser: currentUser,
      otherUser: otherUser,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      currentUserWantsReveal:
          currentUserWantsReveal ?? this.currentUserWantsReveal,
      otherUserWantsReveal: otherUserWantsReveal ?? this.otherUserWantsReveal,
      messages: messages ?? this.messages,
    );
  }
}
