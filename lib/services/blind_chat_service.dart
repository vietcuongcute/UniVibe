import 'package:flutter/material.dart';

import '../models/blind_chat.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

class BlindChatService {
  static final ValueNotifier<BlindChat?> activeBlindChatNotifier =
      ValueNotifier<BlindChat?>(null);

  static BlindChat createBlindChat({
    required UserProfile currentUser,
    required UserProfile otherUser,
  }) {
    final now = DateTime.now();

    final chat = BlindChat(
      id: 'blind_${now.millisecondsSinceEpoch}',
      currentUser: currentUser,
      otherUser: otherUser,
      status: 'active',
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 10)),
      currentUserWantsReveal: false,
      otherUserWantsReveal: false,
      messages: [
        ChatMessage(
          id: 'welcome',
          chatId: 'blind_${now.millisecondsSinceEpoch}',
          senderId: 'system',
          text:
              'Blind chat đã bắt đầu. Hai bạn có 10 phút để trò chuyện trước khi quyết định reveal profile.',
          createdAt: now,
        ),
      ],
    );

    activeBlindChatNotifier.value = chat;

    return chat;
  }

  static void sendMessage(String text) {
    final chat = activeBlindChatNotifier.value;

    if (chat == null) {
      return;
    }

    if (text.trim().isEmpty) {
      return;
    }

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chat.id,
      senderId: chat.currentUser.id,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    activeBlindChatNotifier.value = chat.copyWith(
      messages: [...chat.messages, newMessage],
    );
  }

  static void sendMockReply() {
    final chat = activeBlindChatNotifier.value;

    if (chat == null) {
      return;
    }

    final replies = [
      'Nghe cũng hợp vibe á 😄',
      'Mình cũng thích chủ đề này.',
      'Bạn hay học ở thư viện hay quán cà phê?',
      'Mình thấy profile vibe khá giống nhau.',
      'Haha, nói chuyện vui ghê.',
    ];

    final replyText = replies[DateTime.now().second % replies.length];

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chat.id,
      senderId: chat.otherUser.id,
      text: replyText,
      createdAt: DateTime.now(),
    );

    activeBlindChatNotifier.value = chat.copyWith(
      messages: [...chat.messages, newMessage],
    );
  }

  static void requestReveal() {
    final chat = activeBlindChatNotifier.value;

    if (chat == null) {
      return;
    }

    activeBlindChatNotifier.value = chat.copyWith(currentUserWantsReveal: true);
  }

  static void mockOtherUserAcceptReveal() {
    final chat = activeBlindChatNotifier.value;

    if (chat == null) {
      return;
    }

    activeBlindChatNotifier.value = chat.copyWith(
      otherUserWantsReveal: true,
      status: 'revealed',
    );
  }

  static void expireChatIfNeeded() {
    final chat = activeBlindChatNotifier.value;

    if (chat == null) {
      return;
    }

    if (DateTime.now().isAfter(chat.expiresAt) && chat.status == 'active') {
      activeBlindChatNotifier.value = chat.copyWith(status: 'expired');
    }
  }

  static void endChat() {
    activeBlindChatNotifier.value = null;
  }
}
