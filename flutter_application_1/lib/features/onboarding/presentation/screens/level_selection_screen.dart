import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/core/services/user_prefs_service.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';
import 'package:flutter_application_1/features/home/presentation/screens/main_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
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

  static const _levels = [
    _LevelInfo(
      code: 'N5',
      label: 'N5 — Người mới bắt đầu',
      description: 'Hiểu và sử dụng được các cấu trúc cơ bản của tiếng Nhật trong cuộc sống hằng ngày.',
      keywords: ['Hiragana & Katakana', '800 từ vựng', '100 Kanji cơ bản'],
      emoji: '🌱',
      color: Color(0xFF4CAF50),
    ),
    _LevelInfo(
      code: 'N4',
      label: 'N4 — Cơ bản',
      description: 'Có thể hiểu nội dung giao tiếp cơ bản trong các tình huống quen thuộc.',
      keywords: ['1.500 từ vựng', '300 Kanji', 'Ngữ pháp cơ bản'],
      emoji: '🌸',
      color: Color(0xFFFF6B9D),
    ),
    _LevelInfo(
      code: 'N3',
      label: 'N3 — Trung cấp',
      description: 'Hiểu được tiếng Nhật trong nhiều tình huống hằng ngày ở mức độ nhất định.',
      keywords: ['3.750 từ vựng', '650 Kanji', 'Ngữ pháp nâng cao'],
      emoji: '🗾',
      color: Color(0xFFFF9800),
    ),
    _LevelInfo(
      code: 'N2',
      label: 'N2 — Cao cấp',
      description: 'Hiểu tiếng Nhật trong các tình huống đa dạng, có thể đọc hiểu các bài báo, tạp chí.',
      keywords: ['6.000 từ vựng', '1.000 Kanji', 'Giao tiếp lưu loát'],
      emoji: '🗻',
      color: Color(0xFF9C27B0),
    ),
    _LevelInfo(
      code: 'N1',
      label: 'N1 — Chuyên sâu',
      description: 'Hiểu tiếng Nhật trong mọi hoàn cảnh, đọc hiểu các bài viết phức tạp về mặt logic.',
      keywords: ['10.000 từ vựng', '2.000 Kanji', 'Tiếng Nhật bản xứ'],
      emoji: '🐉',
      color: Color(0xFFEF4444),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

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
      Navigator.of(context).pop(_selectedLevel);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SakuraNightBackground(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      children: [
                        ..._levels.map((lvl) => _LevelCard(
                              info: lvl,
                              isSelected: _selectedLevel == lvl.code,
                              onTap: () => setState(() => _selectedLevel = lvl.code),
                            )),
                        const SizedBox(height: 12),
                        _buildConfirmButton(),
                      ],
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: SNJ.bgDeep.withOpacity(0.4),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        border: const Border(
          bottom: BorderSide(color: SNJ.border, width: 0.8),
        ),
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
                  color: SNJ.sakuraSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SNJ.borderNeon, width: 0.8),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: SNJ.sakura, size: 18),
              ),
            ),
          if (widget.isChanging) const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SNJ.sakuraSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SNJ.borderNeon, width: 0.8),
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
                        color: SNJ.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isChanging
                          ? 'Chọn lại cấp độ JLPT phù hợp với bạn'
                          : 'Chọn trình độ để chúng tôi cá nhân hoá lộ trình học của bạn',
                      style: const TextStyle(
                        fontSize: 13,
                        color: SNJ.textSecondary,
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

  Widget _buildConfirmButton() {
    final isEnabled = _selectedLevel != null && !_isSaving;
    return AnimatedOpacity(
      opacity: _selectedLevel != null ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Container(
          decoration: BoxDecoration(
            gradient: isEnabled ? SNJ.sakuraGradient : null,
            color: isEnabled ? null : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: SNJ.sakura.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: isEnabled ? _confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: Colors.white.withOpacity(0.4),
              shadowColor: Colors.transparent,
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
      ),
    );
  }
}

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
            color: isSelected
                ? info.color.withOpacity(0.12)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? info.color : SNJ.border,
              width: isSelected ? 2.5 : 0.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: info.color.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? info.color.withOpacity(0.18)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? info.color.withOpacity(0.3) : SNJ.border,
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Text(info.emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? info.color : info.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            info.code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
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
                              color: isSelected ? info.color : SNJ.textPrimary,
                            ),
                          ),
                        ),
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
                                    border: Border.all(color: SNJ.border, width: 2),
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
                        color: SNJ.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: info.keywords
                          .map(
                            (kw) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? info.color.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? info.color.withOpacity(0.3)
                                      : SNJ.border,
                                ),
                              ),
                              child: Text(
                                kw,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : SNJ.textSecondary,
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

class _LevelInfo {
  final String code;
  final String label;
  final String description;
  final List<String> keywords;
  final String emoji;
  final Color color;

  const _LevelInfo({
    required this.code,
    required this.label,
    required this.description,
    required this.keywords,
    required this.emoji,
    required this.color,
  });
}