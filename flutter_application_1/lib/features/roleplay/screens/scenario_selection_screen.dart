import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
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
    final textColor = AppColors.primaryText(context);
    final sectionColor = AppColors.secondaryText(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        title: const Text('Thiết lập Roleplay'),
        actions: [
          IconButton(
            tooltip: 'Lịch sử chat',
            icon: const Icon(Icons.history_rounded),
            onPressed: _openHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn kịch bản nhanh:',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: sectionColor),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction(
                      'Phỏng vấn', Icons.work, 'Sếp/Nhà tuyển dụng', 'keigo'),
                  _buildQuickAction(
                      'Đi nhậu', Icons.local_bar, 'Bạn thân', 'plain'),
                  _buildQuickAction(
                      'Hỏi đường', Icons.map, 'Người lạ', 'keigo'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Divider(color: AppColors.divider(context)),
            const SizedBox(height: 20),
            Text(
              'Tự thiết lập bối cảnh:',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 20),
            Text(
              '1. Bạn đang nói chuyện với ai?',
              style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _targetController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'VD: Trưởng phòng, Bạn cùng lớp, Bố mẹ...',
                hintStyle: TextStyle(color: AppColors.tertiaryText(context)),
                filled: true,
                fillColor: AppColors.inputFill(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '2. Trong hoàn cảnh nào?',
              style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contextController,
              maxLines: 2,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'VD: Xin nghỉ phép, Nhờ vả công việc, Rủ đi ăn...',
                hintStyle: TextStyle(color: AppColors.tertiaryText(context)),
                filled: true,
                fillColor: AppColors.inputFill(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '3. Mối quan hệ giữa hai người?',
              style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildModeOption(
                      context, 'Thân thiết', 'plain', Icons.face),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeOption(context, 'Lịch sự / Kính ngữ',
                      'keigo', Icons.business_center),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _startRoleplay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: const Text(
                  'BẮT ĐẦU LUYỆN TẬP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(
      BuildContext context, String label, String mode, IconData icon) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.softAccentSurface(context, AppColors.primary)
              : AppColors.inputFill(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.secondaryText(context),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primaryText(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
      String label, IconData icon, String target, String mode) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: () {
          _targetController.text = target;
          setState(() => _selectedMode = mode);
        },
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
