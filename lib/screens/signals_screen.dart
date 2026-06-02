import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../models/vibe_signal.dart';
import '../services/signal_service.dart';
import '../services/user_profile_service.dart';
import 'chat_detail_screen.dart';

class SignalsScreen extends StatefulWidget {
  const SignalsScreen({super.key});

  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> {
  late Future<UserProfile?> currentUserFuture;

  @override
  void initState() {
    super.initState();
    currentUserFuture = UserProfileService.getCurrentUserProfile();
  }

  Future<void> refreshSignals() async {
    setState(() {
      currentUserFuture = UserProfileService.getCurrentUserProfile();
    });

    await currentUserFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: currentUserFuture,
      builder: (context, snapshot) {
        final currentUser = snapshot.data;

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
                    child: _buildMainContent(
                      snapshot: snapshot,
                      currentUser: currentUser,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent({
    required AsyncSnapshot<UserProfile?> snapshot,
    required UserProfile? currentUser,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
      );
    }

    if (snapshot.hasError) {
      return _buildErrorState(snapshot.error.toString());
    }

    if (currentUser == null) {
      return _buildErrorState('Không tìm thấy profile hiện tại');
    }

    return TabBarView(
      children: [
        _buildReceivedSignalsTab(currentUser),
        _buildSentSignalsTab(currentUser),
      ],
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
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: refreshSignals,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
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

  Widget _buildReceivedSignalsTab(UserProfile currentUser) {
    return StreamBuilder<List<VibeSignal>>(
      stream: SignalService.receivedSignalsStream(currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final signals = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: refreshSignals,
          child: signals.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    _buildEmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'Chưa có signal đã nhận',
                      subtitle:
                          'Khi có người thấy bạn hợp vibe và gửi signal, tín hiệu sẽ xuất hiện ở đây.',
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                          _openChatFromSignal(context: context, signal: signal);
                          return;
                        }

                        _showSignalBackDialog(
                          context: context,
                          currentUser: currentUser,
                          signal: signal,
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildSentSignalsTab(UserProfile currentUser) {
    return StreamBuilder<List<VibeSignal>>(
      stream: SignalService.sentSignalsStream(currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final signals = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: refreshSignals,
          child: signals.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    _buildEmptyState(
                      icon: Icons.send_rounded,
                      title: 'Chưa gửi signal nào',
                      subtitle:
                          'Hãy vào Daily Match để gửi tín hiệu nhẹ cho người bạn thấy hợp vibe.',
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                                signal: signal,
                              );
                            }
                          : null,
                    );
                  },
                ),
        );
      },
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
    final bool isPending = signal.status == 'pending';

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
                  titleName.isEmpty ? 'Người dùng UniVibe' : titleName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  signal.message.isEmpty
                      ? 'Đã gửi một vibe signal.'
                      : signal.message,
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
                if (isReceived && isPending)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onPrimaryAction,
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('Signal lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  )
                else if (isMutual)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onPrimaryAction,
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      label: const Text('Mở chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  )
                else if (!isReceived && isPending)
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
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _getStatusText(signal.status),
                      style: TextStyle(
                        color: Colors.grey.shade700,
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
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
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
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
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
    required UserProfile currentUser,
    required VibeSignal signal,
  }) {
    final messageController = TextEditingController(
      text: 'Mình cũng thấy bạn hợp vibe, kết nối nhé!',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSending = false;

        return StatefulBuilder(
          builder: (innerContext, setDialogState) {
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
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFFF9800),
                    ),
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
                      style: const TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      enabled: !isSending,
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
                  onPressed: isSending
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: isSending
                      ? null
                      : () async {
                          setDialogState(() {
                            isSending = true;
                          });

                          try {
                            final senderProfile = await _getUserProfileById(
                              signal.senderId,
                              fallbackName: signal.senderName,
                            );

                            final result = await SignalService.signalBack(
                              currentUser: currentUser,
                              sender: senderProfile,
                              message: messageController.text.trim().isEmpty
                                  ? 'Mình cũng thấy bạn hợp vibe, kết nối nhé!'
                                  : messageController.text.trim(),
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );

                            setState(() {});
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              isSending = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Signal lại thất bại: $e'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(isSending ? 'Đang gửi...' : 'Signal lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
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

  Future<UserProfile> _getUserProfileById(
    String userId, {
    required String fallbackName,
  }) async {
    final users = await UserProfileService.getAllUsers();

    for (final user in users) {
      if (user.id == userId) {
        return user;
      }
    }

    return UserProfile(
      id: userId,
      nickname: fallbackName.isEmpty ? 'Người dùng UniVibe' : fallbackName,
      avatarUrl: '',
      coverUrl: '',
      university: '',
      major: '',
      year: 1,
      gender: '',
      interests: const [],
      goals: const [],
      vibeTags: const [],
      featuredImageUrls: const [],
      bio: '',
    );
  }

  void _openChatFromSignal({
    required BuildContext context,
    required VibeSignal signal,
  }) {
    final chatRoomId =
        signal.chatRoomId ??
        SignalService.chatRoomIdFor(signal.senderId, signal.receiverId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chatRoomId: chatRoomId),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Padding(
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 42,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Không tải được signals',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: refreshSignals,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    if (status == 'pending') {
      return 'Đang chờ';
    } else if (status == 'mutual') {
      return 'Mutual';
    } else if (status == 'accepted') {
      return 'Đã đồng ý';
    } else if (status == 'declined') {
      return 'Đã từ chối';
    } else {
      return status;
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'pending') {
      return const Color(0xFFFF9800);
    } else if (status == 'mutual') {
      return const Color(0xFF4CAF50);
    } else if (status == 'accepted') {
      return const Color(0xFF4CAF50);
    } else if (status == 'declined') {
      return const Color(0xFFE53935);
    } else {
      return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    }

    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');

    return '$day/$month';
  }
}
