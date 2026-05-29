import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_gate.dart';
import '../services/chat_service.dart';

import 'vibe_tab.dart';
import 'confession_tab.dart';
import 'unimoment_tab.dart';
import 'market_tab.dart';
import 'chat_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    VibeTab(),
    ConfessionTab(),
    UniMomentTab(),
    MarketTab(),
    ChatTab(),
  ];

  final List<String> _titles = const [
    'Vibe',
    'Confession',
    'UniMoment',
    'Market',
    'Chat',
  ];

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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng xuất thất bại: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
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
              onPressed: () {
                Navigator.pop(dialogContext);
              },
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
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D1B69),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _showLogoutConfirmDialog,
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEDE7FF),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Vibe',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Confession',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'UniMoment',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
