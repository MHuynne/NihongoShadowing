import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_ui.dart';
import 'package:flutter_application_1/features/admin/services/admin_api_service.dart';

/// Trang quản lý Shadowing Segment độc lập và Category
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
    _tabController = TabController(length: 2, vsync: this);
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
          AdminSectionHeader(
            title: 'Segments & Categories',
            subtitle: 'Segment độc lập (không gắn topic) và danh mục phân loại nội dung.',
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            labelColor: AdminPalette.sidebarSelectedForeground,
            unselectedLabelColor: AdminPalette.textMuted,
            indicatorColor: AdminPalette.sidebarSelectedForeground,
            tabs: const [
              Tab(text: 'Shadowing Segments', icon: Icon(Icons.view_list_rounded, size: 18)),
              Tab(text: 'Categories', icon: Icon(Icons.label_rounded, size: 18)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SegmentsTab(api: widget.api),
                _CategoriesTab(api: widget.api),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 – Shadowing Segments (độc lập)
// ─────────────────────────────────────────────────────────────────────────────

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
  List<Map<String, dynamic>> _categories = [];

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
        widget.api.fetchCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _segments = (results[0] as List<Map<String, dynamic>>)
          ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
        _categories = results[1] as List<Map<String, dynamic>>;
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
    final imageCtrl = TextEditingController(text: (seg?['image_url'] ?? '').toString());
    // Dùng map để track state trong StatefulBuilder
    final imgState = <String, dynamic>{
      'bytes': null,    // Uint8List? — preview bytes
      'uploading': false,
    };

    // Categories
    final existingCatIds = ((seg?['categories'] as List?) ?? [])
        .map((c) => (c as Map)['id'] as int)
        .toSet();
    final selectedCatIds = Set<int>.from(existingCatIds);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) {
          final imgUrl = imageCtrl.text.trim();
          return AlertDialog(
            title: Text(
              isEditing ? 'Chỉnh sửa Segment' : 'Thêm Segment mới',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Tiêu đề hiển thị ─────────────────────────────────
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề bài Segment',
                        hintText: 'VD: Chào hỏi cơ bản',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Phân loại (Categories) ────────────────────────────
                    const Text(
                      'Phân loại (Categories)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (_categories.isEmpty)
                      const Text(
                        'Chưa có category nào. Hãy tạo category trước.',
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
                            labelStyle: TextStyle(
                              color: selected
                                  ? AdminPalette.sidebarSelectedForeground
                                  : AdminPalette.textPrimary,
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),

                    // ── Ảnh minh hoạ ─────────────────────────────────────
                    const Text(
                      'Ảnh minh hoạ',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    // Vùng kéo-thả / click để chọn file
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
                            color: AdminPalette.sidebarSelectedForeground.withValues(alpha: 0.5),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                          color: AdminPalette.surfaceMuted,
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
                                    CircularProgressIndicator(),
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
                    const SizedBox(height: 8),
                    // URL hiển thị (read-mostly, có thể sửa thủ công)
                    TextField(
                      controller: imageCtrl,
                      onChanged: (_) => setDS(() => imgState['bytes'] = null),
                      decoration: const InputDecoration(
                        labelText: 'Hoặc nhập URL ảnh trực tiếp',
                        hintText: '/static/uploads/abc.jpg',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link_rounded),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Nội dung câu Shadowing ────────────────────────────
                    const Text(
                      'Nội dung câu Shadowing',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: kanjiCtrl,
                      decoration: const InputDecoration(
                        labelText: '漢字 — Câu gốc (có Kanji)',
                        hintText: 'VD: 日本語を勉強しています',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: furiganaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Furigana — Phiên âm Hiragana',
                        hintText: 'VD: にほんごをべんきょうしています',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: transCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dịch nghĩa tiếng Việt',
                        hintText: 'VD: Tôi đang học tiếng Nhật.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Huỷ'),
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
      'image_url': imageCtrl.text.trim().isEmpty ? null : imageCtrl.text.trim(),
    };

    try {
      Map<String, dynamic> savedSeg;
      if (isEditing) {
        savedSeg = await widget.api.updateSegment(seg['id'] as int, payload);
      } else {
        savedSeg = await widget.api.createSegment(payload);
      }
      await widget.api.setSegmentCategories(
          savedSeg['id'] as int, selectedCatIds.toList());

      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu segment!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Widget _dropZonePlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: AdminPalette.sidebarSelectedForeground.withValues(alpha: 0.6),
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

  Widget _imagePlaceholder() => _dropZonePlaceholder();


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

  Future<void> _deleteSegment(Map<String, dynamic> seg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá segment?'),
        content: Text(
            'Segment "${seg['kanji_content'] ?? 'ID ${seg['id']}'}" sẽ bị xoá vĩnh viễn.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Huỷ')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AdminPalette.errorRed),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Xoá')),
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
          .showSnackBar(SnackBar(content: Text('Không thể xoá: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: AdminPalette.errorRed)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${_segments.length} segments',
                style: const TextStyle(color: AdminPalette.textMuted)),
            const Spacer(),
            AdminPrimaryButton(
              label: 'Thêm segment',
              onPressed: _openSegmentDialog,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_segments.isEmpty)
          const Expanded(
            child: AdminEmptyState(
              title: 'Chưa có segment nào',
              subtitle: 'Thêm segment mới để dùng trong các bài Shadowing.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: _segments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final seg = _segments[i];
                final cats = (seg['categories'] as List?) ?? [];
                final imgUrl = (seg['image_url'] ?? '').toString();
                final fullImgUrl = imgUrl.isNotEmpty
                    ? (imgUrl.startsWith('http')
                        ? imgUrl
                        : '${widget.api.baseUrl}$imgUrl')
                    : '';

                return Container(
                  decoration: BoxDecoration(
                    color: AdminPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AdminPalette.borderSoft),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Ảnh thumbnail ──────────────────────────────
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

                      // ── Nội dung ───────────────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (cats.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: cats.map((c) => Chip(
                                  label: Text(
                                    (c as Map)['name']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: AdminPalette.sidebarSelectedBackground,
                                  labelStyle: const TextStyle(
                                    color: AdminPalette.sidebarSelectedForeground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                )).toList(),
                              ),
                            if (cats.isNotEmpty) const SizedBox(height: 6),
                            Text(
                              (seg['kanji_content'] ?? '—').toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AdminPalette.textPrimary,
                              ),
                            ),
                            if ((seg['furigana'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                seg['furigana'].toString(),
                                style: const TextStyle(
                                    color: AdminPalette.textSecondary, fontSize: 13),
                              ),
                            ],
                            if ((seg['translation_vi'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                seg['translation_vi'].toString(),
                                style: const TextStyle(
                                    color: AdminPalette.textMuted, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── Actions ────────────────────────────────────
                      Column(
                        children: [
                          IconButton(
                            tooltip: 'Chỉnh sửa',
                            onPressed: () => _openSegmentDialog(seg),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Xoá',
                            onPressed: () => _deleteSegment(seg),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.redAccent),
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
          color: AdminPalette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminPalette.borderSoft),
        ),
        child: const Icon(Icons.image_outlined, color: Colors.grey),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 – Categories
// ─────────────────────────────────────────────────────────────────────────────

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
        title: Text(isEditing ? 'Chỉnh sửa Category' : 'Thêm Category mới'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Tên category (vd: Giao tiếp)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Mô tả (tuỳ chọn)',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Huỷ')),
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
          .showSnackBar(const SnackBar(content: Text('Đã lưu category!')));
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
        title: const Text('Xoá category?'),
        content: Text('Category "${cat['name']}" sẽ bị xoá khỏi tất cả segments liên quan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Huỷ')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AdminPalette.errorRed),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Xoá')),
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
          .showSnackBar(SnackBar(content: Text('Không thể xoá: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: AdminPalette.errorRed)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${_categories.length} categories',
                style: const TextStyle(color: AdminPalette.textMuted)),
            const Spacer(),
            AdminPrimaryButton(
              label: 'Thêm category',
              onPressed: _openCategoryDialog,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_categories.isEmpty)
          const Expanded(
            child: AdminEmptyState(
              title: 'Chưa có category nào',
              subtitle: 'Thêm các category như Giao tiếp, Du lịch, Công việc để phân loại nội dung.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AdminPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminPalette.borderSoft),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AdminPalette.sidebarSelectedBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.label_rounded,
                            color: AdminPalette.sidebarSelectedForeground),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (cat['name'] ?? 'Không tên').toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AdminPalette.textPrimary,
                                  fontSize: 15),
                            ),
                            if ((cat['description'] ?? '').toString().isNotEmpty)
                              Text(
                                cat['description'].toString(),
                                style: const TextStyle(
                                    color: AdminPalette.textMuted, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'ID: ${cat['id']}',
                        style: const TextStyle(
                            color: AdminPalette.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Chỉnh sửa',
                        onPressed: () => _openCategoryDialog(cat),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                      IconButton(
                        tooltip: 'Xoá',
                        onPressed: () => _deleteCategory(cat),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: Colors.redAccent),
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
