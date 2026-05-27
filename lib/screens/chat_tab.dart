import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentUserId.isEmpty) {
      return _buildLoginRequiredState();
    }

    return StreamBuilder<List<FirestoreChatRoom>>(
      stream: ChatService.chatRoomsStream(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final chatRooms = snapshot.data ?? [];

        if (chatRooms.isEmpty) {
          return _buildEmptyState();
        }

        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: chatRooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final room = chatRooms[index];

              return Dismissible(
                key: ValueKey(room.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 22),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            title: const Text(
                              'Xoá đoạn chat?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                              'Đoạn chat chỉ bị xoá khỏi danh sách của bạn. Người kia vẫn thấy bình thường.',
                              style: TextStyle(
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, false);
                                },
                                child: const Text('Huỷ'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(dialogContext, true);
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Xoá'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ) ??
                      false;
                },
                onDismissed: (_) async {
                  final messenger = ScaffoldMessenger.of(context);

                  final result = await ChatService.deleteChatRoomForCurrentUser(
                    room.id,
                  );

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(result),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Hoàn tác',
                        textColor: Colors.white,
                        onPressed: () async {
                          final restoreResult =
                              await ChatService.restoreChatRoomForCurrentUser(
                                room.id,
                              );

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(restoreResult),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(chatRoomId: room.id),
                      ),
                    );
                  },
                  child: _buildChatRoomCard(room),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoginRequiredState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 54),
                SizedBox(height: 14),
                Text(
                  'Bạn chưa đăng nhập',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Đăng nhập để xem danh sách chat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.grey.shade400,
                  size: 54,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chưa có phòng chat',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Khi hai bên mutual signal, phòng chat sẽ hiện ở đây.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 54,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Không tải được phòng chat',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatRoomCard(FirestoreChatRoom room) {
    final isBlindHidden = room.type == 'blind' && !room.isRevealed;

    final displayName = isBlindHidden
        ? 'Ẩn danh UniVibe'
        : room.otherName.isNotEmpty
        ? room.otherName
        : 'Người dùng UniVibe';

    final displayLastMessage = room.lastMessage.isNotEmpty
        ? room.lastMessage
        : isBlindHidden
        ? 'Blind chat đang ẩn danh'
        : 'Bắt đầu trò chuyện';

    final avatarLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFEDE7FF),
            backgroundImage: !isBlindHidden && room.otherAvatarUrl.isNotEmpty
                ? NetworkImage(room.otherAvatarUrl)
                : null,
            child: isBlindHidden
                ? const Icon(
                    Icons.visibility_off_rounded,
                    color: Color(0xFF7B61FF),
                    size: 24,
                  )
                : room.otherAvatarUrl.isEmpty
                ? Text(
                    avatarLetter,
                    style: const TextStyle(
                      color: Color(0xFF7B61FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayLastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}
