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
  static const Color _softPurple = Color(0xFFF1EAFF);
  static const Color _border = Color(0xFFEDE7FF);

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
      final status = userDoc.data()?['status']?.toString() ?? 'active';

      final results = await Future.wait<int>([
        _safeCount(db.collection('signals').where('senderId', isEqualTo: uid)),
        _safeCount(
          db.collection('signals').where('receiverId', isEqualTo: uid),
        ),
        _safeCount(
          db.collection('matches').where('userIds', arrayContains: uid),
        ),
        _safeCount(
          db.collection('chatRooms').where('userIds', arrayContains: uid),
        ),
        _safeCount(
          db.collection('confessions').where('authorId', isEqualTo: uid),
        ),
        _safeCount(db.collection('moments').where('authorId', isEqualTo: uid)),
        _safeCount(
          db.collection('marketPosts').where('sellerId', isEqualTo: uid),
        ),
      ]);

      return _UserDashboardStats(
        sentSignals: results[0],
        receivedSignals: results[1],
        matches: results[2],
        chatRooms: results[3],
        confessions: results[4],
        moments: results[5],
        marketPosts: results[6],
        role: role,
        status: status,
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

  void _goTo(int index) {
    widget.onNavigate?.call(index);
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
            style: TextStyle(fontWeight: FontWeight.w900),
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
      text: profile.interests.map((e) => e.toString()).join(', '),
    );
    final goalsController = TextEditingController(
      text: profile.goals.map((e) => e.toString()).join(', '),
    );
    final vibeTagsController = TextEditingController(
      text: profile.vibeTags.map((e) => e.toString()).join(', '),
    );

    int selectedYear = profile.year <= 0 ? 1 : profile.year;
    String selectedGender = profile.gender.trim().isEmpty
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
                    'status': 'active',
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
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogSectionTitle(
                        icon: Icons.account_circle_rounded,
                        title: 'Thông tin cơ bản',
                      ),
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
                        icon: Icons.favorite_rounded,
                        title: 'Sở thích',
                      ),
                      _buildDialogTextField(
                        controller: interestsController,
                        label: 'Ví dụ: game, cà phê, học nhóm',
                        icon: Icons.interests_rounded,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      _buildDialogSectionTitle(
                        icon: Icons.flag_rounded,
                        title: 'Mục tiêu',
                      ),
                      _buildDialogTextField(
                        controller: goalsController,
                        label: 'Ví dụ: tìm bạn học, tìm teammate',
                        icon: Icons.rocket_launch_rounded,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      _buildDialogSectionTitle(
                        icon: Icons.local_fire_department_rounded,
                        title: 'Vibe tags',
                      ),
                      _buildDialogTextField(
                        controller: vibeTagsController,
                        label: 'Ví dụ: chill, hướng nội, năng động',
                        icon: Icons.auto_awesome_rounded,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
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
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  Widget _buildDialogSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _softDeleteMyDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .update({
            'status': 'deleted',
            'deletedAt': FieldValue.serverTimestamp(),
            'deletedBy': FirebaseAuth.instance.currentUser?.uid,
          });

      _showMessage('Đã xóa bài khỏi tài khoản của bạn');
    } catch (e) {
      _showMessage('Xóa thất bại: $e');
    }
  }

  Future<void> _markMarketSold(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('marketPosts')
          .doc(docId)
          .update({
            'status': 'sold',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _showMessage('Đã đánh dấu bài Market là đã bán');
    } catch (e) {
      _showMessage('Cập nhật thất bại: $e');
    }
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
              child: ListView(
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

                      return Column(
                        children: [
                          if (stats.status == 'blocked') ...[
                            _buildBlockedWarning(),
                            const SizedBox(height: 18),
                          ],
                          _buildStatsSection(stats),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildQuickActions(profile),
                  const SizedBox(height: 18),
                  _buildProfileInfoSection(profile),
                  const SizedBox(height: 18),
                  _buildMyActivitySection(),
                  const SizedBox(height: 18),
                  _buildTagSection(
                    title: 'Mục tiêu',
                    icon: Icons.flag_rounded,
                    items: profile.goals,
                    emptyText:
                        'Chưa cập nhật mục tiêu. Ví dụ: tìm bạn học, tìm teammate, tìm người cùng vibe.',
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
                  const SizedBox(height: 18),
                  _buildAccountSettingsSection(),
                ],
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
      decoration: _cardDecoration(radius: 30),
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
                                fontWeight: FontWeight.w800,
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
                        backgroundColor: _softPurple,
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

  Widget _buildBlockedWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.block_rounded, color: Color(0xFFE53935)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tài khoản của bạn đang bị khóa. Bạn có thể xem một số thông tin, nhưng không thể đăng bài, gửi signal hoặc nhắn tin cho tới khi admin mở khóa.',
              style: TextStyle(
                color: Color(0xFF9F1D1D),
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusPill(stats.status),
          const SizedBox(width: 8),
          _buildRolePill(stats.role),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 760 ? 7 : 3;

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth >= 760 ? 1.05 : 1.05,
            children: [
              _buildStatTile(
                icon: Icons.north_east_rounded,
                label: 'Đã gửi',
                value: stats.sentSignals,
              ),
              _buildStatTile(
                icon: Icons.south_west_rounded,
                label: 'Nhận',
                value: stats.receivedSignals,
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
        border: Border.all(color: _border),
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
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
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
                  icon: Icons.favorite_rounded,
                  label: 'Tìm vibe',
                  color: _pink,
                  onTap: () => _goTo(0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.forum_rounded,
                  label: 'Confession',
                  color: const Color(0xFF8E2DE2),
                  onTap: () => _goTo(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'UniMoment',
                  color: const Color(0xFF00A6A6),
                  onTap: () => _goTo(2),
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
                  label: 'Market',
                  color: const Color(0xFFFF8A00),
                  onTap: () => _goTo(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  color: const Color(0xFF18A058),
                  onTap: () => _goTo(4),
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
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoSection(UserProfile profile) {
    return _buildSectionCard(
      title: 'Hồ sơ của tôi',
      icon: Icons.account_circle_rounded,
      trailing: TextButton.icon(
        onPressed: () => _showEditProfileDialog(profile),
        icon: const Icon(Icons.edit_rounded, size: 17),
        label: const Text('Sửa'),
      ),
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
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Text(
              profile.bio.isEmpty
                  ? 'Chưa có bio. Hãy viết vài dòng để người khác hiểu vibe của bạn hơn.'
                  : profile.bio,
              style: const TextStyle(color: Colors.black87, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyActivitySection() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      return _buildSectionCard(
        title: 'Hoạt động của tôi',
        icon: Icons.dashboard_customize_rounded,
        child: const Text(
          'Bạn chưa đăng nhập.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return _buildSectionCard(
      title: 'Hoạt động của tôi',
      icon: Icons.dashboard_customize_rounded,
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: _primary,
                unselectedLabelColor: Colors.black54,
                indicatorColor: _primary,
                tabs: [
                  Tab(text: 'Confession'),
                  Tab(text: 'Market'),
                  Tab(text: 'Moment'),
                  Tab(text: 'Signal'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 360,
              child: TabBarView(
                children: [
                  _buildMyDocsList(
                    query: FirebaseFirestore.instance
                        .collection('confessions')
                        .where('authorId', isEqualTo: uid),
                    emptyIcon: Icons.forum_outlined,
                    emptyText: 'Bạn chưa đăng confession nào.',
                    collectionName: 'confessions',
                    type: _MyDocType.confession,
                  ),
                  _buildMyDocsList(
                    query: FirebaseFirestore.instance
                        .collection('marketPosts')
                        .where('sellerId', isEqualTo: uid),
                    emptyIcon: Icons.storefront_outlined,
                    emptyText: 'Bạn chưa đăng bài Market nào.',
                    collectionName: 'marketPosts',
                    type: _MyDocType.market,
                  ),
                  _buildMyDocsList(
                    query: FirebaseFirestore.instance
                        .collection('moments')
                        .where('authorId', isEqualTo: uid),
                    emptyIcon: Icons.auto_awesome_outlined,
                    emptyText: 'Bạn chưa đăng UniMoment nào.',
                    collectionName: 'moments',
                    type: _MyDocType.moment,
                  ),
                  _buildSignalList(uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyDocsList({
    required Query<Map<String, dynamic>> query,
    required IconData emptyIcon,
    required String emptyText,
    required String collectionName,
    required _MyDocType type,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }

        if (snapshot.hasError) {
          return _buildInlineError(snapshot.error.toString());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildInlineEmpty(icon: emptyIcon, text: emptyText);
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            return _buildMyDocTile(
              docId: doc.id,
              data: data,
              collectionName: collectionName,
              type: type,
            );
          },
        );
      },
    );
  }

  Widget _buildMyDocTile({
    required String docId,
    required Map<String, dynamic> data,
    required String collectionName,
    required _MyDocType type,
  }) {
    final title = _getDocTitle(data, type);
    final content = _getDocContent(data, type);
    final status = data['status']?.toString() ?? 'active';
    final createdAt = _formatTimestamp(data['createdAt']);

    IconData icon;
    Color color;

    switch (type) {
      case _MyDocType.confession:
        icon = Icons.forum_rounded;
        color = const Color(0xFF8E2DE2);
        break;
      case _MyDocType.market:
        icon = Icons.storefront_rounded;
        color = const Color(0xFFFF8A00);
        break;
      case _MyDocType.moment:
        icon = Icons.auto_awesome_rounded;
        color = _pink;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSmallIcon(icon: icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              _buildSmallStatus(status),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, height: 1.35),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  createdAt,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (type == _MyDocType.market)
                TextButton(
                  onPressed: () => _markMarketSold(docId),
                  child: const Text('Đã bán'),
                ),
              TextButton(
                onPressed: () => _softDeleteMyDocument(
                  collection: collectionName,
                  docId: docId,
                ),
                child: const Text(
                  'Xóa',
                  style: TextStyle(color: Color(0xFFE53935)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalList(String uid) {
    final query = FirebaseFirestore.instance
        .collection('signals')
        .where('senderId', isEqualTo: uid);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }

        if (snapshot.hasError) {
          return _buildInlineError(snapshot.error.toString());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildInlineEmpty(
            icon: Icons.send_outlined,
            text: 'Bạn chưa gửi signal nào.',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data();

            final receiverId = data['receiverId']?.toString() ?? 'Không rõ';
            final status = data['status']?.toString() ?? 'pending';
            final createdAt = _formatTimestamp(data['createdAt']);

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  _buildSmallIcon(icon: Icons.send_rounded, color: _primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Signal đã gửi',
                          style: TextStyle(
                            color: _darkText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Người nhận: $receiverId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          createdAt,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSmallStatus(status),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getDocTitle(Map<String, dynamic> data, _MyDocType type) {
    switch (type) {
      case _MyDocType.confession:
        return data['title']?.toString().trim().isNotEmpty == true
            ? data['title'].toString()
            : 'Confession của tôi';
      case _MyDocType.market:
        return data['title']?.toString().trim().isNotEmpty == true
            ? data['title'].toString()
            : 'Bài Market của tôi';
      case _MyDocType.moment:
        return data['caption']?.toString().trim().isNotEmpty == true
            ? data['caption'].toString()
            : 'UniMoment của tôi';
    }
  }

  String _getDocContent(Map<String, dynamic> data, _MyDocType type) {
    switch (type) {
      case _MyDocType.confession:
        return data['content']?.toString() ??
            data['text']?.toString() ??
            data['body']?.toString() ??
            '';
      case _MyDocType.market:
        final description = data['description']?.toString() ?? '';
        final price = data['price'];
        if (price == null || price.toString().isEmpty) {
          return description;
        }
        return '$description\nGiá: $price';
      case _MyDocType.moment:
        return data['caption']?.toString() ??
            data['content']?.toString() ??
            data['text']?.toString() ??
            '';
    }
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
                    color: _softPurple,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    item.toString(),
                    style: const TextStyle(
                      color: _darkText,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
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
                border: Border.all(color: _border),
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
                final imageUrl = profile.featuredImageUrls[index].toString();

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: _softPurple,
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

  Widget _buildAccountSettingsSection() {
    return _buildSectionCard(
      title: 'Cài đặt tài khoản',
      icon: Icons.settings_rounded,
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.refresh_rounded,
            title: 'Tải lại dữ liệu',
            subtitle: 'Làm mới hồ sơ, thống kê và hoạt động',
            color: _primary,
            onTap: _reloadData,
          ),
          const SizedBox(height: 10),
          _buildSettingTile(
            icon: Icons.image_rounded,
            title: 'Upload ảnh',
            subtitle: 'Sẽ bật sau khi cấu hình Firebase Storage',
            color: const Color(0xFFFF8A00),
            onTap: _showStorageLaterMessage,
          ),
          const SizedBox(height: 10),
          _buildSettingTile(
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            subtitle: 'Thoát khỏi tài khoản hiện tại',
            color: const Color(0xFFE53935),
            onTap: _showLogoutConfirmDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            _buildSmallIcon(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
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
              _buildSmallIcon(icon: icon, color: _primary),
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
          _buildSmallIcon(icon: icon, color: _primary),
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
        color: _bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
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
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIcon({required IconData icon, required Color color}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildRolePill(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _softPurple,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _formatRole(role),
        style: const TextStyle(
          color: _primary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final isBlocked = status == 'blocked';
    final color = isBlocked ? const Color(0xFFE53935) : const Color(0xFF18A058);
    final text = isBlocked ? 'Blocked' : 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSmallStatus(String status) {
    Color color;
    String text;

    switch (status) {
      case 'active':
        color = const Color(0xFF18A058);
        text = 'active';
        break;
      case 'sold':
        color = const Color(0xFFFF8A00);
        text = 'sold';
        break;
      case 'hidden':
        color = const Color(0xFF8E2DE2);
        text = 'hidden';
        break;
      case 'deleted':
        color = const Color(0xFFE53935);
        text = 'deleted';
        break;
      case 'matched':
        color = _pink;
        text = 'matched';
        break;
      case 'pending':
      default:
        color = _primary;
        text = status.isEmpty ? 'pending' : status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildInlineEmpty({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _primary, size: 38),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Text(
        'Không tải được dữ liệu: $error',
        style: const TextStyle(
          color: Color(0xFFE53935),
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
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
                backgroundColor: _softPurple,
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
                  fontWeight: FontWeight.w900,
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
                  fontWeight: FontWeight.w900,
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

  BoxDecoration _cardDecoration({double radius = 26}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.purple.withOpacity(0.07),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
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

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${_two(date.day)}/${_two(date.month)}/${date.year} ${_two(date.hour)}:${_two(date.minute)}';
    }

    return 'Chưa rõ thời gian';
  }

  String _two(int value) {
    return value.toString().padLeft(2, '0');
  }
}

enum _MyDocType { confession, market, moment }

class _UserDashboardStats {
  final int sentSignals;
  final int receivedSignals;
  final int matches;
  final int chatRooms;
  final int confessions;
  final int moments;
  final int marketPosts;
  final String role;
  final String status;

  const _UserDashboardStats({
    required this.sentSignals,
    required this.receivedSignals,
    required this.matches,
    required this.chatRooms,
    required this.confessions,
    required this.moments,
    required this.marketPosts,
    required this.role,
    required this.status,
  });

  factory _UserDashboardStats.empty() {
    return const _UserDashboardStats(
      sentSignals: 0,
      receivedSignals: 0,
      matches: 0,
      chatRooms: 0,
      confessions: 0,
      moments: 0,
      marketPosts: 0,
      role: 'student',
      status: 'active',
    );
  }
}
