import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/user_profile.dart';

class ChatService {
  static final ValueNotifier<List<ChatRoom>> chatRoomsNotifier =
      ValueNotifier<List<ChatRoom>>([]);

  static List<ChatRoom> get chatRooms => chatRoomsNotifier.value;

  static bool hasChatRoomWith(String userId) {
    return chatRooms.any((room) => room.otherUser.id == userId);
  }

  static ChatRoom? getChatRoomWith(String userId) {
    try {
      return chatRooms.firstWhere((room) => room.otherUser.id == userId);
    } catch (_) {
      return null;
    }
  }

  static ChatRoom createChatRoom({
    required UserProfile currentUser,
    required UserProfile otherUser,
  }) {
    final existedRoom = getChatRoomWith(otherUser.id);

    if (existedRoom != null) {
      return existedRoom;
    }

    final now = DateTime.now();
    final roomId =
        'chat_${currentUser.id}_${otherUser.id}_${now.millisecondsSinceEpoch}';

    final welcomeMessage = ChatMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      chatId: roomId,
      senderId: 'system',
      text:
          'Hai bạn đã mutual signal 🎉 Bây giờ có thể trò chuyện với nhau rồi!',
      createdAt: now,
    );

    final newRoom = ChatRoom(
      id: roomId,
      userIds: [currentUser.id, otherUser.id],
      otherUser: otherUser,
      lastMessage: welcomeMessage.text,
      createdAt: now,
      updatedAt: now,
      messages: [welcomeMessage],
    );

    chatRoomsNotifier.value = [newRoom, ...chatRoomsNotifier.value];

    return newRoom;
  }

  static ChatRoom? getChatRoomById(String chatRoomId) {
    try {
      return chatRooms.firstWhere((room) => room.id == chatRoomId);
    } catch (_) {
      return null;
    }
  }

  static void sendMessage({
    required String chatRoomId,
    required String senderId,
    required String text,
  }) {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      return;
    }

    final roomIndex = chatRooms.indexWhere((room) => room.id == chatRoomId);

    if (roomIndex == -1) {
      return;
    }

    final currentRoom = chatRooms[roomIndex];
    final now = DateTime.now();

    final newMessage = ChatMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      chatId: chatRoomId,
      senderId: senderId,
      text: trimmedText,
      createdAt: now,
    );

    final updatedRoom = currentRoom.copyWith(
      messages: [...currentRoom.messages, newMessage],
      lastMessage: trimmedText,
      updatedAt: now,
    );

    final updatedRooms = [...chatRooms];
    updatedRooms[roomIndex] = updatedRoom;

    updatedRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    chatRoomsNotifier.value = updatedRooms;
  }

  static String hideChatRoom(ChatRoom room) {
    final updatedRooms = chatRooms.where((chatRoom) {
      return chatRoom.id != room.id;
    }).toList();

    chatRoomsNotifier.value = updatedRooms;

    return 'Đã ẩn đoạn chat với ${room.otherUser.nickname}.';
  }

  static String deleteChatRoom(ChatRoom room) {
    final updatedRooms = chatRooms.where((chatRoom) {
      return chatRoom.id != room.id;
    }).toList();

    chatRoomsNotifier.value = updatedRooms;

    return 'Đã xoá đoạn chat với ${room.otherUser.nickname}.';
  }

  static String restoreChatRoom(ChatRoom room) {
    if (chatRooms.any((chatRoom) => chatRoom.id == room.id)) {
      return 'Đoạn chat đã tồn tại.';
    }

    final updatedRooms = [room, ...chatRooms];

    updatedRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    chatRoomsNotifier.value = updatedRooms;

    return 'Đã khôi phục đoạn chat với ${room.otherUser.nickname}.';
  }

  static void clearChats() {
    chatRoomsNotifier.value = [];
  }
}
