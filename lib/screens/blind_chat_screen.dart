import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_users.dart';
import '../models/blind_chat.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/blind_chat_service.dart';

class BlindChatScreen extends StatefulWidget {
  final UserProfile? otherUser;

  const BlindChatScreen({super.key, this.otherUser});

  @override
  State<BlindChatScreen> createState() => _BlindChatScreenState();
}

class _BlindChatScreenState extends State<BlindChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  Timer? _timer;
  Duration _timeLeft = const Duration(minutes: 10);

  @override
  void initState() {
    super.initState();

    final selectedUser = widget.otherUser ?? mockUsers.first;

    if (BlindChatService.activeBlindChatNotifier.value == null) {
      BlindChatService.createBlindChat(
        currentUser: currentUser,
        otherUser: selectedUser,
      );
    }

    _updateTimeLeft();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft();
      BlindChatService.expireChatIfNeeded();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeLeft() {
    final chat = BlindChatService.activeBlindChatNotifier.value;

    if (chat == null) {
      return;
    }

    final difference = chat.expiresAt.difference(DateTime.now());

    setState(() {
      if (difference.isNegative) {
        _timeLeft = Duration.zero;
      } else {
        _timeLeft = difference;
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    BlindChatService.sendMessage(text);
    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 600), () {
      BlindChatService.sendMockReply();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BlindChat?>(
      valueListenable: BlindChatService.activeBlindChatNotifier,
      builder: (context, chat, child) {
        if (chat == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F3FF),
            body: SafeArea(
              child: Column(
                children: [
                  _buildEmptyHeader(context),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Chưa có blind chat nào.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F3FF),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, chat),
                _buildInfoBanner(chat),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final message = chat.messages[index];

                      return _buildMessageBubble(
                        message: message,
                        currentUserId: chat.currentUser.id,
                      );
                    },
                  ),
                ),
                _buildRevealSection(chat),
                _buildMessageInput(chat),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyHeader(BuildContext context) {
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
      child: Row(
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
              'Blind Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BlindChat chat) {
    final String title = _buildTitle(chat);
    final bool revealed = chat.status == 'revealed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {
                  BlindChatService.endChat();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Icon(
                  revealed
                      ? Icons.person_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      revealed ? chat.otherUser.nickname : 'Ẩn danh cùng vibe',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      revealed
                          ? '${chat.otherUser.major} · ${chat.otherUser.university}'
                          : 'Chat 10 phút, chỉ reveal khi cả hai đồng ý.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildTitle(BlindChat chat) {
    if (chat.status == 'revealed') {
      return chat.otherUser.nickname;
    }

    if (chat.status == 'expired') {
      return 'Blind Chat đã hết hạn';
    }

    return 'Blind Chat';
  }

  Widget _buildInfoBanner(BlindChat chat) {
    final minutes = _timeLeft.inMinutes.toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    String text;
    IconData icon;
    Color color;

    if (chat.status == 'revealed') {
      text = 'Hai bạn đã đồng ý reveal profile.';
      icon = Icons.verified_rounded;
      color = const Color(0xFF4CAF50);
    } else if (chat.status == 'expired') {
      text = 'Blind chat đã hết hạn.';
      icon = Icons.timer_off_rounded;
      color = const Color(0xFFE53935);
    } else {
      text = 'Còn $minutes:$seconds để trò chuyện ẩn danh.';
      icon = Icons.timer_rounded;
      color = const Color(0xFFFF9800);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required ChatMessage message,
    required String currentUserId,
  }) {
    final isSystem = message.senderId == 'system';
    final isMe = message.senderId == currentUserId;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                )
              : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.06),
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
    );
  }

  Widget _buildRevealSection(BlindChat chat) {
    if (chat.status == 'expired') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              BlindChatService.endChat();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded),
            label: const Text('Kết thúc chat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
              side: const BorderSide(color: Color(0xFFE53935)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      );
    }

    if (chat.status == 'revealed') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.18)),
        ),
        child: Text(
          'Profile đã mở: ${chat.otherUser.nickname} · ${chat.otherUser.major} · ${chat.otherUser.university}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    if (chat.currentUserWantsReveal) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800).withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.18)),
        ),
        child: Column(
          children: [
            const Text(
              'Bạn đã yêu cầu reveal profile. Đang chờ người kia đồng ý.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFE65100),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                BlindChatService.mockOtherUserAcceptReveal();
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Giả lập người kia đồng ý'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF9800),
                side: const BorderSide(color: Color(0xFFFF9800)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            BlindChatService.requestReveal();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã gửi yêu cầu reveal profile.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.visibility_rounded),
          label: const Text('Reveal profile nếu cả hai đồng ý'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF7B61FF),
            side: const BorderSide(color: Color(0xFF7B61FF), width: 1.4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BlindChat chat) {
    if (chat.status == 'expired') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
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
              onSubmitted: (_) {
                _sendMessage();
              },
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
