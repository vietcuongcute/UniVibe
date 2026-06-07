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
