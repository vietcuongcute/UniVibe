import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';
import 'home_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  final String? initialNickname;

  const CreateProfileScreen({super.key, this.initialNickname});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  late final TextEditingController nicknameController;
  final universityController = TextEditingController();
  final majorController = TextEditingController();
  final bioController = TextEditingController();

  bool isLoading = false;

  int selectedYear = 1;
  String selectedGender = 'Không muốn nói';

  final Set<String> selectedGoals = {};
  final Set<String> selectedInterests = {};
  final Set<String> selectedVibeTags = {};

  final List<String> yearOptions = [
    'Năm 1',
    'Năm 2',
    'Năm 3',
    'Năm 4',
    'Năm 5+',
  ];

  final List<String> genderOptions = ['Nam', 'Nữ', 'Khác', 'Không muốn nói'];

  final List<String> goalOptions = [
    'Study Buddy',
    'Food Buddy',
    'Game Buddy',
    'Dating',
    'Friendship',
    'Project Team',
    'Workout Buddy',
    'Language Exchange',
  ];

  final List<String> interestOptions = [
    'Âm nhạc',
    'Phim ảnh',
    'Game',
    'Đọc sách',
    'Cà phê',
    'Du lịch',
    'Thể thao',
    'Lập trình',
    'Thiết kế',
    'Nhiếp ảnh',
    'Kinh doanh',
    'Anime',
  ];

  final List<String> vibeTagOptions = [
    'Hướng ngoại',
    'Hướng nội',
    'Chill',
    'Năng lượng',
    'Hài hước',
    'Sâu sắc',
    'Sáng tạo',
    'Kỷ luật',
    'Thích học',
    'Hay đi chơi',
  ];

  @override
  void initState() {
    super.initState();
    nicknameController = TextEditingController(
      text: widget.initialNickname ?? '',
    );
  }

  Future<void> submitProfile() async {
    final nickname = nicknameController.text.trim();
    final university = universityController.text.trim();
    final major = majorController.text.trim();
    final bio = bioController.text.trim();

    if (nickname.isEmpty || university.isEmpty || major.isEmpty) {
      showMessage('Vui lòng nhập nickname, trường và ngành học');
      return;
    }

    if (selectedGoals.isEmpty) {
      showMessage('Vui lòng chọn ít nhất 1 mục tiêu');
      return;
    }

    if (selectedInterests.isEmpty) {
      showMessage('Vui lòng chọn ít nhất 1 sở thích');
      return;
    }

    try {
      setState(() => isLoading = true);

      await UserProfileService.createProfile(
        nickname: nickname,
        university: university,
        major: major,
        year: selectedYear,
        gender: selectedGender,
        bio: bio,
        interests: selectedInterests.toList(),
        goals: selectedGoals.toList(),
        vibeTags: selectedVibeTags.toList(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      showMessage('Tạo profile thất bại: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void toggleItem(Set<String> selectedSet, String value) {
    setState(() {
      if (selectedSet.contains(value)) {
        selectedSet.remove(value);
      } else {
        selectedSet.add(value);
      }
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
      backgroundColor: const Color(0xFFF7F3FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoCard(),
                    const SizedBox(height: 18),
                    _buildChoiceSection(
                      title: 'Bạn muốn tìm gì?',
                      subtitle: 'Chọn ít nhất 1 mục tiêu',
                      options: goalOptions,
                      selectedSet: selectedGoals,
                    ),
                    const SizedBox(height: 18),
                    _buildChoiceSection(
                      title: 'Sở thích của bạn',
                      subtitle: 'Chọn ít nhất 1 sở thích',
                      options: interestOptions,
                      selectedSet: selectedInterests,
                    ),
                    const SizedBox(height: 18),
                    _buildChoiceSection(
                      title: 'Vibe tags',
                      subtitle: 'Chọn vài tag mô tả vibe của bạn',
                      options: vibeTagOptions,
                      selectedSet: selectedVibeTags,
                    ),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tạo Vibe Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Thông tin này giúp UniVibe gợi ý người hợp với bạn hơn.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: nicknameController,
            label: 'Nickname',
            hint: 'Ví dụ: Minh Anh',
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: universityController,
            label: 'Trường đại học',
            hint: 'Ví dụ: Đại học Yersin Đà Lạt',
            icon: Icons.school_rounded,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: majorController,
            label: 'Ngành học',
            hint: 'Ví dụ: Công nghệ thông tin',
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildYearDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildGenderDropdown()),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: bioController,
            label: 'Bio ngắn',
            hint: 'Viết vài dòng về bạn',
            icon: Icons.edit_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedYear,
      decoration: _inputDecoration(
        label: 'Năm học',
        icon: Icons.calendar_month_rounded,
      ),
      items: List.generate(yearOptions.length, (index) {
        final value = index + 1;
        return DropdownMenuItem<int>(
          value: value,
          child: Text(yearOptions[index]),
        );
      }),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          selectedYear = value;
        });
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: _inputDecoration(
        label: 'Giới tính',
        icon: Icons.person_rounded,
      ),
      items: genderOptions.map((gender) {
        return DropdownMenuItem<String>(value: gender, child: Text(gender));
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          selectedGender = value;
        });
      },
    );
  }

  Widget _buildChoiceSection({
    required String title,
    required String subtitle,
    required List<String> options,
    required Set<String> selectedSet,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: options.map((option) {
              final isSelected = selectedSet.contains(option);

              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                selectedColor: const Color(0xFF7B61FF),
                backgroundColor: const Color(0xFFF7F3FF),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF7B61FF)
                      : Colors.purple.shade100,
                ),
                onSelected: (_) {
                  toggleItem(selectedSet, option);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : submitProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B61FF),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.purple.shade200,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Hoàn tất profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
      filled: true,
      fillColor: const Color(0xFFF9F7FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.purple.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.6),
      ),
    );
  }
}
