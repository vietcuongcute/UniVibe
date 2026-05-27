import 'dart:async';

import 'package:flutter/material.dart';

import '../services/blind_chat_match_service.dart';
import 'chat_detail_screen.dart';

class BlindChatScreen extends StatefulWidget {
  const BlindChatScreen({super.key});

  @override
  State<BlindChatScreen> createState() => _BlindChatScreenState();
}

class _BlindChatScreenState extends State<BlindChatScreen> {
  bool _isFinding = false;
  bool _isWaiting = false;
  String _statusText = 'Sẵn sàng bóc túi mù?';
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _findBlindChat() async {
    if (_isFinding || _isWaiting) return;

    setState(() {
      _isFinding = true;
      _statusText = 'Đang tìm người phù hợp...';
    });

    final result = await BlindChatMatchService.startMatching();

    if (!mounted) return;

    if (result.success && result.chatRoomId != null) {
      setState(() {
        _isFinding = false;
        _isWaiting = false;
        _statusText = result.message;
      });

      await BlindChatMatchService.cleanupMyQueueAfterOpen();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(chatRoomId: result.chatRoomId!),
        ),
      );
      return;
    }

    if (result.success && result.waiting) {
      setState(() {
        _isFinding = false;
        _isWaiting = true;
        _statusText = result.message;
      });

      _startPolling();
      return;
    }

    setState(() {
      _isFinding = false;
      _isWaiting = false;
      _statusText = result.message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final result = await BlindChatMatchService.checkWaitingResult();

      if (!mounted) return;

      if (result.success && result.chatRoomId != null) {
        _pollTimer?.cancel();

        setState(() {
          _isFinding = false;
          _isWaiting = false;
          _statusText = result.message;
        });

        await BlindChatMatchService.cleanupMyQueueAfterOpen();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chatRoomId: result.chatRoomId!),
          ),
        );
        return;
      }

      if (result.success && result.waiting) {
        setState(() {
          _statusText = result.message;
        });
        return;
      }

      setState(() {
        _isFinding = false;
        _isWaiting = false;
        _statusText = result.message;
      });
    });
  }

  Future<void> _cancelWaiting() async {
    _pollTimer?.cancel();

    final result = await BlindChatMatchService.cancelWaiting();

    if (!mounted) return;

    setState(() {
      _isFinding = false;
      _isWaiting = false;
      _statusText = 'Sẵn sàng bóc túi mù?';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: const Text(
          'Blind Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D1B69),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 18),
            _buildStatusCard(),
            const SizedBox(height: 18),
            _buildActionButton(),
            const SizedBox(height: 14),
            if (_isWaiting) _buildCancelButton(),
            const SizedBox(height: 24),
            _buildRulesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_off_rounded, color: Colors.white, size: 48),
          SizedBox(height: 18),
          Text(
            'Bóc túi mù UniVibe',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ghép ngẫu nhiên với một sinh viên trong trường. Chat trước, reveal sau.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: _isFinding || _isWaiting
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFE91E63),
                    ),
                  )
                : const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFE91E63),
                    size: 28,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _statusText,
              style: const TextStyle(
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D1B69),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isFinding || _isWaiting ? null : _findBlindChat,
        icon: const Icon(Icons.shuffle_rounded),
        label: Text(
          _isFinding
              ? 'Đang tìm...'
              : _isWaiting
              ? 'Đang chờ...'
              : 'Tìm Blind Chat mới',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _cancelWaiting,
        icon: const Icon(Icons.close_rounded),
        label: const Text('Huỷ chờ'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE91E63),
          side: const BorderSide(color: Color(0xFFE91E63)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Luật chơi bản dev',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B69),
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Mỗi lần tìm là một blind chat mới.\n'
            '• Không dùng lại phòng blind chat cũ.\n'
            '• Account đầu bấm tìm sẽ vào hàng chờ.\n'
            '• Account thứ hai bấm tìm sẽ tạo phòng chat mới.\n'
            '• Người đang chờ sẽ tự mở phòng khi được ghép.\n'
            '• Tin nhắn dùng chung hệ thống chat realtime hiện tại.',
            style: TextStyle(color: Colors.black54, height: 1.45),
          ),
        ],
      ),
    );
  }
}
