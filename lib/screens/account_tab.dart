import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/user_profile_service.dart';
import 'auth_gate.dart';

class AccountTab extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const AccountTab({super.key, this.onNavigate});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  static const Color _primary = Color(0xFF7B61FF);
  static const Color _pink = Color(0xFFEC5AA6);
  static const Color _darkText = Color(0xFF2D1B69);
  static const Color _bg = Color(0xFFF7F3FF);

  late Future<UserProfile?> _profileFuture;
  late Future<_UserDashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  void _reloadData() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    setState(() {
      _profileFuture = UserProfileService.getCurrentUserProfile();
      _statsFuture = _loadStats(uid);
    });
  }

  Future<_UserDashboardStats> _loadStats(String uid) async {
    if (uid.isEmpty) return _UserDashboardStats.empty();

    final db = FirebaseFirestore.instance;

    try {
      final userDoc = await db.collection('users').doc(uid).get();
      final role = userDoc.data()?['role']?.toString() ?? 'student';

      final results = await Future.wait<int>([
        _safeCount(db.collection('signals').where('senderId', isEqualTo: uid)),
        _safeCount(
          db.collection('matches').where('userIds', arrayContains: uid),
        ),
        _safeCount(
          db.collection('chatRooms').where('userIds', arrayContains: uid),
        ),
        _safeCount(
          db.collection('confessions').where('authorId', isEqualTo: uid),
        ),
        _safeCountMoment(uid),
        _safeCount(
          db.collection('marketPosts').where('sellerId', isEqualTo: uid),
        ),
      ]);

      return _UserDashboardStats(
        sentSignals: results[0],
        matches: results[1],
        chatRooms: results[2],
        confessions: results[3],
        moments: results[4],
        marketPosts: results[5],
        role: role,
      );
    } catch (_) {
      return _UserDashboardStats.empty();
    }
  }

  Future<int> _safeCount(Query<Map<String, dynamic>> query) async {
    try {
      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _safeCountMoment(String uid) async {
    final db = FirebaseFirestore.instance;

    final byAuthorId = await _safeCount(
      db.collection('moments').where('authorId', isEqualTo: uid),
    );

    if (byAuthorId > 0) return byAuthorId;

    return _safeCount(db.collection('moments').where('userId', isEqualTo: uid));
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
                _reloadData();
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
                width: 560,
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

  void _showStorageLaterMessage() {
    _showMessage(
      'Upload ảnh sẽ làm sau vì Firebase Storage chưa bật. Hiện tại dùng placeholder trước.',
    );
  }

  void _goTo(int index) {
    widget.onNavigate?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FutureBuilder<UserProfile?>(
          future: _profileFuture,
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            }

            if (profileSnapshot.hasError) {
              return _buildErrorState(profileSnapshot.error.toString());
            }

            final profile = profileSnapshot.data;

            if (profile == null) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              color: _primary,
              onRefresh: () async {
                _reloadData();
                await Future.delayed(const Duration(milliseconds: 350));
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      _buildHeroProfile(
                        profile: profile,
                        email: authUser?.email ?? '',
                      ),
                      const SizedBox(height: 18),
                      FutureBuilder<_UserDashboardStats>(
                        future: _statsFuture,
                        builder: (context, statsSnapshot) {
                          final stats =
                              statsSnapshot.data ?? _UserDashboardStats.empty();

                          return _buildStatsSection(stats);
                        },
                      ),
                      const SizedBox(height: 18),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildInfoCard(profile)),
                            const SizedBox(width: 18),
                            Expanded(child: _buildQuickActions(profile)),
                          ],
                        )
                      else ...[
                        _buildInfoCard(profile),
                        const SizedBox(height: 18),
                        _buildQuickActions(profile),
                      ],
                      const SizedBox(height: 18),
                      _buildSectionCard(
                        title: 'Bio',
                        icon: Icons.notes_rounded,
                        child: Text(
                          profile.bio.isEmpty
                              ? 'Chưa có bio. Hãy viết vài dòng để người khác hiểu vibe của bạn hơn.'
                              : profile.bio,
                          style: const TextStyle(
                            color: Colors.black87,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildTagSection(
                        title: 'Mục tiêu',
                        icon: Icons.flag_rounded,
                        items: profile.goals,
                        emptyText:
                            'Chưa cập nhật mục tiêu. Ví dụ: tìm bạn học, tìm teammate, tìm người yêu.',
                      ),
                      const SizedBox(height: 18),
                      _buildTagSection(
                        title: 'Sở thích',
                        icon: Icons.interests_rounded,
                        items: profile.interests,
                        emptyText:
                            'Chưa cập nhật sở thích. Ví dụ: game, cà phê, chạy deadline, nghe nhạc.',
                      ),
                      const SizedBox(height: 18),
                      _buildTagSection(
                        title: 'Vibe tags',
                        icon: Icons.auto_awesome_rounded,
                        items: profile.vibeTags,
                        emptyText:
                            'Chưa cập nhật vibe tags. Ví dụ: chill, hướng nội, năng động.',
                      ),
                      const SizedBox(height: 18),
                      _buildFeaturedImagesSection(profile),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroProfile({
    required UserProfile profile,
    required String email,
  }) {
    final firstLetter = profile.nickname.trim().isEmpty
        ? 'U'
        : profile.nickname.trim()[0].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFFEC5AA6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  image: profile.coverUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(profile.coverUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile.coverUrl.isEmpty
                    ? Stack(
                        children: [
                          Positioned(
                            top: 18,
                            right: 20,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white.withOpacity(0.28),
                              size: 54,
                            ),
                          ),
                          Positioned(
                            bottom: 18,
                            left: 20,
                            child: Text(
                              'UniVibe Student Dashboard',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.88),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
              Positioned(
                bottom: -44,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFFF1EAFF),
                        backgroundImage: profile.avatarUrl.isNotEmpty
                            ? NetworkImage(profile.avatarUrl)
                            : null,
                        child: profile.avatarUrl.isEmpty
                            ? Text(
                                firstLetter,
                                style: const TextStyle(
                                  color: _primary,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),
                    ),
                    InkWell(
                      onTap: _showStorageLaterMessage,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 54),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: Column(
              children: [
                Text(
                  profile.nickname.isEmpty
                      ? 'Sinh viên UniVibe'
                      : profile.nickname,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email.isEmpty ? 'Chưa có email' : email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMiniBadge(
                      icon: Icons.school_rounded,
                      text: profile.university.isEmpty
                          ? 'Chưa cập nhật trường'
                          : profile.university,
                    ),
                    _buildMiniBadge(
                      icon: Icons.menu_book_rounded,
                      text: profile.major.isEmpty
                          ? 'Chưa cập nhật ngành'
                          : profile.major,
                    ),
                    _buildMiniBadge(
                      icon: Icons.calendar_month_rounded,
                      text: 'Năm ${profile.year}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(_UserDashboardStats stats) {
    return _buildSectionCard(
      title: 'Thống kê cá nhân',
      icon: Icons.insights_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EAFF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _formatRole(stats.role),
          style: const TextStyle(
            color: _primary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 700 ? 6 : 3;

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth >= 700 ? 1.05 : 1.12,
            children: [
              _buildStatTile(
                icon: Icons.send_rounded,
                label: 'Signal',
                value: stats.sentSignals,
              ),
              _buildStatTile(
                icon: Icons.favorite_rounded,
                label: 'Match',
                value: stats.matches,
              ),
              _buildStatTile(
                icon: Icons.chat_bubble_rounded,
                label: 'Chat',
                value: stats.chatRooms,
              ),
              _buildStatTile(
                icon: Icons.forum_rounded,
                label: 'Confess',
                value: stats.confessions,
              ),
              _buildStatTile(
                icon: Icons.auto_awesome_rounded,
                label: 'Moment',
                value: stats.moments,
              ),
              _buildStatTile(
                icon: Icons.storefront_rounded,
                label: 'Market',
                value: stats.marketPosts,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required int value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _primary, size: 22),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              color: _darkText,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserProfile profile) {
    return _buildSectionCard(
      title: 'Thông tin sinh viên',
      icon: Icons.account_circle_rounded,
      child: Column(
        children: [
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
        ],
      ),
    );
  }

  Widget _buildQuickActions(UserProfile profile) {
    return _buildSectionCard(
      title: 'Thao tác nhanh',
      icon: Icons.bolt_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Sửa hồ sơ',
                  color: _primary,
                  onTap: () => _showEditProfileDialog(profile),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Vào Chat',
                  color: const Color(0xFF00A6A6),
                  onTap: () => _goTo(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.storefront_rounded,
                  label: 'Đăng Market',
                  color: const Color(0xFFFF8A00),
                  onTap: () => _goTo(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.forum_rounded,
                  label: 'Confession',
                  color: const Color(0xFF8E2DE2),
                  onTap: () => _goTo(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'UniMoment',
                  color: _pink,
                  onTap: () => _goTo(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.logout_rounded,
                  label: 'Đăng xuất',
                  color: const Color(0xFFE53935),
                  onTap: _showLogoutConfirmDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedImagesSection(UserProfile profile) {
    return _buildSectionCard(
      title: 'Ảnh nổi bật',
      icon: Icons.photo_library_rounded,
      trailing: TextButton.icon(
        onPressed: _showStorageLaterMessage,
        icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
        label: const Text('Thêm'),
      ),
      child: profile.featuredImageUrls.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEDE7FF)),
              ),
              child: const Text(
                'Chưa có ảnh nổi bật. Sau khi bật Firebase Storage, mục này sẽ dùng để show ảnh cá nhân/hoạt động nổi bật.',
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: profile.featuredImageUrls.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final imageUrl = profile.featuredImageUrls[index];

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF1EAFF),
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: _primary,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTagSection({
    required String title,
    required IconData icon,
    required List items,
    required String emptyText,
  }) {
    return _buildSectionCard(
      title: title,
      icon: icon,
      child: items.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                emptyText,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            )
          : Wrap(
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
                    item.toString(),
                    style: const TextStyle(
                      color: _darkText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EAFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _primary, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 15),
          child,
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _primary, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _darkText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
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
                onPressed: _reloadData,
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
                onPressed: _reloadData,
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

  Widget _buildDialogSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6D4AFF),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      case 'clubLeader':
        return 'CLB Leader';
      case 'eventManager':
        return 'Event Manager';
      case 'student':
      default:
        return 'Student';
    }
  }
}

class _UserDashboardStats {
  final int sentSignals;
  final int matches;
  final int chatRooms;
  final int confessions;
  final int moments;
  final int marketPosts;
  final String role;

  const _UserDashboardStats({
    required this.sentSignals,
    required this.matches,
    required this.chatRooms,
    required this.confessions,
    required this.moments,
    required this.marketPosts,
    required this.role,
  });

  factory _UserDashboardStats.empty() {
    return const _UserDashboardStats(
      sentSignals: 0,
      matches: 0,
      chatRooms: 0,
      confessions: 0,
      moments: 0,
      marketPosts: 0,
      role: 'student',
    );
  }
}
