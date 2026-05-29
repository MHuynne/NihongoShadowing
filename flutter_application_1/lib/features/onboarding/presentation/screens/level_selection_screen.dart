import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/core/services/user_prefs_service.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';

/// Màn hình chọn cấp độ JLPT — hiện ra ngay sau lần đăng nhập đầu tiên.
class LevelSelectionScreen extends StatefulWidget {
  /// Nếu [isChanging] = true, hiển thị nút Back để quay lại (chỉnh sửa từ Profile).
  final bool isChanging;

  const LevelSelectionScreen({super.key, this.isChanging = false});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen>
    with TickerProviderStateMixin {
  String? _selectedLevel;
  bool _isSaving = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static const _toriiRed = Color(0xFFBC2428);

  // Thông tin các cấp độ
  static const _levels = [
    _LevelInfo(
      code: 'N5',
      label: 'N5 — Người mới bắt đầu',
      description: 'Hiểu và sử dụng được các cấu trúc cơ bản của tiếng Nhật trong cuộc sống hằng ngày.',
      keywords: ['Hiragana & Katakana', '800 từ vựng', '100 Kanji cơ bản'],
      emoji: '🌱',
      color: Color(0xFF4CAF50),
      gradient: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
    ),
    _LevelInfo(
      code: 'N4',
      label: 'N4 — Cơ bản',
      description: 'Có thể hiểu nội dung giao tiếp cơ bản trong các tình huống quen thuộc.',
      keywords: ['1.500 từ vựng', '300 Kanji', 'Ngữ pháp cơ bản'],
      emoji: '🌸',
      color: Color(0xFF2196F3),
      gradient: [Color(0xFFE3F2FD), Color(0xFFEDE7F6)],
    ),
    _LevelInfo(
      code: 'N3',
      label: 'N3 — Trung cấp',
      description: 'Hiểu được tiếng Nhật trong nhiều tình huống hằng ngày ở mức độ nhất định.',
      keywords: ['3.750 từ vựng', '650 Kanji', 'Ngữ pháp nâng cao'],
      emoji: '🗾',
      color: Color(0xFFFF9800),
      gradient: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
    ),
    _LevelInfo(
      code: 'N2',
      label: 'N2 — Cao cấp',
      description: 'Hiểu tiếng Nhật trong các tình huống đa dạng, có thể đọc hiểu các bài báo, tạp chí.',
      keywords: ['6.000 từ vựng', '1.000 Kanji', 'Giao tiếp lưu loát'],
      emoji: '🗻',
      color: Color(0xFF9C27B0),
      gradient: [Color(0xFFF3E5F5), Color(0xFFF8BBD0)],
    ),
    _LevelInfo(
      code: 'N1',
      label: 'N1 — Chuyên sâu',
      description: 'Hiểu tiếng Nhật trong mọi hoàn cảnh, đọc hiểu các bài viết phức tạp về mặt logic.',
      keywords: ['10.000 từ vựng', '2.000 Kanji', 'Tiếng Nhật bản xứ'],
      emoji: '🐉',
      color: Color(0xFFE91E63),
      gradient: [Color(0xFFFCE4EC), Color(0xFFFFCDD2)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Nếu đang thay đổi, load level hiện tại để pre-select
    if (widget.isChanging) _loadCurrentLevel();
  }

  Future<void> _loadCurrentLevel() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final level = await UserPrefsService().getLevel(uid);
    if (mounted && level != null) setState(() => _selectedLevel = level);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedLevel == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    await UserPrefsService().saveLevel(uid, _selectedLevel!);

    if (!mounted) return;

    if (widget.isChanging) {
      // Quay lại màn hình trước (Profile)
      Navigator.of(context).pop(_selectedLevel);
    } else {
      // Lần đầu chọn → vào MainScreen, xoá hết stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      ..._levels.map((lvl) => _LevelCard(
                            info: lvl,
                            isSelected: _selectedLevel == lvl.code,
                            onTap: () => setState(() => _selectedLevel = lvl.code),
                          )),
                      const SizedBox(height: 8),
                      _buildConfirmButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isChanging)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: _toriiRed, size: 18),
              ),
            ),
          if (widget.isChanging) const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAEB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('🎌', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isChanging ? 'Thay đổi cấp độ' : 'Bạn đang ở đâu?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.isChanging
                          ? 'Chọn lại cấp độ JLPT phù hợp với bạn'
                          : 'Chọn trình độ để chúng tôi cá nhân hoá lộ trình học của bạn',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
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

  // ── Confirm button ──────────────────────────────────────────────────────────

  Widget _buildConfirmButton() {
    final isEnabled = _selectedLevel != null && !_isSaving;
    return AnimatedOpacity(
      opacity: _selectedLevel != null ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isEnabled ? _confirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _toriiRed,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _toriiRed,
            disabledForegroundColor: Colors.white,
            elevation: 4,
            shadowColor: _toriiRed.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedLevel != null
                          ? 'Xác nhận — Cấp độ $_selectedLevel'
                          : 'Chọn cấp độ của bạn',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    if (_selectedLevel != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Level Card ──────────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final _LevelInfo info;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelCard({
    required this.info,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      info.color.withValues(alpha: 0.15),
                      info.color.withValues(alpha: 0.05),
                    ]
                  : info.gradient,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? info.color : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? info.color.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: isSelected ? 20 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Emoji badge ──────────────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected ? info.color.withValues(alpha: 0.18) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: info.color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(info.emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),

              // ── Content ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? info.color : info.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            info.code,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : info.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            info.label.replaceFirst('${info.code} — ', ''),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? info.color : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        // Check icon
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isSelected
                              ? Container(
                                  key: const ValueKey('check'),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: info.color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                                )
                              : Container(
                                  key: const ValueKey('uncheck'),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Keywords chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: info.keywords
                          .map(
                            (kw) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? info.color.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? info.color.withValues(alpha: 0.3)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                kw,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? info.color : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data class ──────────────────────────────────────────────────────────────────

class _LevelInfo {
  final String code;
  final String label;
  final String description;
  final List<String> keywords;
  final String emoji;
  final Color color;
  final List<Color> gradient;

  const _LevelInfo({
    required this.code,
    required this.label,
    required this.description,
    required this.keywords,
    required this.emoji,
    required this.color,
    required this.gradient,
  });
}
