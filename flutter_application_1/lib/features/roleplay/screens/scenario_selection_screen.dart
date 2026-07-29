import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';
import 'roleplay_history_screen.dart';
import 'roleplay_chat_screen.dart';

class ScenarioSelectionScreen extends StatefulWidget {
  const ScenarioSelectionScreen({super.key});

  @override
  State<ScenarioSelectionScreen> createState() =>
      _ScenarioSelectionScreenState();
}

class _ScenarioSelectionScreenState extends State<ScenarioSelectionScreen> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  String _selectedMode = 'keigo';
  bool _isAutoStarting = false;

  @override
  void dispose() {
    _targetController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _resetSetupForm() {
    setState(() {
      _targetController.clear();
      _contextController.clear();
      _selectedMode = 'keigo';
    });
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleplayHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: SNJ.bgDeep.withOpacity(0.4),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Thiết lập Roleplay',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Lịch sử chat',
            icon: const Icon(Icons.history_rounded, color: SNJ.sakura),
            onPressed: _openHistory,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: SNJ.border, height: 1),
        ),
      ),
      body: SakuraNightBackground(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kịch bản nhanh (Tự động kích hoạt ⚡):',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: SNJ.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal quick action glass cards
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickScenarioCard(
                          title: 'Phỏng vấn xin việc',
                          description: 'Phỏng vấn thử việc bằng tiếng Nhật',
                          target: 'Nhà tuyển dụng',
                          contextText: 'Phỏng vấn xin việc vào công ty IT ở Tokyo',
                          mode: 'keigo',
                          emoji: '💼',
                          color: const Color(0xFF4CAF50),
                        ),
                        _buildQuickScenarioCard(
                          title: 'Rủ sếp đi nhậu',
                          description: 'Rủ đi Izakaya sau giờ làm việc',
                          target: 'Trưởng phòng (Sếp)',
                          contextText: 'Rủ sếp đi uống bia sau giờ làm việc căng thẳng',
                          mode: 'keigo',
                          emoji: '🍻',
                          color: const Color(0xFFFF9800),
                        ),
                        _buildQuickScenarioCard(
                          title: 'Hỏi đường ga Shinjuku',
                          description: 'Hỏi đường đi đến ga tàu điện ngầm',
                          target: 'Người qua đường',
                          contextText: 'Hỏi đường đi đến ga tàu điện ngầm Shinjuku ở Tokyo',
                          mode: 'keigo',
                          emoji: '🗺️',
                          color: const Color(0xFF2196F3),
                        ),
                        _buildQuickScenarioCard(
                          title: 'Tán gẫu bạn bè',
                          description: 'Trò chuyện thân mật về kỳ nghỉ hè',
                          target: 'Bạn thân',
                          contextText: 'Bàn kế hoạch đi chơi biển vào mùa hè này',
                          mode: 'plain',
                          emoji: '🎒',
                          color: const Color(0xFFFF6B9D),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: SNJ.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'HOẶC',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: SNJ.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: SNJ.border)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Tự thiết lập bối cảnh:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildFormLabel('1. Bạn đang nói chuyện với ai?'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _targetController,
                    hint: 'VD: Trưởng phòng, Bạn cùng lớp, Bố mẹ...',
                    maxLines: 1,
                  ),
                  const SizedBox(height: 20),

                  _buildFormLabel('2. Trong hoàn cảnh nào?'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _contextController,
                    hint: 'VD: Xin nghỉ phép, Nhờ vả công việc, Rủ đi ăn...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  _buildFormLabel('3. Mối quan hệ giữa hai người?'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModeOption('Thân thiết', 'plain', Icons.face_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModeOption('Lịch sự / Kính ngữ', 'keigo', Icons.business_center_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Start button
                  _AnimatedPress(
                    onTap: _startRoleplay,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: SNJ.sakuraGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: SNJ.sakura.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'BẮT ĐẦU LUYỆN TẬP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            if (_isAutoStarting)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: GlassCard(
                    neonBorder: true,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: SNJ.sakura),
                        const SizedBox(height: 20),
                        Text(
                          'Đang tự động khởi chạy kịch bản...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickScenarioCard({
    required String title,
    required String description,
    required String target,
    required String contextText,
    required String mode,
    required String emoji,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 14),
      width: 170,
      height: 160,
      child: _AnimatedPress(
        onTap: () async {
          setState(() {
            _targetController.text = target;
            _contextController.text = contextText;
            _selectedMode = mode;
            _isAutoStarting = true;
          });
          // Small delay for satisfying animation
          await Future.delayed(const Duration(milliseconds: 700));
          if (mounted) {
            setState(() => _isAutoStarting = false);
            _startRoleplay();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SNJ.border, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3), width: 0.8),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      mode == 'keigo' ? 'Kính ngữ' : 'Tán gẫu',
                      style: const TextStyle(fontSize: 8.5, color: SNJ.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SNJ.textSecondary,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: SNJ.textSecondary,
        fontSize: 14,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: SNJ.textMuted),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SNJ.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SNJ.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SNJ.sakura, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildModeOption(String label, String mode, IconData icon) {
    final isSelected = _selectedMode == mode;
    return _AnimatedPress(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? SNJ.sakura.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? SNJ.sakura : SNJ.border,
            width: isSelected ? 2.0 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SNJ.sakura.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? SNJ.sakura : SNJ.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : SNJ.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRoleplay() async {
    if (_targetController.text.isEmpty || _contextController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ thông tin!')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoleplayChatScreen(
          title: 'Nói chuyện với ${_targetController.text}',
          description: _contextController.text,
          mode: _selectedMode,
        ),
      ),
    );

    if (mounted) {
      _resetSetupForm();
    }
  }
}

// Custom Micro-Interaction Button Scale feedback wrapper
class _AnimatedPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _AnimatedPress({required this.child, this.onTap});

  @override
  State<_AnimatedPress> createState() => _AnimatedPressState();
}

class _AnimatedPressState extends State<_AnimatedPress>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.08,
    )..addListener(() {
        setState(() {
          _scale = 1.0 - _controller.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onTap != null ? _controller.forward() : null,
      onTapUp: (_) {
        if (widget.onTap != null) {
          _controller.reverse();
          widget.onTap!();
        }
      },
      onTapCancel: () => widget.onTap != null ? _controller.reverse() : null,
      child: Transform.scale(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}