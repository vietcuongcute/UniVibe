import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../models/vibe_signal.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/signal_service.dart';
import '../services/user_profile_service.dart';
import 'auth_gate.dart';
import 'chats_screen.dart';
import 'daily_match_screen.dart';
import 'daily_poll_screen.dart';
import 'signals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<UserProfile?> currentUserFuture;

  @override
  void initState() {
    super.initState();
    currentUserFuture = UserProfileService.getCurrentUserProfile();
  }

  void _goToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  int _getPendingReceivedSignalCount(List<VibeSignal> signals) {
    return signals.where((signal) => signal.status == 'pending').length;
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc muốn đăng xuất khỏi UniVibe không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  Future<void> _refreshHome() async {
    setState(() {
      currentUserFuture = UserProfileService.getCurrentUserProfile();
    });

    await currentUserFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: currentUserFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F3FF),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
            ),
          );
        }

        if (userSnapshot.hasError) {
          return _buildErrorScaffold(userSnapshot.error.toString());
        }

        final currentUser = userSnapshot.data;

        if (currentUser == null) {
          return _buildErrorScaffold('Không tìm thấy profile hiện tại');
        }

        return StreamBuilder<List<VibeSignal>>(
          stream: SignalService.receivedSignalsStream(currentUser.id),
          builder: (context, signalSnapshot) {
            final receivedSignals = signalSnapshot.data ?? [];
            final pendingSignalCount = _getPendingReceivedSignalCount(
              receivedSignals,
            );

            return StreamBuilder<List<FirestoreChatRoom>>(
              stream: ChatService.chatRoomsStream(currentUser.id),
              builder: (context, chatSnapshot) {
                final chatRooms = chatSnapshot.data ?? [];
                final chatCount = chatRooms.length;
                final totalNotificationCount = pendingSignalCount + chatCount;

                return Scaffold(
                  backgroundColor: const Color(0xFFF7F3FF),
                  body: SafeArea(
                    child: RefreshIndicator(
                      onRefresh: _refreshHome,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildHeader(
                              context: context,
                              totalNotificationCount: totalNotificationCount,
                            ),
                            const SizedBox(height: 18),
                            _buildTodayCard(
                              pendingSignalCount: pendingSignalCount,
                              chatCount: chatCount,
                            ),
                            const SizedBox(height: 18),
                            _buildFeatureSection(
                              context: context,
                              pendingSignalCount: pendingSignalCount,
                              chatCount: chatCount,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildErrorScaffold(String error) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      body: SafeArea(
        child: Center(
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
                    'Không tải được trang chủ',
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
                    onPressed: _refreshHome,
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
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required int totalNotificationCount,
  }) {
    final bool hasNotification = totalNotificationCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(
            context: context,
            hasNotification: hasNotification,
            totalNotificationCount: totalNotificationCount,
          ),
          const SizedBox(height: 28),
          const Text(
            'UniVibe',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tìm người cùng vibe trong đại học.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Kết nối an toàn bằng Mutual Signal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar({
    required BuildContext context,
    required bool hasNotification,
    required int totalNotificationCount,
  }) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          child: Text(
            'U',
            style: TextStyle(
              color: Color(0xFF6A11CB),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 2),
              Text(
                'Bạn hôm nay muốn vibe gì?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            _goToScreen(context, const SignalsScreen());
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                ),
              ),
              if (hasNotification)
                Positioned(
                  right: -4,
                  top: -5,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        totalNotificationCount > 9
                            ? '9+'
                            : totalNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            _logout(context);
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayCard({
    required int pendingSignalCount,
    required int chatCount,
  }) {
    String title = 'Daily Vibe';
    String subtitle =
        'Khám phá match, gửi signal, mở chat khi hai bên cùng đồng ý.';

    if (pendingSignalCount > 0) {
      title = 'Bạn có $pendingSignalCount signal mới';
      subtitle =
          'Có người đã gửi tín hiệu kết nối cho bạn. Vào Vibe Signals để signal lại nếu thấy hợp vibe.';
    } else if (chatCount > 0) {
      title = 'Bạn có $chatCount phòng chat';
      subtitle =
          'Các phòng chat được mở sau khi hai bên cùng gửi signal cho nhau.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
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
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: pendingSignalCount > 0
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFFFEEF6),
              child: Icon(
                pendingSignalCount > 0 ? Icons.bolt_rounded : Icons.favorite,
                color: pendingSignalCount > 0
                    ? const Color(0xFFFF9800)
                    : const Color(0xFFE91E63),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.35,
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

  Widget _buildFeatureSection({
    required BuildContext context,
    required int pendingSignalCount,
    required int chatCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chức năng chính',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _buildFeatureCard(
            context: context,
            title: 'Daily Match',
            subtitle: 'Xem những người hợp vibe với bạn hôm nay.',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF7B61FF),
            screen: const DailyMatchScreen(),
          ),
          _buildFeatureCard(
            context: context,
            title: 'Vibe Signals',
            subtitle: pendingSignalCount > 0
                ? 'Bạn có $pendingSignalCount signal đang chờ phản hồi.'
                : 'Xem signal đã nhận, đã gửi và signal lại.',
            icon: Icons.bolt_rounded,
            color: const Color(0xFFFF9800),
            screen: const SignalsScreen(),
            badgeCount: pendingSignalCount,
          ),
          _buildFeatureCard(
            context: context,
            title: 'Chats',
            subtitle: chatCount > 0
                ? 'Bạn đang có $chatCount phòng chat đã mutual signal.'
                : 'Trò chuyện với những người đã mutual signal.',
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF00A8CC),
            screen: const ChatsScreen(),
            badgeCount: chatCount,
          ),
          _buildFeatureCard(
            context: context,
            title: 'Daily Poll',
            subtitle:
                'Vote câu hỏi vui hằng ngày và xem vibe của sinh viên khác.',
            icon: Icons.poll_rounded,
            color: const Color(0xFFE91E63),
            screen: const DailyPollScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget screen,
    int badgeCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            _goToScreen(context, screen);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icon, color: color, size: 30),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -7,
                        top: -7,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              badgeCount > 9 ? '9+' : badgeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (badgeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                'Mới',
                                style: TextStyle(
                                  color: Color(0xFFFF3B30),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 17,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
