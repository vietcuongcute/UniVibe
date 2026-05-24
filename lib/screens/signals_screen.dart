import 'package:flutter/material.dart';

import '../data/mock_users.dart';
import '../models/chat_room.dart';
import '../models/vibe_signal.dart';
import '../services/chat_service.dart';
import '../services/signal_service.dart';
import 'chat_detail_screen.dart';

class SignalsScreen extends StatelessWidget {
  const SignalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F3FF),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const TabBar(
                labelColor: Color(0xFF7B61FF),
                unselectedLabelColor: Colors.black45,
                indicatorColor: Color(0xFF7B61FF),
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Đã nhận'),
                  Tab(text: 'Đã gửi'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildReceivedSignalsTab(context),
                    _buildSentSignalsTab(context),
                  ],
                ),
              ),
            ],
          ),
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
                  'Vibe Signals',
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
                child: const Icon(Icons.bolt_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Tín hiệu kết nối',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hai bên cùng signal thì UniVibe sẽ mở phòng chat.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Text(
              'Giới hạn ${SignalService.dailySignalLimit} signal mỗi ngày',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedSignalsTab(BuildContext context) {
    return ValueListenableBuilder<List<VibeSignal>>(
      valueListenable: SignalService.receivedSignalsNotifier,
      builder: (context, signals, child) {
        if (signals.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox_rounded,
            title: 'Chưa có signal đã nhận',
            subtitle:
                'Khi có người thấy bạn hợp vibe và gửi signal, tín hiệu sẽ xuất hiện ở đây.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          itemCount: signals.length,
          itemBuilder: (context, index) {
            final signal = signals[index];

            return _buildSignalCard(
              context: context,
              signal: signal,
              titleName: signal.senderName,
              isReceived: true,
              onPrimaryAction: () {
                if (signal.status == 'mutual') {
                  _openChatFromSignal(
                    context: context,
                    otherUserId: signal.senderId,
                  );

                  return;
                }

                _showSignalBackDialog(context: context, signal: signal);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSentSignalsTab(BuildContext context) {
    return ValueListenableBuilder<List<VibeSignal>>(
      valueListenable: SignalService.sentSignalsNotifier,
      builder: (context, signals, child) {
        if (signals.isEmpty) {
          return _buildEmptyState(
            icon: Icons.send_rounded,
            title: 'Chưa gửi signal nào',
            subtitle:
                'Hãy vào Daily Match để gửi tín hiệu nhẹ cho người bạn thấy hợp vibe.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          itemCount: signals.length,
          itemBuilder: (context, index) {
            final signal = signals[index];

            return _buildSignalCard(
              context: context,
              signal: signal,
              titleName: signal.receiverName,
              isReceived: false,
              onPrimaryAction: signal.status == 'mutual'
                  ? () {
                      _openChatFromSignal(
                        context: context,
                        otherUserId: signal.receiverId,
                      );
                    }
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: const Color(0xFFFF9800), size: 40),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
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

  Widget _buildSignalCard({
    required BuildContext context,
    required VibeSignal signal,
    required String titleName,
    required bool isReceived,
    required VoidCallback? onPrimaryAction,
  }) {
    final Color statusColor = _getStatusColor(signal.status);
    final bool isMutual = signal.status == 'mutual';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: isMutual
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
                child: Text(
                  titleName.isNotEmpty ? titleName[0].toUpperCase() : '?',
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
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: statusColor,
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
                  titleName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  signal.message,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildStatusChip(signal.status),
                    _buildTimeChip(signal.createdAt),
                  ],
                ),
                const SizedBox(height: 14),
                if (isReceived || isMutual)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onPrimaryAction,
                      icon: Icon(
                        isMutual
                            ? Icons.chat_bubble_rounded
                            : Icons.bolt_rounded,
                        size: 18,
                      ),
                      label: Text(isMutual ? 'Mở chat' : 'Signal lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMutual
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFFF9800).withOpacity(0.18),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          size: 18,
                          color: Color(0xFFFF9800),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đang chờ người kia signal lại',
                            style: TextStyle(
                              color: Color(0xFFFF9800),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final String text = _getStatusText(status);
    final Color color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimeChip(DateTime time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(time),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showSignalBackDialog({
    required BuildContext context,
    required VibeSignal signal,
  }) {
    final messageController = TextEditingController(
      text: 'Mình cũng thấy bạn hợp vibe, kết nối nhé!',
    );

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
                  color: const Color(0xFFFF9800).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFFFF9800)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Signal lại',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gửi signal lại cho ${signal.senderName}. Sau khi mutual signal, phòng chat sẽ được mở.',
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Lời nhắn',
                    filled: true,
                    fillColor: const Color(0xFFF7F3FF),
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
                Navigator.pop(dialogContext);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final result = SignalService.signalBack(
                  currentUser: currentUser,
                  senderId: signal.senderId,
                  message: messageController.text.trim().isEmpty
                      ? 'Mình cũng thấy bạn hợp vibe, kết nối nhé!'
                      : messageController.text.trim(),
                );

                Navigator.pop(dialogContext);

                final chatRoom = ChatService.getChatRoomWith(signal.senderId);

                if (chatRoom != null) {
                  _showMutualSuccessDialog(
                    context: context,
                    userName: signal.senderName,
                    chatRoom: chatRoom,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Signal lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMutualSuccessDialog({
    required BuildContext context,
    required String userName,
    required ChatRoom chatRoom,
  }) {
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mutual Signal!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Bạn và $userName đã cùng gửi signal cho nhau. Phòng chat đã được mở.',
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Để sau'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatDetailScreen(chatRoomId: chatRoom.id),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text('Mở chat ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _openChatFromSignal({
    required BuildContext context,
    required String otherUserId,
  }) {
    final chatRoom = ChatService.getChatRoomWith(otherUserId);

    if (chatRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa tìm thấy phòng chat. Hãy thử lại sau.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chatRoomId: chatRoom.id),
      ),
    );
  }

  String _getStatusText(String status) {
    if (status == 'pending') {
      return 'Đang chờ';
    } else if (status == 'mutual') {
      return 'Mutual';
    } else if (status == 'accepted') {
      return 'Đã đồng ý';
    } else {
      return 'Đã từ chối';
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'pending') {
      return const Color(0xFFFF9800);
    } else if (status == 'mutual') {
      return const Color(0xFF4CAF50);
    } else if (status == 'accepted') {
      return const Color(0xFF4CAF50);
    } else {
      return const Color(0xFFE53935);
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
