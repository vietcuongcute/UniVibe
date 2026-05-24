import 'package:flutter/material.dart';

import '../data/mock_users.dart';
import '../models/user_profile.dart';
import '../services/block_service.dart';
import '../services/hidden_match_service.dart';
import '../services/match_service.dart';
import '../services/signal_service.dart';

class DailyMatchScreen extends StatefulWidget {
  const DailyMatchScreen({super.key});

  @override
  State<DailyMatchScreen> createState() => _DailyMatchScreenState();
}

class _DailyMatchScreenState extends State<DailyMatchScreen> {
  List<MatchResult> getDailyMatches() {
    return generateDailyMatches(
      currentUser: currentUser,
      users: mockUsers,
    ).where((match) {
      final userId = match.user.id;

      return !BlockService.isBlocked(userId) &&
          !HiddenMatchService.isHidden(userId);
    }).toList();
  }

  void refreshMatches() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<MatchResult> dailyMatches = getDailyMatches();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, dailyMatches.length),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: dailyMatches.isEmpty
                    ? _buildEmptyMatches()
                    : ListView.builder(
                        key: ValueKey(dailyMatches.length),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        itemCount: dailyMatches.length,
                        itemBuilder: (context, index) {
                          final match = dailyMatches[index];
                          final user = match.user;

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 350 + index * 80),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 24 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildMatchCard(
                              context: context,
                              user: user,
                              match: match,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int matchCount) {
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
                  'Daily Match',
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
                  Icons.favorite_border_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Người hợp vibe hôm nay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gửi signal trước. Chỉ khi hai bên cùng signal thì mới mở chat.',
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '$matchCount match khả dụng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard({
    required BuildContext context,
    required UserProfile user,
    required MatchResult match,
  }) {
    final bool hasSentSignal = SignalService.hasSentSignalTo(user.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
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
        children: [
          _buildCardTop(user, match),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.bio,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.school_rounded,
                  text: user.university,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.menu_book_rounded,
                  text: '${user.major} · Năm ${user.year}',
                ),
                const SizedBox(height: 18),
                _buildSectionTitle('Mục tiêu'),
                const SizedBox(height: 8),
                _buildChipWrap(user.goals, const Color(0xFF7B61FF)),
                const SizedBox(height: 16),
                _buildSectionTitle('Sở thích'),
                const SizedBox(height: 8),
                _buildChipWrap(user.interests, const Color(0xFF00A8CC)),
                const SizedBox(height: 16),
                _buildSectionTitle('Vibe'),
                const SizedBox(height: 8),
                _buildChipWrap(user.vibeTags, const Color(0xFFE91E63)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSignalButton(
                        hasSentSignal: hasSentSignal,
                        onPressed: hasSentSignal
                            ? null
                            : () {
                                _showSignalDialog(
                                  context: context,
                                  receiver: user,
                                );
                              },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildHideButton(context: context, user: user),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTop(UserProfile user, MatchResult match) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7FF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFF7B61FF),
                child: Text(
                  user.nickname[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
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
                    color: Colors.green,
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
                  user.nickname,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${user.major} · Năm ${user.year}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          _buildScoreBadge(match.compatibilityScore),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$score%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'match',
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.purple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChipWrap(List items, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return _buildChip(item.toString(), color);
      }).toList(),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSignalButton({
    required bool hasSentSignal,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        hasSentSignal ? Icons.check_circle_rounded : Icons.bolt_rounded,
        size: 19,
      ),
      label: Text(hasSentSignal ? 'Đã gửi Signal' : 'Gửi Signal'),
      style: ElevatedButton.styleFrom(
        backgroundColor: hasSentSignal
            ? Colors.grey.shade400
            : const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildHideButton({
    required BuildContext context,
    required UserProfile user,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        final result = HiddenMatchService.hideUser(user);

        refreshMatches();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Hoàn tác',
              textColor: Colors.white,
              onPressed: () {
                final undoResult = HiddenMatchService.unhideUser(user);

                refreshMatches();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(undoResult),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        );
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.visibility_off_rounded, color: Colors.black54),
      ),
    );
  }

  void _showSignalDialog({
    required BuildContext context,
    required UserProfile receiver,
  }) {
    final defaultMessage = _getDefaultSignalMessage(receiver);
    final messageController = TextEditingController(text: defaultMessage);

    final quickMessages = [
      defaultMessage,
      'Mình thấy tụi mình có nhiều điểm chung, kết nối nhé!',
      'Bạn có vẻ cùng vibe với mình!',
      'Hôm nào mình học hoặc đi event chung nhé!',
    ];

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
                  'Gửi Signal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gửi một lời nhắn ngắn cho ${receiver.nickname}. Nếu bạn ấy signal lại, hai bạn sẽ mở được phòng chat.',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Lời nhắn',
                    hintText: 'Nhập lời nhắn...',
                    filled: true,
                    fillColor: const Color(0xFFF7F3FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chọn nhanh',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickMessages.map((message) {
                    return ActionChip(
                      label: Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        messageController.text = message;
                      },
                    );
                  }).toList(),
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
                final result = SignalService.sendSignal(
                  currentUser: currentUser,
                  receiver: receiver,
                  message: messageController.text.trim().isEmpty
                      ? defaultMessage
                      : messageController.text.trim(),
                );

                Navigator.pop(dialogContext);

                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Gửi'),
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

  String _getDefaultSignalMessage(UserProfile receiver) {
    final goals = receiver.goals.map((goal) => goal.toString()).toList();

    if (goals.contains('Study Buddy')) {
      return 'Mình thấy bạn hợp vibe học chung, kết nối nhé!';
    }

    if (goals.contains('Food Buddy')) {
      return 'Mình thấy bạn cũng thích đi ăn, hôm nào đi chung nhé!';
    }

    if (goals.contains('Game Buddy')) {
      return 'Bạn có vẻ cùng vibe chơi game với mình!';
    }

    if (goals.contains('Event Buddy')) {
      return 'Mình muốn tìm bạn đi event/workshop chung, kết nối nhé!';
    }

    return 'Bạn có vẻ cùng vibe với mình!';
  }

  Widget _buildEmptyMatches() {
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
                  color: const Color(0xFF7B61FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 42,
                  color: Color(0xFF7B61FF),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Không còn match nào',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Những người bạn đã ẩn hoặc đã block sẽ không còn xuất hiện trong Daily Match.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
