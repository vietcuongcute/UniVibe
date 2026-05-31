import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/user_profile_service.dart';
import 'auth_gate.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  static const Color _primary = Color(0xFF7B61FF);
  static const Color _darkText = Color(0xFF2D1B69);
  static const Color _bg = Color(0xFFF7F3FF);

  late Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = UserProfileService.getCurrentUserProfile();
  }

  void _reloadProfile() {
    setState(() {
      _profileFuture = UserProfileService.getCurrentUserProfile();
    });
  }

  Future<void> _logout() async {
    try {
      ChatService.chatRoomsNotifier.value = [];
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      _showMessage('Đăng xuất thất bại: $e');
    }
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Đăng xuất?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Bạn có chắc muốn đăng xuất tài khoản hiện tại không?',
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _logout();
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog(UserProfile profile) {
    final nicknameController = TextEditingController(text: profile.nickname);
    final universityController = TextEditingController(
      text: profile.university,
    );
    final majorController = TextEditingController(text: profile.major);
    final bioController = TextEditingController(text: profile.bio);

    final interestsController = TextEditingController(
      text: profile.interests.join(', '),
    );
    final goalsController = TextEditingController(
      text: profile.goals.join(', '),
    );
    final vibeTagsController = TextEditingController(
      text: profile.vibeTags.join(', '),
    );

    int selectedYear = profile.year;
    String selectedGender = profile.gender.isEmpty
        ? 'Không muốn nói'
        : profile.gender;

    final genderOptions = ['Nam', 'Nữ', 'Khác', 'Không muốn nói'];

    if (!genderOptions.contains(selectedGender)) {
      selectedGender = 'Không muốn nói';
    }

    List<String> parseList(String text) {
      return text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveProfile() async {
              final nickname = nicknameController.text.trim();
              final university = universityController.text.trim();
              final major = majorController.text.trim();
              final bio = bioController.text.trim();

              final interests = parseList(interestsController.text);
              final goals = parseList(goalsController.text);
              final vibeTags = parseList(vibeTagsController.text);

              if (nickname.isEmpty || university.isEmpty || major.isEmpty) {
                _showMessage('Vui lòng nhập nickname, trường và ngành học');
                return;
              }

              try {
                setDialogState(() => isSaving = true);

                await UserProfileService.updateProfile(
                  data: {
                    'nickname': nickname,
                    'university': university,
                    'major': major,
                    'year': selectedYear,
                    'gender': selectedGender,
                    'bio': bio,
                    'interests': interests,
                    'goals': goals,
                    'vibeTags': vibeTags,
                  },
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);
                _reloadProfile();
                _showMessage('Đã cập nhật hồ sơ');
              } catch (e) {
                _showMessage('Cập nhật thất bại: $e');
              } finally {
                if (mounted) {
                  setDialogState(() => isSaving = false);
                }
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Chỉnh sửa hồ sơ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogTextField(
                        controller: nicknameController,
                        label: 'Nickname',
                        icon: Icons.badge_rounded,
                      ),
                      const SizedBox(height: 12),

                      _buildDialogTextField(
                        controller: universityController,
                        label: 'Trường',
                        icon: Icons.school_rounded,
                      ),
                      const SizedBox(height: 12),

                      _buildDialogTextField(
                        controller: majorController,
                        label: 'Ngành học',
                        icon: Icons.menu_book_rounded,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedYear,
                              decoration: _dialogInputDecoration(
                                label: 'Năm học',
                                icon: Icons.calendar_month_rounded,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('Năm 1'),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('Năm 2'),
                                ),
                                DropdownMenuItem(
                                  value: 3,
                                  child: Text('Năm 3'),
                                ),
                                DropdownMenuItem(
                                  value: 4,
                                  child: Text('Năm 4'),
                                ),
                                DropdownMenuItem(
                                  value: 5,
                                  child: Text('Năm 5+'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() {
                                  selectedYear = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedGender,
                              decoration: _dialogInputDecoration(
                                label: 'Giới tính',
                                icon: Icons.person_rounded,
                              ),
                              items: genderOptions.map((gender) {
                                return DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() {
                                  selectedGender = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildDialogTextField(
                        controller: bioController,
                        label: 'Bio',
                        icon: Icons.edit_rounded,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 18),
                      _buildDialogSectionTitle(
                        icon: Icons.interests_rounded,
                        title: 'Sở thích',
                      ),
                      const SizedBox(height: 8),
                      _buildDialogTextField(
                        controller: interestsController,
                        label: 'Ví dụ: game, cà phê, học nhóm',
                        icon: Icons.favorite_rounded,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 14),
                      _buildDialogSectionTitle(
                        icon: Icons.flag_rounded,
                        title: 'Mục tiêu',
                      ),
                      const SizedBox(height: 8),
                      _buildDialogTextField(
                        controller: goalsController,
                        label: 'Ví dụ: tìm bạn học, đi chơi, tìm người yêu',
                        icon: Icons.rocket_launch_rounded,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 14),
                      _buildDialogSectionTitle(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Vibe tags',
                      ),
                      const SizedBox(height: 8),
                      _buildDialogTextField(
                        controller: vibeTagsController,
                        label: 'Ví dụ: chill, hướng nội, năng động',
                        icon: Icons.local_fire_department_rounded,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mỗi mục cách nhau bằng dấu phẩy. Ví dụ: game, học bài, cà phê',
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _dialogInputDecoration(label: label, icon: icon),
    );
  }

  InputDecoration _dialogInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: const Color(0xFFF9F7FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.purple.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FutureBuilder<UserProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final profile = snapshot.data;

            if (profile == null) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              color: _primary,
              onRefresh: () async {
                _reloadProfile();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  _buildProfileHeader(profile, authUser?.email ?? ''),
                  const SizedBox(height: 18),
                  _buildInfoCard(profile),
                  const SizedBox(height: 18),
                  _buildTagSection(
                    title: 'Mục tiêu',
                    icon: Icons.flag_rounded,
                    items: profile.goals,
                  ),
                  const SizedBox(height: 18),
                  _buildTagSection(
                    title: 'Sở thích',
                    icon: Icons.interests_rounded,
                    items: profile.interests,
                  ),
                  const SizedBox(height: 18),
                  _buildTagSection(
                    title: 'Vibe tags',
                    icon: Icons.auto_awesome_rounded,
                    items: profile.vibeTags,
                  ),
                  const SizedBox(height: 18),
                  _buildActionCard(profile),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile, String email) {
    final firstLetter = profile.nickname.trim().isEmpty
        ? 'U'
        : profile.nickname.trim()[0].toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFFEC5AA6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white.withOpacity(0.22),
            backgroundImage: profile.avatarUrl.isNotEmpty
                ? NetworkImage(profile.avatarUrl)
                : null,
            child: profile.avatarUrl.isEmpty
                ? Text(
                    firstLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            profile.nickname,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email.isEmpty ? 'Chưa có email' : email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: Text(
              '${profile.major} • Năm ${profile.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin tài khoản',
            style: TextStyle(
              color: _darkText,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.school_rounded,
            label: 'Trường',
            value: profile.university,
          ),
          _buildInfoRow(
            icon: Icons.menu_book_rounded,
            label: 'Ngành',
            value: profile.major,
          ),
          _buildInfoRow(
            icon: Icons.calendar_month_rounded,
            label: 'Năm học',
            value: 'Năm ${profile.year}',
          ),
          _buildInfoRow(
            icon: Icons.person_rounded,
            label: 'Giới tính',
            value: profile.gender.isEmpty ? 'Chưa cập nhật' : profile.gender,
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            profile.bio.isEmpty ? 'Chưa có bio.' : profile.bio,
            style: const TextStyle(color: Colors.black87, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EAFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? 'Chưa cập nhật' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _darkText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Chưa cập nhật mục này.',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EAFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: _darkText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard(UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showEditProfileDialog(profile),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Chỉnh sửa hồ sơ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _showLogoutConfirmDialog,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53935),
                side: const BorderSide(color: Color(0xFFFFCDD2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFF1EAFF),
                child: Icon(
                  Icons.person_search_rounded,
                  color: _primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Chưa tìm thấy hồ sơ',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tài khoản này chưa có dữ liệu profile trong collection users.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _reloadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFFFEBEE),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFE53935),
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Không tải được tài khoản',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _reloadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: Colors.purple.withOpacity(0.07),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
