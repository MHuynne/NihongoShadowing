import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

class AdminSegmentsPage extends StatefulWidget {
  const AdminSegmentsPage({super.key, required this.api});

  final AdminApiService api;

  @override
  State<AdminSegmentsPage> createState() => _AdminSegmentsPageState();
}

class _AdminSegmentsPageState extends State<AdminSegmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Phân đoạn & Danh mục',
            subtitle: 'Câu Shadowing độc lập (không thuộc chủ đề) và danh mục phân loại.',
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: AdminPalette.sidebarSelectedForeground,
            unselectedLabelColor: AdminPalette.textMuted,
            indicatorColor: AdminPalette.sidebarSelectedForeground,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Câu Shadowing', icon: Icon(Icons.view_list_rounded, size: 18)),
              Tab(text: 'Chủ đề Shadowing', icon: Icon(Icons.folder_copy_rounded, size: 18)),
              Tab(text: 'Danh mục', icon: Icon(Icons.label_rounded, size: 18)),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SegmentsTab(api: widget.api),
                _SegmentTopicsTab(api: widget.api),
                _CategoriesTab(api: widget.api),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable styling helper
InputDecoration _inputDeco(String label, {bool isDense = false, Widget? prefixIcon}) {
  return InputDecoration(
    labelText: label,
    isDense: isDense,
    prefixIcon: prefixIcon,
    prefixIconColor: Colors.white.withOpacity(0.5),
    labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
    floatingLabelStyle: const TextStyle(color: AdminPalette.sidebarSelectedForeground, fontSize: 13, fontWeight: FontWeight.w700),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isDense ? 12 : 16),
    filled: true,
    fillColor: Colors.white.withOpacity(0.015),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AdminPalette.sidebarSelectedForeground, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AdminPalette.errorRed, width: 1.0),
    ),
  );
}

class _SegmentsTab extends StatefulWidget {
  const _SegmentsTab({required this.api});
  final AdminApiService api;

  @override
  State<_SegmentsTab> createState() => _SegmentsTabState();
}

class _SegmentsTabState extends State<_SegmentsTab> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _segments = [];
  List<Map<String, dynamic>> _segmentTopics = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.api.fetchAllSegments(),
        widget.api.fetchSegmentTopics(),
      ]);
      if (!mounted) return;
      setState(() {
        _segments = (results[0] as List<Map<String, dynamic>>)
          ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        _segmentTopics = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _openSegmentDialog([Map<String, dynamic>? seg]) async {
    final isEditing = seg != null;
    final titleCtrl = TextEditingController(text: (seg?['title'] ?? '').toString());
    final kanjiCtrl = TextEditingController(text: (seg?['kanji_content'] ?? '').toString());
    final furiganaCtrl = TextEditingController(text: (seg?['furigana'] ?? '').toString());
    final transCtrl = TextEditingController(text: (seg?['translation_vi'] ?? '').toString());
    int? selectedTopicId = seg?['segment_topic_id'] as int?;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) {
          return AlertDialog(
            title: Text(
              isEditing ? 'Chỉnh sửa câu Shadowing' : 'Thêm câu Shadowing mới',
              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            backgroundColor: AdminPalette.surfaceMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
            ),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: _inputDeco('Tiêu đề câu', prefixIcon: const Icon(Icons.title_rounded)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedTopicId,
                      decoration: _inputDeco('Gắn vào chủ đề Shadowing (Tùy chọn)', prefixIcon: const Icon(Icons.topic_outlined)),
                      dropdownColor: AdminPalette.surfaceMuted,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('— Không gắn chủ đề —'),
                        ),
                        ..._segmentTopics.map(
                          (t) => DropdownMenuItem<int>(
                            value: t['id'] as int,
                            child: Text(t['title']?.toString() ?? ''),
                          ),
                        ),
                      ],
                      onChanged: (v) => setDS(() => selectedTopicId = v),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nội dung câu Shadowing',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: kanjiCtrl,
                      decoration: _inputDeco('漢字 — Câu gốc (có Kanji)'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: furiganaCtrl,
                      decoration: _inputDeco('Furigana — Phiên âm Hiragana'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: transCtrl,
                      decoration: _inputDeco('Dịch nghĩa tiếng Việt'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true || !mounted) return;

    final payload = {
      'title': titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
      'order_index': 1,
      'start_time': null,
      'end_time': null,
      'kanji_content': kanjiCtrl.text.trim().isEmpty ? null : kanjiCtrl.text.trim(),
      'furigana': furiganaCtrl.text.trim().isEmpty ? null : furiganaCtrl.text.trim(),
      'romaji': null,
      'sino_vietnamese': null,
      'translation_vi': transCtrl.text.trim().isEmpty ? null : transCtrl.text.trim(),
      'image_url': null,
      'segment_topic_id': selectedTopicId,
    };

    try {
      if (isEditing) {
        await widget.api.updateSegment(seg['id'] as int, payload);
      } else {
        await widget.api.createSegment(payload);
      }
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu câu Shadowing!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _openBulkDialog() async {
    final rows = <Map<String, TextEditingController>>[
      _newBulkRow(),
    ];
    int? bulkSelectedTopicId;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) {
          return AlertDialog(
            title: const Text(
              'Thêm nhiều câu Shadowing cùng lúc',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3),
            ),
            backgroundColor: AdminPalette.surfaceMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
            ),
            content: SizedBox(
              width: 900,
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 340,
                    child: DropdownButtonFormField<int>(
                      value: bulkSelectedTopicId,
                      decoration: _inputDeco('Gắn tất cả vào chủ đề (Tùy chọn)', prefixIcon: const Icon(Icons.topic_outlined), isDense: true),
                      dropdownColor: AdminPalette.surfaceMuted,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('— Không gắn chủ đề —'),
                        ),
                        ..._segmentTopics.map(
                          (t) => DropdownMenuItem<int>(
                            value: t['id'] as int,
                            child: Text(t['title']?.toString() ?? ''),
                          ),
                        ),
                      ],
                      onChanged: (v) => setDS(() => bulkSelectedTopicId = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: const [
                        SizedBox(width: 32),
                        SizedBox(width: 8),
                        Expanded(flex: 3, child: Text('漢字 (Câu gốc)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white70))),
                        SizedBox(width: 8),
                        Expanded(flex: 3, child: Text('Furigana', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white70))),
                        SizedBox(width: 8),
                        Expanded(flex: 4, child: Text('Dịch nghĩa (Việt)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white70))),
                        SizedBox(width: 8),
                        Expanded(flex: 2, child: Text('Tiêu đề', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white70))),
                        SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final row = rows[i];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: _compactField(
                                row['kanji']!,
                                hint: 'VD: 日本語',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: _compactField(
                                row['furigana']!,
                                hint: 'にほんご',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: _compactField(
                                row['trans']!,
                                hint: 'Tiếng Nhật',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _compactField(
                                row['title']!,
                                hint: 'Tiêu đề',
                              ),
                            ),
                            IconButton(
                              tooltip: 'Xóa dòng này',
                              onPressed: rows.length > 1
                                  ? () => setDS(() {
                                        rows.removeAt(i);
                                      })
                                  : null,
                              icon: Icon(
                                Icons.remove_circle_outline,
                                size: 18,
                                color: rows.length > 1
                                    ? AdminPalette.errorRed
                                    : Colors.white30,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => setDS(() {
                      rows.add(_newBulkRow());
                    }),
                    icon: const Icon(Icons.add_circle_outline, size: 18, color: AdminPalette.sidebarSelectedForeground),
                    label: const Text('Thêm dòng mới', style: TextStyle(color: AdminPalette.sidebarSelectedForeground, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text('Lưu ${rows.length} câu'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true || !mounted) return;

    final payloads = rows
        .map((r) => {
              'title': r['title']!.text.trim().isEmpty ? null : r['title']!.text.trim(),
              'order_index': 1,
              'start_time': null,
              'end_time': null,
              'kanji_content': r['kanji']!.text.trim().isEmpty ? null : r['kanji']!.text.trim(),
              'furigana': r['furigana']!.text.trim().isEmpty ? null : r['furigana']!.text.trim(),
              'romaji': null,
              'sino_vietnamese': null,
              'translation_vi': r['trans']!.text.trim().isEmpty ? null : r['trans']!.text.trim(),
              'image_url': null,
              'segment_topic_id': bulkSelectedTopicId,
            })
        .where((p) =>
            (p['kanji_content'] ?? '').toString().isNotEmpty ||
            (p['translation_vi'] ?? '').toString().isNotEmpty)
        .toList();

    if (payloads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có dòng nào hợp lệ để lưu.')),
      );
      return;
    }

    try {
      await widget.api.createSegmentsBulk(payloads);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${payloads.length} câu Shadowing!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }

    for (final r in rows) {
      for (final c in r.values) {
        c.dispose();
      }
    }
  }

  Map<String, TextEditingController> _newBulkRow() => {
        'kanji': TextEditingController(),
        'furigana': TextEditingController(),
        'trans': TextEditingController(),
        'title': TextEditingController(),
      };

  Widget _compactField(TextEditingController ctrl, {String hint = ''}) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
          isDense: true,
          filled: true,
          fillColor: Colors.white.withOpacity(0.015),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AdminPalette.sidebarSelectedForeground, width: 1.0),
          ),
        ),
      );

  Future<void> _deleteSegment(Map<String, dynamic> seg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa câu Shadowing?'),
        content: Text(
            'Câu Shadowing "${seg['kanji_content'] ?? 'ID ${seg['id']}'}" sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AdminPalette.errorRed),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteSegment(seg['id'] as int);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể xóa: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AdminPalette.sidebarSelectedForeground),
        ),
      );
    }
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: AdminPalette.errorRed)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${_segments.length} câu Shadowing',
                style: const TextStyle(color: AdminPalette.textMuted, fontSize: 13)),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _openBulkDialog,
              icon: const Icon(Icons.playlist_add_rounded, size: 18),
              label: const Text('Thêm nhiều câu'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminPalette.sidebarSelectedForeground,
                side: BorderSide(
                  color: AdminPalette.sidebarSelectedForeground.withOpacity(0.6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AdminPrimaryButton(
              label: 'Thêm 1 câu',
              onPressed: _openSegmentDialog,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_segments.isEmpty)
          const Expanded(
            child: AdminEmptyState(
              title: 'Chưa có câu Shadowing nào',
              subtitle: 'Thêm câu Shadowing mới để luyện nghe nói.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _segments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final seg = _segments[i];
                final imgUrl = (seg['image_url'] ?? '').toString();
                final fullImgUrl = imgUrl.isNotEmpty
                    ? (imgUrl.startsWith('http')
                        ? imgUrl
                        : '${widget.api.baseUrl}$imgUrl')
                    : '';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.015),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: fullImgUrl.isNotEmpty
                            ? Image.network(
                                fullImgUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _noImageBox(),
                              )
                            : _noImageBox(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (seg['segment_topic_id'] != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: AdminPalette.sidebarSelectedBackground.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AdminPalette.sidebarSelectedForeground.withOpacity(0.2)),
                                ),
                                child: Text(
                                  'Topic: ${_segmentTopics.firstWhere((t) => t['id'] == seg['segment_topic_id'], orElse: () => {'title': 'N/A'})['title']}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AdminPalette.sidebarSelectedForeground,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            Text(
                              (seg['kanji_content'] ?? '—').toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AdminPalette.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if ((seg['furigana'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                seg['furigana'].toString(),
                                style: const TextStyle(
                                    color: AdminPalette.textSecondary, fontSize: 13),
                              ),
                            ],
                            if ((seg['translation_vi'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                seg['translation_vi'].toString(),
                                style: const TextStyle(
                                    color: AdminPalette.textMuted, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Chỉnh sửa',
                            onPressed: () => _openSegmentDialog(seg),
                            icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 19),
                          ),
                          IconButton(
                            tooltip: 'Xóa',
                            onPressed: () => _deleteSegment(seg),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 19, color: AdminPalette.errorRed),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _noImageBox() => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.015),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Icon(Icons.image_outlined, color: Colors.white38),
      );
}

class _CategoriesTab extends StatefulWidget {
  const _CategoriesTab({required this.api});
  final AdminApiService api;

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await widget.api.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = data..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _openCategoryDialog([Map<String, dynamic>? cat]) async {
    final isEditing = cat != null;
    final nameCtrl = TextEditingController(text: (cat?['name'] ?? '').toString());
    final descCtrl = TextEditingController(text: (cat?['description'] ?? '').toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEditing ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới',
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        backgroundColor: AdminPalette.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: _inputDeco('Tên danh mục (vd: Giao tiếp)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: _inputDeco('Mô tả (tùy chọn)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Lưu')),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    final payload = {
      'name': nameCtrl.text.trim(),
      'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
    };

    try {
      if (isEditing) {
        await widget.api.updateCategory(cat['id'] as int, payload);
      } else {
        await widget.api.createCategory(payload);
      }
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu danh mục!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa danh mục?'),
        content: Text('Danh mục "${cat['name']}" sẽ bị xóa khỏi tất cả segment topics liên quan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AdminPalette.errorRed),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteCategory(cat['id'] as int);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể xóa: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AdminPalette.sidebarSelectedForeground),
        ),
      );
    }
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: AdminPalette.errorRed)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${_categories.length} danh mục',
                style: const TextStyle(color: AdminPalette.textMuted, fontSize: 13)),
            const Spacer(),
            AdminPrimaryButton(
              label: 'Thêm danh mục',
              onPressed: _openCategoryDialog,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_categories.isEmpty)
          const Expanded(
            child: AdminEmptyState(
              title: 'Chưa có danh mục nào',
              subtitle: 'Thêm các danh mục như Giao tiếp, Du lịch, Công việc để phân loại nội dung.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.015),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AdminPalette.sidebarSelectedBackground.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminPalette.sidebarSelectedForeground.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.label_rounded,
                            color: AdminPalette.sidebarSelectedForeground, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (cat['name'] ?? 'Không tên').toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AdminPalette.textPrimary,
                                  fontSize: 15,
                                  letterSpacing: -0.3),
                            ),
                            if ((cat['description'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                cat['description'].toString(),
                                style: const TextStyle(
                                    color: AdminPalette.textMuted, fontSize: 12),
                              ),
                            ]
                          ],
                        ),
                      ),
                      Text(
                        'ID: ${cat['id']}',
                        style: const TextStyle(
                            color: AdminPalette.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        tooltip: 'Chỉnh sửa',
                        onPressed: () => _openCategoryDialog(cat),
                        icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 19),
                      ),
                      IconButton(
                        tooltip: 'Xóa',
                        onPressed: () => _deleteCategory(cat),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 19, color: AdminPalette.errorRed),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SegmentTopicsTab extends StatefulWidget {
  const _SegmentTopicsTab({required this.api});
  final AdminApiService api;

  @override
  State<_SegmentTopicsTab> createState() => _SegmentTopicsTabState();
}

class _SegmentTopicsTabState extends State<_SegmentTopicsTab> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allSegments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.api.fetchSegmentTopics(),
        widget.api.fetchCategories(),
        widget.api.fetchAllSegments(),
      ]);
      if (!mounted) return;
      setState(() {
        _topics = (results[0] as List<Map<String, dynamic>>)
          ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        _categories = results[1] as List<Map<String, dynamic>>;
        _allSegments = (results[2] as List<Map<String, dynamic>>)
          ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _openTopicDialog([Map<String, dynamic>? topic]) async {
    final isEditing = topic != null;
    final titleCtrl = TextEditingController(text: (topic?['title'] ?? '').toString());
    final descCtrl  = TextEditingController(text: (topic?['description'] ?? '').toString());
    final imageCtrl = TextEditingController(text: (topic?['image_url'] ?? '').toString());

    final imgState = <String, dynamic>{
      'bytes': null,
      'uploading': false,
    };

    final existingCatIds = ((topic?['categories'] as List?) ?? [])
        .map((c) => (c as Map)['id'] as int)
        .toSet();
    final selectedCatIds = Set<int>.from(existingCatIds);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          title: Text(
            isEditing ? 'Sửa chủ đề Shadowing' : 'Tạo chủ đề Shadowing mới',
            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          backgroundColor: AdminPalette.surfaceMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: _inputDeco('Tiêu đề chủ đề *', prefixIcon: const Icon(Icons.folder_copy_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: _inputDeco('Mô tả (tùy chọn)', prefixIcon: const Icon(Icons.description_outlined)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ảnh minh hoạ',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (result == null || result.files.single.bytes == null) return;
                      final bytes = result.files.single.bytes!;
                      final name = result.files.single.name;
                      setDS(() => imgState['uploading'] = true);
                      try {
                        final url = await widget.api.uploadFile(bytes, name);
                        setDS(() {
                          imageCtrl.text = url;
                          imgState['bytes'] = bytes;
                          imgState['uploading'] = false;
                        });
                      } catch (e) {
                        setDS(() => imgState['uploading'] = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Lỗi upload: $e')),
                          );
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AdminPalette.sidebarSelectedForeground.withOpacity(0.3),
                          width: 1.5,
                        ),
                        color: Colors.white.withOpacity(0.015),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: () {
                        final previewBytes = imgState['bytes'] as Uint8List?;
                        final uploading = imgState['uploading'] as bool;
                        final currentUrl = imageCtrl.text.trim();

                        if (uploading) {
                          return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AdminPalette.sidebarSelectedForeground)),
                                  SizedBox(height: 12),
                                  Text('Đang tải lên...', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                        }
                        if (previewBytes != null) {
                          return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(previewBytes, fit: BoxFit.cover),
                                _changeOverlay(),
                              ],
                            );
                        }
                        if (currentUrl.isNotEmpty) {
                          return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  currentUrl.startsWith('http') ? currentUrl : '${widget.api.baseUrl}$currentUrl',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _dropZonePlaceholder(),
                                ),
                                _changeOverlay(),
                              ],
                            );
                        }
                        return _dropZonePlaceholder();
                      }()
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageCtrl,
                    onChanged: (_) => setDS(() => imgState['bytes'] = null),
                    decoration: _inputDeco('Hoặc nhập URL ảnh trực tiếp', prefixIcon: const Icon(Icons.link_rounded), isDense: true),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Phân loại (Danh mục)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  if (_categories.isEmpty)
                    const Text(
                      'Chưa có danh mục. Hãy tạo trong tab Danh mục.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final id = cat['id'] as int;
                        final selected = selectedCatIds.contains(id);
                        return FilterChip(
                          label: Text(cat['name']?.toString() ?? ''),
                          selected: selected,
                          onSelected: (v) => setDS(() {
                            if (v) selectedCatIds.add(id);
                            else selectedCatIds.remove(id);
                          }),
                          selectedColor: AdminPalette.sidebarSelectedBackground,
                          checkmarkColor: AdminPalette.sidebarSelectedForeground,
                          backgroundColor: Colors.white.withOpacity(0.015),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? AdminPalette.sidebarSelectedForeground
                                : AdminPalette.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final payload = {
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      'image_url': imageCtrl.text.trim().isEmpty ? null : imageCtrl.text.trim(),
    };

    try {
      Map<String, dynamic> result;
      if (isEditing) {
        result = await widget.api.updateSegmentTopic(topic['id'] as int, payload);
      } else {
        result = await widget.api.createSegmentTopic(payload);
      }
      await widget.api.setSegmentTopicCategories(
          result['id'] as int, selectedCatIds.toList());
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu chủ đề Shadowing!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _deleteTopic(Map<String, dynamic> topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa chủ đề Shadowing?'),
        content: Text('"${topic['title']}" sẽ bị xóa. Các câu Shadowing sẽ bị gỡ khỏi chủ đề.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminPalette.errorRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteSegmentTopic(topic['id'] as int);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể xóa: $e')));
    }
  }

  Future<void> _openManageSegmentsDialog(Map<String, dynamic> topic) async {
    final topicId = topic['id'] as int;
    final assignedIds = ((topic['segments'] as List?) ?? [])
        .map((s) => (s as Map)['id'] as int)
        .toSet();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) {
          final available = _allSegments.where((s) {
            final stid = s['segment_topic_id'];
            return stid == null || stid == topicId;
          }).toList();

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.manage_search_rounded, size: 22, color: AdminPalette.sidebarSelectedForeground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Các câu của: ${topic['title']}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AdminPalette.surfaceMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
            ),
            content: SizedBox(
              width: 680,
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${assignedIds.length} câu đang thuộc chủ đề này',
                    style: const TextStyle(color: AdminPalette.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: available.isEmpty
                        ? const Center(
                            child: Text(
                              'Không có câu Shadowing nào để gán.\nTạo câu ở tab Câu Shadowing trước.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: available.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final seg = available[i];
                              final segId = seg['id'] as int;
                              final isAssigned = assignedIds.contains(segId);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isAssigned
                                      ? AdminPalette.sidebarSelectedBackground
                                          .withOpacity(0.12)
                                      : Colors.white.withOpacity(0.01),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isAssigned
                                        ? AdminPalette.sidebarSelectedForeground
                                            .withOpacity(0.3)
                                        : Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: isAssigned
                                          ? const Icon(
                                              Icons.check_circle_rounded,
                                              size: 18,
                                              color: AdminPalette
                                                  .sidebarSelectedForeground)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (seg['kanji_content'] ??
                                                    seg['title'] ??
                                                    'Câu $segId')
                                                .toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: AdminPalette.textPrimary,
                                            ),
                                          ),
                                          if ((seg['translation_vi'] ?? '')
                                              .toString()
                                              .isNotEmpty)
                                            Text(
                                              seg['translation_vi'].toString(),
                                              style: const TextStyle(
                                                  color: AdminPalette.textMuted,
                                                  fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),
                                    FilledButton.tonal(
                                      onPressed: () async {
                                        try {
                                          if (isAssigned) {
                                            await widget.api
                                                .removeSegmentFromTopic(
                                                    topicId, segId);
                                            setDS(() =>
                                                assignedIds.remove(segId));
                                          } else {
                                            await widget.api
                                                .assignSegmentToTopic(
                                                    topicId, segId);
                                            setDS(
                                                () => assignedIds.add(segId));
                                          }
                                        } catch (e) {
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(ctx)
                                                .showSnackBar(SnackBar(
                                                    content:
                                                        Text('Lỗi: $e')));
                                          }
                                        }
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isAssigned
                                            ? AdminPalette.errorRed
                                                .withOpacity(0.15)
                                            : AdminPalette
                                                .sidebarSelectedBackground,
                                        foregroundColor: isAssigned
                                            ? AdminPalette.errorRed
                                            : AdminPalette
                                                .sidebarSelectedForeground,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        textStyle:
                                            const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      child: Text(
                                          isAssigned ? 'Gỡ ra' : 'Gán vào'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _loadData();
                },
                child: const Text('Xong'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AdminPalette.sidebarSelectedForeground),
        ),
      );
    }
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: AdminPalette.errorRed)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${_topics.length} segment topics',
                style: const TextStyle(color: AdminPalette.textMuted, fontSize: 13)),
            const Spacer(),
            AdminPrimaryButton(
              label: 'Tạo Topic mới',
              onPressed: _openTopicDialog,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_topics.isEmpty)
          const Expanded(
            child: AdminEmptyState(
              title: 'Chưa có chủ đề Shadowing nào',
              subtitle: 'Tạo chủ đề để nhóm các câu theo chủ đề.\nMỗi chủ đề thuộc nhiều danh mục.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final topic = _topics[i];
                final cats = (topic['categories'] as List?) ?? [];
                final segs = (topic['segments'] as List?) ?? [];
                final imgUrl = (topic['image_url'] ?? '').toString();
                final fullImg = imgUrl.isNotEmpty
                    ? (imgUrl.startsWith('http')
                        ? imgUrl
                        : '${widget.api.baseUrl}$imgUrl')
                    : '';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.015),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: fullImg.isNotEmpty
                                ? Image.network(
                                    fullImg,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _noImgBox(),
                                  )
                                : _noImgBox(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  topic['title']?.toString() ?? '(Không tên)',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AdminPalette.textPrimary,
                                      letterSpacing: -0.3),
                                ),
                                if ((topic['description'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    topic['description'].toString(),
                                    style: const TextStyle(
                                        color: AdminPalette.textMuted,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${topic['id']}  •  ${segs.length} câu',
                                  style: const TextStyle(
                                      color: AdminPalette.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quản lý các câu',
                            onPressed: () => _openManageSegmentsDialog(topic),
                            icon: const Icon(
                                Icons.playlist_add_check_rounded,
                                size: 22,
                                color: AdminPalette.sidebarSelectedForeground),
                          ),
                          IconButton(
                            tooltip: 'Chỉnh sửa',
                            onPressed: () => _openTopicDialog(topic),
                            icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 19),
                          ),
                          IconButton(
                            tooltip: 'Xóa',
                            onPressed: () => _deleteTopic(topic),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 19, color: AdminPalette.errorRed),
                          ),
                        ],
                      ),
                      if (cats.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: cats
                              .map((c) => Chip(
                                    label: Text(
                                      (c as Map)['name']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor:
                                        AdminPalette.sidebarSelectedBackground.withOpacity(0.15),
                                    side: BorderSide(color: AdminPalette.sidebarSelectedForeground.withOpacity(0.2)),
                                    labelStyle: const TextStyle(
                                        color: AdminPalette.sidebarSelectedForeground,
                                        fontWeight: FontWeight.bold),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ))
                              .toList(),
                        ),
                      ],
                      if (segs.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.008),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.03)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Các câu tiêu biểu:',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white38)),
                              const SizedBox(height: 4),
                              ...segs.take(3).map((s) => Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Row(children: [
                                      const Icon(Icons.chevron_right,
                                          size: 14,
                                          color: Colors.white24),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ((s as Map)['kanji_content'] ??
                                                  s['title'] ??
                                                  'Câu ${s['id']}')
                                              .toString(),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white70),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ]),
                                  )),
                              if (segs.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                      '... và ${segs.length - 3} câu khác',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white38)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _noImgBox() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.015),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Icon(Icons.folder_copy_outlined, color: Colors.white38, size: 20),
      );

  Widget _dropZonePlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: AdminPalette.sidebarSelectedForeground.withOpacity(0.6),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nhấp để chọn ảnh',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'JPG, PNG, WEBP — tối đa 10MB',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      );

  Widget _changeOverlay() => Positioned(
        bottom: 0, left: 0, right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: Colors.black54,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh_rounded, size: 14, color: Colors.white70),
              SizedBox(width: 6),
              Text('Nhấp để đổi ảnh', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      );
}