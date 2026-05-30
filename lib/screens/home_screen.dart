import 'package:flutter/material.dart';

import 'account_tab.dart';
import 'chat_tab.dart';
import 'confession_tab.dart';
import 'market_tab.dart';
import 'unimoment_tab.dart';
import 'vibe_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primary = Color(0xFF7B61FF);
  static const Color _darkText = Color(0xFF2D1B69);
  static const Color _bg = Color(0xFFF7F3FF);
  static const Color _softPurple = Color(0xFFEDE7FF);

  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    VibeTab(),
    ConfessionTab(),
    UniMomentTab(),
    MarketTab(),
    ChatTab(),
    AccountTab(),
  ];

  final List<String> _titles = const [
    'Vibe',
    'Confession',
    'UniMoment',
    'Market',
    'Chat',
    'Tài khoản',
  ];

  final List<String> _subtitles = const [
    'Tìm người cùng vibe trong trường',
    'Góc chia sẻ nội bộ sinh viên',
    'Khoảnh khắc 24h của trường',
    'Mua bán đồ sinh viên',
    'Nhắn tin với người đã match',
    'Quản lý hồ sơ',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: _darkText,
      centerTitle: false,
      titleSpacing: 18,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titles[_currentIndex],
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: _darkText,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _subtitles[_currentIndex],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 74,
          selectedIndex: _currentIndex,
          backgroundColor: Colors.white,
          indicatorColor: _softPurple,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 250),
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded, color: _primary),
              label: 'Vibe',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded, color: _primary),
              label: 'Confession',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded, color: _primary),
              label: 'Moment',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded, color: _primary),
              label: 'Market',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded, color: _primary),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: _primary),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
