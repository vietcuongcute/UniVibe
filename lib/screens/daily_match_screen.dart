import 'package:flutter/material.dart';

import 'blind_chat_screen.dart';

import '../data/mock_users.dart';
import '../models/user_profile.dart';
import '../services/block_service.dart';
import '../services/match_service.dart';
import '../services/report_service.dart';
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
      return !BlockService.isBlocked(match.user.id);
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
            'Dựa trên mục tiêu, sở thích, ngành học và vibe tag của bạn.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
        ],
      ),
    );
  }

  Widget _buildMatchCard({
    required BuildContext context,
    required UserProfile user,
    required MatchResult match,
  }) {
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
                      child: _buildPrimaryButton(
                        label: 'Blind Chat',
                        icon: Icons.chat_bubble_rounded,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BlindChatScreen(otherUser: user),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSecondaryButton(
                        label: 'Signal',
                        icon: Icons.bolt_rounded,
                        onPressed: () {
                          final result = SignalService.sendSignal(
                            currentUser: currentUser,
                            receiver: user,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildMoreButton(context: context, user: user),
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

  Widget _buildChipWrap(List<String> items, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return _buildChip(item, color);
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

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7B61FF),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFF9800),
        side: const BorderSide(color: Color(0xFFFF9800), width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildMoreButton({
    required BuildContext context,
    required UserProfile user,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _showSafetyBottomSheet(context: context, user: user);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.more_horiz_rounded, color: Colors.black54),
      ),
    );
  }

  void _showSafetyBottomSheet({
    required BuildContext context,
    required UserProfile user,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
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
                      user.nickname[0].toUpperCase(),
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
                subtitle: 'Báo cáo hồ sơ hoặc hành vi không phù hợp.',
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
                subtitle: 'Ẩn người này khỏi Daily Match của bạn.',
                onTap: () {
                  Navigator.pop(bottomSheetContext);

                  final result = BlockService.blockUser(user);

                  refreshMatches();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Hoàn tác',
                        textColor: Colors.white,
                        onPressed: () {
                          final undoResult = BlockService.unblockUser(user);

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
    String selectedReason = 'Hồ sơ không phù hợp';
    final detailController = TextEditingController();

    final List<String> reasons = [
      'Hồ sơ không phù hợp',
      'Tin nhắn làm phiền',
      'Giả mạo danh tính',
      'Nội dung phản cảm',
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
                        return DropdownMenuItem(
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
                  onPressed: () {
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
                'Những người bạn đã block sẽ không còn xuất hiện trong Daily Match.',
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
