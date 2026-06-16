import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../services/block_service.dart';
import '../services/chat_service.dart';
import '../services/report_service.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  static const Color _primary = Color(0xFF7B61FF);
  static const Color _danger = Color(0xFFE53935);
  static const Color _warning = Color(0xFFFF9800);
  static const Color _darkText = Color(0xFF2D1B69);

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
                      child: CircularProgressIndicator(color: _primary),
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
          extentRatio: 0.52,
          children: [
            CustomSlidableAction(
              borderRadius: BorderRadius.circular(24),
              backgroundColor: _warning,
              foregroundColor: Colors.white,
              onPressed: (_) {
                _showReportDialog(context, room);
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_rounded, color: Colors.white, size: 26),
                  SizedBox(height: 4),
                  Text(
                    'Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            CustomSlidableAction(
              borderRadius: BorderRadius.circular(24),
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              onPressed: (_) {
                _showDeleteConfirmDialog(context, room);
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white, size: 26),
                  SizedBox(height: 4),
                  Text(
                    'Xoá',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
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
                    backgroundColor: _primary,
                    backgroundImage: room.otherAvatarUrl.isNotEmpty
                        ? NetworkImage(room.otherAvatarUrl)
                        : null,
                    child: room.otherAvatarUrl.isEmpty
                        ? Text(
                            avatarLetter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      backgroundColor: _primary,
                      backgroundImage: room.otherAvatarUrl.isNotEmpty
                          ? NetworkImage(room.otherAvatarUrl)
                          : null,
                      child: room.otherAvatarUrl.isEmpty
                          ? Text(
                              avatarLetter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
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
                _buildOptionTile(
                  icon: Icons.flag_rounded,
                  title: 'Report đoạn chat',
                  subtitle: 'Gửi báo cáo cho admin kiểm duyệt.',
                  backgroundColor: const Color(0xFFFFF3E0),
                  iconColor: _warning,
                  textColor: _warning,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showReportDialog(context, room);
                  },
                ),
                const SizedBox(height: 10),
                _buildOptionTile(
                  icon: Icons.block_rounded,
                  title: 'Chặn người này',
                  subtitle: 'Ẩn người này khỏi danh sách chat của bạn.',
                  backgroundColor: const Color(0xFFFFEBEE),
                  iconColor: _danger,
                  textColor: _danger,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showBlockConfirmDialog(context, room);
                  },
                ),
                const SizedBox(height: 10),
                _buildOptionTile(
                  icon: Icons.delete_rounded,
                  title: 'Xoá đoạn chat',
                  subtitle: 'Ẩn đoạn chat này khỏi danh sách của bạn.',
                  backgroundColor: const Color(0xFFFFEBEE),
                  iconColor: _danger,
                  textColor: _danger,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showDeleteConfirmDialog(context, room);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.62),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: iconColor.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                ),
                child: Icon(icon, color: iconColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
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

  void _showReportDialog(BuildContext context, FirestoreChatRoom room) {
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
                      'Bạn đang report đoạn chat với ${room.otherName}. Admin sẽ xem xét nội dung này.',
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

                    try {
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
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Report thất bại: $e'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Gửi report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
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

  void _showBlockConfirmDialog(BuildContext context, FirestoreChatRoom room) {
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
                  color: _danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.block_rounded, color: _danger),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Chặn người này?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Bạn có chắc muốn chặn ${room.otherName}? Người này sẽ bị ẩn khỏi danh sách chat của bạn.',
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
                await _blockUser(context, room);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Chặn'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockUser(BuildContext context, FirestoreChatRoom room) async {
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

    if (room.otherUserId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy người cần chặn.'),
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

      BlockService.blockedUserIdsNotifier.value = [
        room.otherUserId,
        ...BlockService.blockedUserIds.where(
          (blockedUserId) => blockedUserId != room.otherUserId,
        ),
      ];

      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã chặn ${room.otherName}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                  color: _danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.delete_rounded, color: _danger),
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
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xoá'),
            ),
          ],
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
