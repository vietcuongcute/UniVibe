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
    'Bi-da',
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
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
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
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoCard(),

                    const SizedBox(height: 16),

                    _buildChoiceCard(
                      icon: Icons.flag_rounded,
                      iconColor: const Color(0xFF7B61FF),
                      title: 'Bạn muốn tìm gì trên UniVibe?',
                      subtitle:
                          'Chọn ít nhất 1 mục tiêu để hệ thống match đúng hơn.',
                      options: goals,
                      selectedList: selectedGoals,
                    ),

                    const SizedBox(height: 16),

                    _buildChoiceCard(
                      icon: Icons.interests_rounded,
                      iconColor: const Color(0xFF00A8CC),
                      title: 'Sở thích của bạn',
                      subtitle: 'Những điểm chung giúp bắt chuyện dễ hơn.',
                      options: interests,
                      selectedList: selectedInterests,
                    ),

                    const SizedBox(height: 16),

                    _buildChoiceCard(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFFE91E63),
                      title: 'Vibe tag',
                      subtitle: 'Chọn vài vibe mô tả đúng con người bạn.',
                      options: vibeTags,
                      selectedList: selectedVibeTags,
                    ),

                    const SizedBox(height: 16),

                    _buildBioCard(),

                    const SizedBox(height: 22),

                    _buildSubmitButton(),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tạo Vibe Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Cho UniVibe biết bạn là ai để gợi ý match phù hợp.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
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

  Widget _buildBasicInfoCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(
            icon: Icons.badge_rounded,
            iconColor: const Color(0xFF7B61FF),
            title: 'Thông tin cơ bản',
            subtitle: 'Những thông tin này giúp hồ sơ của bạn rõ ràng hơn.',
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: nicknameController,
            label: 'Nickname',
            hint: 'Ví dụ: Minh chill',
            icon: Icons.person_rounded,
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: universityController,
            label: 'Trường đại học',
            hint: 'Ví dụ: Đại học ABC',
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
        ],
      ),
    );
  }

  Widget _buildBioCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFFFF9800),
            title: 'Bio ngắn',
            subtitle: 'Viết vài dòng để người khác dễ bắt chuyện hơn.',
          ),

          const SizedBox(height: 18),

          _buildTextField(
            controller: bioController,
            label: 'Bio ngắn',
            hint: 'Ví dụ: Thích học nhóm ở quán cà phê, tối hay chơi game.',
            icon: Icons.chat_bubble_outline_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> options,
    required List<String> selectedList,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(
            icon: icon,
            iconColor: iconColor,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 16),
          _buildChoiceChips(
            options: options,
            selectedList: selectedList,
            color: iconColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: child,
    );
  }

  Widget _buildCardTitle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 25),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 56 : 0),
          child: Icon(icon, color: const Color(0xFF7B61FF)),
        ),
        filled: true,
        fillColor: const Color(0xFFF9F7FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.purple.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.6),
        ),
      ),
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedYear,
      decoration: _dropdownDecoration(
        label: 'Năm học',
        icon: Icons.calendar_month_rounded,
      ),
      items: [1, 2, 3, 4, 5].map((year) {
        return DropdownMenuItem(value: year, child: Text('Năm $year'));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            selectedYear = value;
          });
        }
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      decoration: _dropdownDecoration(
        label: 'Giới tính',
        icon: Icons.wc_rounded,
      ),
      items: ['Nam', 'Nữ', 'Khác', 'Không muốn nói'].map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text(gender, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            selectedGender = value;
          });
        }
      },
    );
  }

  InputDecoration _dropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
      filled: true,
      fillColor: const Color(0xFFF9F7FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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

  Widget _buildChoiceChips({
    required List<String> options,
    required List<String> selectedList,
    required Color color,
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
          showCheckmark: false,
          selectedColor: color.withOpacity(0.14),
          backgroundColor: const Color(0xFFF9F7FF),
          side: BorderSide(color: isSelected ? color : Colors.purple.shade100),
          labelStyle: TextStyle(
            color: isSelected ? color : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: saveProfile,
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text(
          'Hoàn tất profile',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B61FF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
