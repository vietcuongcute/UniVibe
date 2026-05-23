import 'package:flutter/material.dart';

import 'home_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final nicknameController = TextEditingController();
  final universityController = TextEditingController();
  final majorController = TextEditingController();
  final bioController = TextEditingController();

  int selectedYear = 1;
  String selectedGender = 'Không muốn nói';

  final List<String> selectedGoals = [];
  final List<String> selectedInterests = [];
  final List<String> selectedVibeTags = [];

  final List<String> goals = [
    'Study Buddy',
    'Food Buddy',
    'Game Buddy',
    'Event Buddy',
    'Crush Mode',
  ];

  final List<String> interests = [
    'Âm nhạc',
    'Game',
    'Cà phê',
    'Phim',
    'Sách',
    'Thể thao',
    'Lập trình',
    'Tiếng Anh',
    'Du lịch',
    'Ăn uống',
  ];

  final List<String> vibeTags = [
    'Chill',
    'Hướng nội',
    'Hướng ngoại',
    'Night owl',
    'Năng động',
    'Hài hước',
    'Nghiêm túc',
    'Thích học nhóm',
    'Thích yên tĩnh',
  ];

  void toggleSelection(List<String> selectedList, String value) {
    setState(() {
      if (selectedList.contains(value)) {
        selectedList.remove(value);
      } else {
        selectedList.add(value);
      }
    });
  }

  void saveProfile() {
    final nickname = nicknameController.text.trim();
    final university = universityController.text.trim();
    final major = majorController.text.trim();

    if (nickname.isEmpty ||
        university.isEmpty ||
        major.isEmpty ||
        selectedGoals.isEmpty ||
        selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập đủ thông tin và chọn ít nhất 1 mục tiêu, 1 sở thích',
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );
  }

  Widget buildChoiceChips({
    required List<String> options,
    required List<String> selectedList,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((item) {
        final isSelected = selectedList.contains(item);

        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => toggleSelection(selectedList, item),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    nicknameController.dispose();
    universityController.dispose();
    majorController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Vibe Profile')),
      body: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cho UniVibe biết bạn là ai',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Thông tin này giúp app gợi ý những người có cùng sở thích, mục tiêu và vibe với bạn.',
              ),

              const SizedBox(height: 24),

              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  hintText: 'Ví dụ: Minh chill',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: universityController,
                decoration: const InputDecoration(
                  labelText: 'Trường đại học',
                  hintText: 'Ví dụ: Đại học ABC',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: majorController,
                decoration: const InputDecoration(
                  labelText: 'Ngành học',
                  hintText: 'Ví dụ: Công nghệ thông tin',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Năm học',
                  border: OutlineInputBorder(),
                ),
                items: [1, 2, 3, 4, 5].map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text('Năm $year'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedYear = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Giới tính',
                  border: OutlineInputBorder(),
                ),
                items: ['Nam', 'Nữ', 'Khác', 'Không muốn nói'].map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedGender = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              buildSectionTitle('Bạn muốn tìm gì trên UniVibe?'),
              const SizedBox(height: 8),
              buildChoiceChips(options: goals, selectedList: selectedGoals),

              const SizedBox(height: 24),

              buildSectionTitle('Sở thích của bạn'),
              const SizedBox(height: 8),
              buildChoiceChips(
                options: interests,
                selectedList: selectedInterests,
              ),

              const SizedBox(height: 24),

              buildSectionTitle('Vibe tag'),
              const SizedBox(height: 8),
              buildChoiceChips(
                options: vibeTags,
                selectedList: selectedVibeTags,
              ),

              const SizedBox(height: 24),

              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio ngắn',
                  hintText:
                      'Ví dụ: Thích học nhóm ở quán cà phê, tối hay chơi game.',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: saveProfile,
                  child: const Text('Hoàn tất profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
