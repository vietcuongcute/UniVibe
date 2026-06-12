import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../services/user_profile_service.dart';
import 'admin_dashboard_screen.dart';
import 'create_profile_screen.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _getStartScreen(User user) async {
    final hasProfile = await UserProfileService.hasProfile();

    if (!hasProfile) {
      return const CreateProfileScreen();
    }

    final blocked = await AdminService.isCurrentUserBlocked();

    if (blocked) {
      await FirebaseAuth.instance.signOut();
      return const BlockedAccountScreen();
    }

    final role = await AdminService.getCurrentRole();

    debugPrint('CURRENT UID: ${user.uid}');
    debugPrint('CURRENT ROLE: $role');

    if (role == 'admin' || role == 'moderator') {
      return const AdminDashboardScreen();
    }

    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const WelcomeScreen();
        }

        return FutureBuilder<Widget>(
          future: _getStartScreen(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (profileSnapshot.hasError) {
              return Scaffold(
                backgroundColor: const Color(0xFFF7F3FF),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Lỗi kiểm tra tài khoản: ${profileSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            return profileSnapshot.data ?? const WelcomeScreen();
          },
        );
      },
    );
  }
}

class BlockedAccountScreen extends StatelessWidget {
  const BlockedAccountScreen({super.key});

  static const Color _primary = Color(0xFF7B61FF);
  static const Color _darkText = Color(0xFF2D1B69);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            width: 430,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(
                    Icons.block_rounded,
                    color: Color(0xFFE53935),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tài khoản đã bị khóa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tài khoản của bạn đã bị admin khóa do vi phạm quy định UniVibe. Vui lòng liên hệ quản trị viên nếu cần hỗ trợ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.45),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Quay lại đăng nhập'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F3FF),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF7B61FF))),
    );
  }
}
