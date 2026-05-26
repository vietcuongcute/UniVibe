import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/block_service.dart';
import '../services/chat_service.dart';
import '../services/report_service.dart';
import '../services/user_profile_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatDetailScreen({super.key, required this.chatRoomId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool isSending = false;

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() {
      isSending = true;
    });

    try {
      await ChatService.sendMessage(chatRoomId: widget.chatRoomId, text: text);

      messageController.clear();

      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted || !scrollController.hasClients) return;
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không gửi được tin nhắn: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FirestoreChatRoom?>(
      stream: ChatService.chatRoomStream(widget.chatRoomId),
      builder: (context, roomSnapshot) {
        if (roomSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F3FF),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
            ),
          );
        }

        if (roomSnapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F3FF),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không tải được phòng chat:\n${roomSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final room = roomSnapshot.data;
        if (room == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F3FF),
            body: Center(child: Text('Không tìm thấy phòng chat.')),
          );
        }

        final isBlocked = BlockService.isBlocked(room.otherUserId);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F3FF),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, room),
                Expanded(
                  child: StreamBuilder<List<FirestoreChatMessage>>(
                    stream: ChatService.messagesStream(widget.chatRoomId),
                    builder: (context, messageSnapshot) {
                      if (messageSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7B61FF),
                          ),
                        );
                      }

                      if (messageSnapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Không tải được tin nhắn:\n${messageSnapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final messages = messageSnapshot.data ?? [];

                      if (messages.isEmpty) {
                        return _buildEmptyMessages();
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageBubble(message);
                        },
                      );
                    },
                  ),
                ),
                if (isBlocked) _buildBlockedBar(room) else _buildInputBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, FirestoreChatRoom room) {
    final avatarLetter = room.otherName.isNotEmpty
        ? room.otherName[0].toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              avatarLetter,
              style: const TextStyle(
                color: Color(0xFF6A11CB),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.otherName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  room.otherMajor.isEmpty
                      ? 'Đã mutual signal'
                      : '${room.otherMajor} · Năm ${room.otherYear}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              _showChatSafetyBottomSheet(
                context: context,
                user: room.otherUser,
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(FirestoreChatMessage message) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isMe = message.senderId == currentUserId;
    final bool isSystem = message.senderId == 'system';

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.purple.withOpacity(0.12)),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF7B61FF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 5),
            bottomRight: Radius.circular(isMe ? 5 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                sendMessage();
              },
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                filled: true,
                fillColor: const Color(0xFFF7F3FF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isSending ? null : sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedBar(FirestoreChatRoom room) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Text(
        'Bạn đã block ${room.otherName}. Không thể gửi tin nhắn.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFE53935),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Chưa có tin nhắn nào.\nHãy bắt đầu cuộc trò chuyện.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
      ),
    );
  }

  void _showChatSafetyBottomSheet({
    required BuildContext context,
    required UserProfile user,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final avatarLetter = user.nickname.isNotEmpty
            ? user.nickname[0].toUpperCase()
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
                      user.nickname,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSafetyAction(
                icon: Icons.flag_rounded,
                color: const Color(0xFFFF9800),
                title: 'Report user',
                subtitle: 'Báo cáo tin nhắn hoặc hành vi không phù hợp.',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showReportDialog(context: context, user: user);
                },
              ),
              const SizedBox(height: 12),
              _buildSafetyAction(
                icon: Icons.block_rounded,
                color: const Color(0xFFE53935),
                title: 'Block user',
                subtitle: 'Chặn người này và ẩn khỏi Daily Match.',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showBlockConfirmDialog(context: context, user: user);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSafetyAction({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
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
    );
  }

  void _showReportDialog({
    required BuildContext context,
    required UserProfile user,
  }) {
    String selectedReason = 'Tin nhắn không phù hợp';
    final detailController = TextEditingController();

    final List<String> reasons = [
      'Tin nhắn không phù hợp',
      'Làm phiền',
      'Giả mạo danh tính',
      'Nội dung phản cảm',
      'Hành vi không an toàn',
      'Khác',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text('Report user'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn muốn báo cáo ${user.nickname} vì lý do gì?',
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      decoration: InputDecoration(
                        labelText: 'Lý do',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: reasons.map((reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedReason = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: detailController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Mô tả thêm',
                        hintText: 'Nhập thêm chi tiết nếu cần...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
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
                    final currentUser =
                        await UserProfileService.getCurrentUserProfile();

                    if (!context.mounted) return;

                    if (currentUser == null) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Không tìm thấy profile hiện tại.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final result = ReportService.reportUser(
                      currentUser: currentUser,
                      targetUser: user,
                      reason: selectedReason,
                      detail: detailController.text.trim(),
                    );

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Gửi report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBlockConfirmDialog({
    required BuildContext context,
    required UserProfile user,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Block user'),
          content: Text(
            'Bạn có chắc muốn block ${user.nickname}? Người này sẽ bị ẩn khỏi Daily Match và bạn không thể gửi tin nhắn.',
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
              onPressed: () {
                final result = BlockService.blockUser(user);
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
