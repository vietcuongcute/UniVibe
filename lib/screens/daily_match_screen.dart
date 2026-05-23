import 'package:flutter/material.dart';

class DailyMatchScreen extends StatelessWidget {
  const DailyMatchScreen({super.key});

  final List<Map<String, dynamic>> mockMatches = const [
    {
      'name': 'An',
      'major': 'Công nghệ thông tin',
      'year': 2,
      'matchType': 'Study Buddy',
      'score': 92,
      'bio': 'Thích học nhóm ở quán cà phê, tối hay code và nghe lofi.',
      'interests': ['Lập trình', 'Cà phê', 'Tiếng Anh'],
      'vibeTags': ['Chill', 'Night owl', 'Thích học nhóm'],
    },
    {
      'name': 'Bình',
      'major': 'Marketing',
      'year': 3,
      'matchType': 'Food Buddy',
      'score': 84,
      'bio': 'Luôn tìm quán ăn mới quanh trường, thích đi event cuối tuần.',
      'interests': ['Ăn uống', 'Du lịch', 'Phim'],
      'vibeTags': ['Hướng ngoại', 'Hài hước', 'Năng động'],
    },
    {
      'name': 'Chi',
      'major': 'Ngôn ngữ Anh',
      'year': 1,
      'matchType': 'Event Buddy',
      'score': 78,
      'bio':
          'Thích workshop, CLB, sách và các buổi nói chuyện truyền cảm hứng.',
      'interests': ['Sách', 'Tiếng Anh', 'Âm nhạc'],
      'vibeTags': ['Chill', 'Nghiêm túc', 'Thích yên tĩnh'],
    },
    {
      'name': 'Duy',
      'major': 'Thiết kế đồ họa',
      'year': 2,
      'matchType': 'Game Buddy',
      'score': 73,
      'bio': 'Game, anime, design và cà phê là combo mỗi tối.',
      'interests': ['Game', 'Cà phê', 'Phim'],
      'vibeTags': ['Night owl', 'Hài hước', 'Hướng nội'],
    },
  ];

  Color getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.deepPurple;
    if (score >= 70) return Colors.orange;
    return Colors.grey;
  }

  void sendSignal(BuildContext context, String name) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Bạn đã gửi Vibe Signal cho $name')));
  }

  void startBlindChat(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Blind Chat với $name sẽ được làm ở bước sau')),
    );
  }

  Widget buildTagList(List<dynamic> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Chip(
          label: Text(tag.toString()),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget buildMatchCard(BuildContext context, Map<String, dynamic> user) {
    final int score = user['score'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    user['name'][0],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${user['major']} • Năm ${user['year']}'),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: getScoreColor(score).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$score%',
                    style: TextStyle(
                      color: getScoreColor(score),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user['matchType'],
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(user['bio'], style: const TextStyle(fontSize: 15)),

            const SizedBox(height: 16),

            const Text(
              'Sở thích chung',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            buildTagList(user['interests']),

            const SizedBox(height: 14),

            const Text(
              'Vibe tag',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            buildTagList(user['vibeTags']),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => startBlindChat(context, user['name']),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Blind Chat'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => sendSignal(context, user['name']),
                    icon: const Icon(Icons.bolt),
                    label: const Text('Signal'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Match')),
      body: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gợi ý hôm nay',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'UniVibe đề xuất những sinh viên có sở thích, mục tiêu và vibe gần với bạn.',
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: mockMatches.length,
                itemBuilder: (context, index) {
                  final user = mockMatches[index];
                  return buildMatchCard(context, user);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
