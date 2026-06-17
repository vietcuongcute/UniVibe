import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/report_service.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatDetailScreen({super.key, required this.chatRoomId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;

  String get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await ChatService.sendMessage(chatRoomId: widget.chatRoomId, text: text);

      _messageController.clear();

      await Future.delayed(const Duration(milliseconds: 150));

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi tin nhắn thất bại: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Bạn chưa đăng nhập.')),
      );
    }

    return StreamBuilder<FirestoreChatRoom?>(
      stream: ChatService.chatRoomStream(widget.chatRoomId),
      builder: (context, roomSnapshot) {
        final room = roomSnapshot.data;

        final isBlind = room?.type == 'blind';
        final isRevealed = room?.isRevealed == true;

        final displayName = isBlind && !isRevealed
            ? 'Ẩn danh UniVibe'
            : room?.otherName.isNotEmpty == true
            ? room!.otherName
            : 'Chat UniVibe';

        return Scaffold(
          backgroundColor: const Color(0xFFF7F3FF),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2D1B69),
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: const Color(0xFFEDE7FF),
                  backgroundImage: !isBlind || isRevealed
                      ? room?.otherAvatarUrl.isNotEmpty == true
                            ? NetworkImage(room!.otherAvatarUrl)
                            : null
                      : null,
                  child: isBlind && !isRevealed
                      ? const Icon(
                          Icons.visibility_off_rounded,
                          color: Color(0xFF7B61FF),
                        )
                      : room == null || room.otherAvatarUrl.isEmpty
                      ? Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF7B61FF),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Tùy chọn',
                onPressed: () {
                  _showChatOptionsBottomSheet(context, room);
                },
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),

          body: Column(
            children: [
              if (isBlind && !isRevealed && room != null)
                _buildRevealBanner(room),

              Expanded(
                child: StreamBuilder<List<FirestoreChatMessage>>(
                  stream: ChatService.messagesStream(widget.chatRoomId),
                  builder: (context, messageSnapshot) {
                    if (messageSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (messageSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Không tải được tin nhắn:\n${messageSnapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    }

                    final messages = messageSnapshot.data ?? [];

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Chưa có tin nhắn.\nHãy bắt đầu cuộc trò chuyện!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, height: 1.4),
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];

                        final isMe = message.senderId == _currentUserId;
                        final isSystem = message.senderId == 'system';

                        if (isSystem) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  message.text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.74,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF7B61FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 18),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  right: 4,
                                  bottom: 10,
                                ),
                                child: Text(
                                  _formatTime(message.createdAt),
                                  style: const TextStyle(
                                    color: Colors.black38,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildInputBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevealBanner(FirestoreChatRoom room) {
    final hasRequested = ChatService.hasRequestedReveal(room);
    final otherRequested = ChatService.otherUserRequestedReveal(room);

    final bool shouldShowOtherRequestNotice = otherRequested && !hasRequested;

    final String text = shouldShowOtherRequestNotice
        ? 'Người kia muốn reveal profile 👀 Nếu bạn đồng ý, bấm Reveal.'
        : hasRequested
        ? 'Đã gửi yêu cầu reveal. Chờ người kia đồng ý.'
        : 'Blind chat đang ẩn danh. Reveal nếu cả hai đồng ý.';

    final IconData icon = shouldShowOtherRequestNotice
        ? Icons.notifications_active_rounded
        : hasRequested
        ? Icons.hourglass_top_rounded
        : Icons.visibility_off_rounded;

    final Color mainColor = shouldShowOtherRequestNotice
        ? const Color(0xFFFF9800)
        : const Color(0xFFE91E63);

    final Color backgroundColor = shouldShowOtherRequestNotice
        ? const Color(0xFFFFF3E0)
        : Colors.white;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mainColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: mainColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2D1B69),
                fontWeight: FontWeight.w700,
                height: 1.3,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: hasRequested
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);

                    final result = await ChatService.requestRevealProfile(
                      widget.chatRoomId,
                    );

                    if (!mounted) return;

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(result),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(hasRequested ? 'Đã gửi' : 'Reveal'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  filled: true,
                  fillColor: const Color(0xFFF7F3FF),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _isSending
                      ? Colors.grey.shade300
                      : const Color(0xFF7B61FF),
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptionsBottomSheet(
    BuildContext context,
    FirestoreChatRoom? room,
  ) {
    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa tải được thông tin phòng chat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Container(
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
                        room.otherName.isNotEmpty
                            ? room.otherName[0].toUpperCase()
                            : 'U',
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildChatOptionTile(
                  icon: Icons.flag_rounded,
                  title: 'Report đoạn chat',
                  subtitle: 'Gửi báo cáo cho admin kiểm duyệt.',
                  color: const Color(0xFFFF9800),
                  backgroundColor: const Color(0xFFFFF3E0),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showReportChatDialog(context, room);
                  },
                ),
                const SizedBox(height: 10),
                _buildChatOptionTile(
                  icon: Icons.block_rounded,
                  title: 'Chặn người này',
                  subtitle: 'Ẩn đoạn chat và chặn tương tác với người này.',
                  color: const Color(0xFFE53935),
                  backgroundColor: const Color(0xFFFFEBEE),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showBlockUserConfirmDialog(context, room);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: backgroundColor,
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

  void _showReportChatDialog(BuildContext context, FirestoreChatRoom room) {
    final detailController = TextEditingController();
    String selectedReason = 'Tin nhắn không phù hợp';

    final reasons = [
      'Tin nhắn không phù hợp',
      'Quấy rối/làm phiền',
      'Spam hoặc lừa đảo',
      'Giả mạo danh tính',
      'Lý do khác',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Report đoạn chat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bạn đang report đoạn chat với ${room.otherName}. Admin sẽ kiểm tra nội dung này.',
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      items: reasons.map((reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedReason = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Lý do report',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Mô tả thêm',
                        hintText: 'Nhập chi tiết để admin dễ kiểm tra...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    detailController.dispose();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(dialogContext);

                    final result = await ReportService.createReport(
                      targetType: 'chat',
                      targetId: room.id,
                      targetOwnerId: room.otherUserId,
                      reason: selectedReason,
                      detail: detailController.text.trim(),
                    );

                    detailController.dispose();
                    navigator.pop();

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(result),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Gửi report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBlockUserConfirmDialog(
    BuildContext context,
    FirestoreChatRoom room,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Chặn người này?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Bạn có chắc muốn chặn ${room.otherName}? Đoạn chat này sẽ được ẩn khỏi danh sách của bạn.',
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _blockUserFromChat(context, room);
              },
              icon: const Icon(Icons.block_rounded),
              label: const Text('Chặn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockUserFromChat(
    BuildContext context,
    FirestoreChatRoom room,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Bạn cần đăng nhập để chặn người dùng.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();
      final blockId = '${currentUser.uid}_${room.otherUserId}';

      final batch = db.batch();

      final blockRef = db.collection('blocks').doc(blockId);
      batch.set(blockRef, {
        'id': blockId,
        'blockerId': currentUser.uid,
        'blockedUserId': room.otherUserId,
        'blockedUserName': room.otherName,
        'chatRoomId': room.id,
        'status': 'active',
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      final chatRoomRef = db.collection('chatRooms').doc(room.id);
      batch.set(chatRoomRef, {
        'blockedBy': FieldValue.arrayUnion([currentUser.uid]),
        'blockedPairs': FieldValue.arrayUnion([blockId]),
        'updatedAt': now,
      }, SetOptions(merge: true));

      await batch.commit();

      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã chặn ${room.otherName}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Chặn thất bại: ${e.message ?? e.code}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Chặn thất bại: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
