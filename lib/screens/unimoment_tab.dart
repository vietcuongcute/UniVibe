import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/moment_service.dart';

class UniMomentTab extends StatefulWidget {
  const UniMomentTab({super.key});

  @override
  State<UniMomentTab> createState() => _UniMomentTabState();
}

class _UniMomentTabState extends State<UniMomentTab> {
  static const List<String> _audiences = [
    'campus',
    'department',
    'club',
    'event',
  ];

  static const List<String> _quickReactions = ['❤️', '😂', '🔥', '😮', '👏'];

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  XFile? _selectedImage;
  String _selectedAudience = _audiences.first;
  bool _isPosting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentUserId.isEmpty) {
      return _buildLoginRequiredState();
    }

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<FirestoreMoment>>(
              stream: MomentService.momentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6CAB)),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final moments = snapshot.data ?? [];

                if (moments.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  itemCount: moments.length,
                  itemBuilder: (context, index) {
                    final moment = moments[index];

                    return _buildMomentCard(
                      moment: moment,
                      currentUserId: currentUserId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6CAB), Color(0xFF7366FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'UniMoment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Đăng ảnh/story 24h kiểu Locket cho sinh viên cùng trường.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateMomentSheet,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Đăng UniMoment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF4F9A),
                padding: const EdgeInsets.symmetric(vertical: 13),
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

  Widget _buildMomentCard({
    required FirestoreMoment moment,
    required String currentUserId,
  }) {
    final myReaction = moment.myReaction(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMomentTopBar(moment),
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Image.network(
              moment.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;

                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6CAB)),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF7F3FF),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: Colors.grey,
                      size: 52,
                    ),
                  ),
                );
              },
            ),
          ),
          if (moment.caption.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Text(
                moment.caption,
                style: const TextStyle(
                  fontSize: 15.5,
                  height: 1.4,
                  color: Color(0xFF222222),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickReactions.map((emoji) {
                    final isSelected = myReaction == emoji;
                    final count = moment.reactions[emoji]?.length ?? 0;

                    return InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () async {
                        final result = await MomentService.toggleReaction(
                          momentId: moment.id,
                          emoji: emoji,
                        );

                        _showSnack(result);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF6CAB).withOpacity(0.16)
                              : const Color(0xFFF7F3FF),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF6CAB)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          count > 0 ? '$emoji $count' : emoji,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 17,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Còn ${_formatRemainingTime(moment.expiresAt)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.5,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showReportSheet(moment.id),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Report'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black45,
                      ),
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

  Widget _buildMomentTopBar(FirestoreMoment moment) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 21,
            backgroundColor: Color(0xFFFFE4F0),
            child: Icon(Icons.person_rounded, color: Color(0xFFFF4F9A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moment.authorNickname,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${moment.displayAudience} • ${_formatTime(moment.createdAt)}',
                  style: const TextStyle(color: Colors.black45, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateMomentSheet() {
    _captionController.clear();
    _selectedImage = null;
    _selectedAudience = _audiences.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Đăng UniMoment',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3FF),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedImage == null
                                  ? Icons.photo_camera_back_rounded
                                  : Icons.check_circle_rounded,
                              color: _selectedImage == null
                                  ? Colors.grey
                                  : const Color(0xFFFF4F9A),
                              size: 44,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedImage == null
                                  ? 'Chưa chọn ảnh'
                                  : 'Đã chọn: ${_selectedImage!.name}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final image = await _pickImage(
                                        ImageSource.gallery,
                                      );

                                      if (image == null) return;

                                      setSheetState(() {
                                        _selectedImage = image;
                                      });
                                    },
                                    icon: const Icon(Icons.image_rounded),
                                    label: const Text('Thư viện'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final image = await _pickImage(
                                        ImageSource.camera,
                                      );

                                      if (image == null) return;

                                      setSheetState(() {
                                        _selectedImage = image;
                                      });
                                    },
                                    icon: const Icon(Icons.camera_alt_rounded),
                                    label: const Text('Camera'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _captionController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Caption ngắn cho moment...',
                          filled: true,
                          fillColor: const Color(0xFFF7F3FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedAudience,
                        decoration: InputDecoration(
                          labelText: 'Moment cho',
                          filled: true,
                          fillColor: const Color(0xFFF7F3FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _audiences.map((audience) {
                          return DropdownMenuItem(
                            value: audience,
                            child: Text(_formatAudienceLabel(audience)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setSheetState(() {
                            _selectedAudience = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isPosting
                              ? null
                              : () async {
                                  if (_selectedImage == null) {
                                    _showSnack('Bạn cần chọn ảnh trước.');
                                    return;
                                  }

                                  setSheetState(() {
                                    _isPosting = true;
                                  });

                                  final result =
                                      await MomentService.createMoment(
                                        image: _selectedImage!,
                                        caption: _captionController.text,
                                        audience: _selectedAudience,
                                      );

                                  setSheetState(() {
                                    _isPosting = false;
                                  });

                                  if (!mounted) return;

                                  Navigator.pop(bottomSheetContext);
                                  _showSnack(result);
                                },
                          icon: _isPosting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_rounded),
                          label: Text(
                            _isPosting ? 'Đang đăng...' : 'Đăng moment',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4F9A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    });
  }

  Future<XFile?> _pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1280,
      );
    } catch (e) {
      _showSnack('Không chọn được ảnh: $e');
      return null;
    }
  }

  void _showReportSheet(String momentId) {
    final detailController = TextEditingController();
    String reason = 'Nội dung không phù hợp';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Report UniMoment',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: reason,
                      decoration: InputDecoration(
                        labelText: 'Lý do',
                        filled: true,
                        fillColor: const Color(0xFFF7F3FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Nội dung không phù hợp',
                          child: Text('Nội dung không phù hợp'),
                        ),
                        DropdownMenuItem(value: 'Spam', child: Text('Spam')),
                        DropdownMenuItem(
                          value: 'Quấy rối/công kích',
                          child: Text('Quấy rối/công kích'),
                        ),
                        DropdownMenuItem(
                          value: 'Ảnh riêng tư/nhạy cảm',
                          child: Text('Ảnh riêng tư/nhạy cảm'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          reason = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Mô tả thêm nếu cần...',
                        filled: true,
                        fillColor: const Color(0xFFF7F3FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await MomentService.reportMoment(
                            momentId: momentId,
                            reason: reason,
                            detail: detailController.text,
                          );

                          detailController.dispose();

                          if (!mounted) return;

                          Navigator.pop(bottomSheetContext);
                          _showSnack(result);
                        },
                        icon: const Icon(Icons.flag_rounded),
                        label: const Text('Gửi report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      detailController.dispose();
    });
  }

  Widget _buildLoginRequiredState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 54),
                SizedBox(height: 14),
                Text(
                  'Bạn chưa đăng nhập',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Đăng nhập để xem và đăng UniMoment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_camera_back_outlined,
                color: Colors.grey.shade400,
                size: 54,
              ),
              const SizedBox(height: 14),
              const Text(
                'Chưa có UniMoment',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bấm “Đăng UniMoment” để đăng story 24h đầu tiên.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.4),
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
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 54,
              ),
              const SizedBox(height: 14),
              const Text(
                'Không tải được UniMoment',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAudienceLabel(String audience) {
    switch (audience) {
      case 'department':
        return 'Theo khoa';
      case 'club':
        return 'CLB';
      case 'event':
        return 'Sự kiện';
      case 'campus':
      default:
        return 'Toàn trường';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'vừa xong';
    if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
    if (difference.inHours < 24) return '${difference.inHours} giờ trước';

    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
  }

  String _formatRemainingTime(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) return '0 phút';
    if (difference.inMinutes < 60) return '${difference.inMinutes} phút';
    return '${difference.inHours} giờ';
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
