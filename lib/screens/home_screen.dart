import 'package:flutter/material.dart';

import 'daily_match_screen.dart';
import 'create_profile_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      {
        'title': 'Vibe Profile',
        'description': 'Tạo hoặc cập nhật hồ sơ vibe của bạn.',
        'icon': Icons.person_outline,
      },
      {
        'title': 'Daily Match',
        'description': 'Xem những người hợp vibe với bạn hôm nay.',
        'icon': Icons.auto_awesome,
      },
      {
        'title': 'Blind Chat',
        'description': 'Chat ẩn danh trong thời gian giới hạn.',
        'icon': Icons.chat_bubble_outline,
      },
      {
        'title': 'Crush Signal',
        'description': 'Gửi tín hiệu quan tâm nhẹ nhàng.',
        'icon': Icons.favorite_border,
      },
      {
        'title': 'Daily Poll',
        'description': 'Trả lời câu hỏi vui hằng ngày.',
        'icon': Icons.poll_outlined,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniVibe'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xin chào 👋',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Hôm nay bạn muốn tìm người cùng vibe kiểu nào?',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: ListView.separated(
                itemCount: features.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final feature = features[index];

                  return Card(
                    child: ListTile(
                      minVerticalPadding: 16,
                      leading: Icon(
                        feature['icon'],
                        size: 34,
                        color: Colors.deepPurple,
                      ),
                      title: Text(
                        feature['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(feature['description']),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        if (feature['title'] == 'Vibe Profile') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateProfileScreen(),
                            ),
                          );
                          return;
                        }

                        if (feature['title'] == 'Daily Match') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DailyMatchScreen(),
                            ),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bạn vừa bấm ${feature['title']}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
