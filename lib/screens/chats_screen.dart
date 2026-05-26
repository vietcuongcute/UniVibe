import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../services/block_service.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  List<FirestoreChatRoom> _getVisibleChatRooms(List<FirestoreChatRoom> rooms) {
    return rooms.where((room) {
      return !BlockService.isBlocked(room.otherUserId);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<List<FirestoreChatRoom>>(
                stream: ChatService.chatRoomsStream(currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7B61FF),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  final rooms = snapshot.data ?? [];
                  final visibleRooms = _getVisibleChatRooms(rooms);

                  if (visibleRooms.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    itemCount: visibleRooms.length,
                    itemBuilder: (context, index) {
                      final room = visibleRooms[index];
                      return _buildSlidableChatRoomCard(context, room);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Chats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Phòng chat của bạn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chat realtime sau khi hai bên mutual signal.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidableChatRoomCard(
    BuildContext context,
    FirestoreChatRoom room,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Slidable(
        key: ValueKey(room.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.26,
          children: [
            CustomSlidableAction(
              borderRadius: BorderRadius.circular(24),
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              onPressed: (_) {
                _showDeleteConfirmDialog(context, room);
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Xoá',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        child: _buildChatRoomCard(context, room),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, FirestoreChatRoom room) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Xoá đoạn chat?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Bạn có chắc muốn xoá đoạn chat với ${room.otherName}? Tin nhắn vẫn còn trong Firestore, chỉ ẩn khỏi danh sách của bạn.',
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Xoá'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatRoomCard(BuildContext context, FirestoreChatRoom room) {
    final avatarLetter = room.otherName.isNotEmpty
        ? room.otherName[0].toUpperCase()
        : 'U';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(chatRoomId: room.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF7B61FF),
                    child: Text(
                      avatarLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.otherName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      room.lastMessage.isEmpty
                          ? 'Bắt đầu trò chuyện nào.'
                          : room.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(room.updatedAt),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () {
                      _showChatOptionsBottomSheet(context, room);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
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

  void _showChatOptionsBottomSheet(
    BuildContext context,
    FirestoreChatRoom room,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final avatarLetter = room.otherName.isNotEmpty
            ? room.otherName[0].toUpperCase()
            : 'U';

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF7B61FF),
                    child: Text(
                      avatarLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      room.otherName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showDeleteConfirmDialog(context, room);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE53935).withOpacity(0.16),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                          child: Icon(
                            Icons.delete_rounded,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xoá đoạn chat',
                              style: TextStyle(
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Ẩn đoạn chat này khỏi danh sách của bạn.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A8CC).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 42,
                  color: Color(0xFF00A8CC),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Chưa có phòng chat',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khi hai bên cùng gửi signal, phòng chat sẽ tự động xuất hiện ở đây.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'Không tải được danh sách chat:\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, height: 1.4),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
