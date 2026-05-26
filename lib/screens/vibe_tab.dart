import 'package:flutter/material.dart';

import 'daily_match_screen.dart';
import 'signals_screen.dart';
import 'blind_chat_screen.dart';
import 'daily_poll_screen.dart';

class VibeTab extends StatelessWidget {
  const VibeTab({super.key});

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 18),
          _buildFeatureCard(
            context: context,
            title: 'Daily Match',
            subtitle: 'Tìm người hợp vibe hôm nay.',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF7B61FF),
            screen: const DailyMatchScreen(),
          ),
          _buildFeatureCard(
            context: context,
            title: 'Vibe Signals',
            subtitle: 'Xem signal đã nhận, đã gửi và mutual signal.',
            icon: Icons.bolt_rounded,
            color: const Color(0xFFFF9800),
            screen: const SignalsScreen(),
          ),
          _buildFeatureCard(
            context: context,
            title: 'Blind Chat',
            subtitle: 'Bóc túi mù để trò chuyện ẩn danh.',
            icon: Icons.visibility_off_rounded,
            color: const Color(0xFFE91E63),
            screen: const BlindChatScreen(),
          ),
          _buildFeatureCard(
            context: context,
            title: 'Daily Poll',
            subtitle: 'Vote câu hỏi vui hằng ngày.',
            icon: Icons.poll_rounded,
            color: const Color(0xFF00A8CC),
            screen: const DailyPollScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_rounded, color: Colors.white, size: 42),
          SizedBox(height: 16),
          Text(
            'Tìm người cùng vibe trong trường',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gửi Signal. Nếu hai bên cùng gửi Signal thì mở Chat.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openScreen(context, screen),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 28),
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
