import 'package:flutter/material.dart';
import 'roleplay_chat_screen.dart';

class ScenarioSelectionScreen extends StatefulWidget {
  const ScenarioSelectionScreen({super.key});

  @override
  State<ScenarioSelectionScreen> createState() => _ScenarioSelectionScreenState();
}

class _ScenarioSelectionScreenState extends State<ScenarioSelectionScreen> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  String _selectedMode = 'keigo'; // 'keigo' cho công việc, 'plain' cho bạn bè

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập Roleplay'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn kịch bản nhanh:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction('Phỏng vấn', Icons.work, 'Sếp/Nhà tuyển dụng', 'keigo'),
                  _buildQuickAction('Đi nhậu', Icons.local_bar, 'Bạn thân', 'plain'),
                  _buildQuickAction('Hỏi đường', Icons.map, 'Người lạ', 'keigo'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Tự thiết lập bối cảnh:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('1. Bạn đang nói chuyện với ai?', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _targetController,
              decoration: InputDecoration(
                hintText: 'VD: Trưởng phòng, Bạn cùng lớp, Bố mẹ...',
                filled: true,
                fillColor: Colors.blueGrey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            const Text('2. Trong hoàn cảnh nào?', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _contextController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'VD: Xin nghỉ phép, Nhờ vả công việc, Rủ đi ăn...',
                filled: true,
                fillColor: Colors.blueGrey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            const Text('3. Mối quan hệ giữa hai người?', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildModeOption('Thân thiết', 'plain', Icons.face),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeOption('Lịch sự / Kính ngữ', 'keigo', Icons.business_center),
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
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: const Text('BẮT ĐẦU LUYỆN TẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(String label, String mode, IconData icon) {
    bool isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, String target, String mode) {
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

  void _startRoleplay() {
    if (_targetController.text.isEmpty || _contextController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin!')));
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoleplayChatScreen(
          title: 'Nói chuyện với ${_targetController.text}',
          description: _contextController.text,
          mode: _selectedMode,
        ),
      ),
    );
  }
}
