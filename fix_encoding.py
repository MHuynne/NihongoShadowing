import os

path = r'flutter_application_1\lib\features\admin\presentation\screens\pages\admin_segments_page.dart'

# Byte gốc trước khi append (lấy từ Total Bytes lúc file còn đúng)
ORIGINAL_SIZE = 46441

with open(path, 'rb') as f:
    raw = f.read()

# Lấy đúng phần gốc UTF-8
head_bytes = raw[:ORIGINAL_SIZE]
head = head_bytes.decode('utf-8')

# Kiểm tra kết thúc đúng chỗ (dòng cuối nên là "}\n")
print("Tail of head:", repr(head[-60:]))

new_tab = '''

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 – Segment Topics
// ─────────────────────────────────────────────────────────────────────────────

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
          ..sort((a, b) => (a[\'id\'] as int).compareTo(b[\'id\'] as int));
        _categories = results[1] as List<Map<String, dynamic>>;
        _allSegments = (results[2] as List<Map<String, dynamic>>)
          ..sort((a, b) => (a[\'id\'] as int).compareTo(b[\'id\'] as int));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _openTopicDialog([Map<String, dynamic>? topic]) async {
    final isEditing = topic != null;
    final titleCtrl = TextEditingController(text: (topic?[\'title\'] ?? \'\').toString());
    final descCtrl  = TextEditingController(text: (topic?[\'description\'] ?? \'\').toString());
    final imageCtrl = TextEditingController(text: (topic?[\'image_url\'] ?? \'\').toString());

    final existingCatIds = ((topic?[\'categories\'] as List?) ?? [])
        .map((c) => (c as Map)[\'id\'] as int)
        .toSet();
    final selectedCatIds = Set<int>.from(existingCatIds);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          title: Text(
            isEditing ? \'Sửa Segment Topic\' : \'Tạo Segment Topic mới\',
            style: const TextStyle(fontWeight: FontWeight.w800),
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
                    decoration: const InputDecoration(
                      labelText: \'Tiêu đề Topic *\',
                      hintText: \'VD: Giao tiếp hàng ngày\',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder_copy_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: \'Mô tả (tuỳ chọn)\',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: imageCtrl,
                    decoration: const InputDecoration(
                      labelText: \'URL ảnh (tuỳ chọn)\',
                      hintText: \'/static/uploads/...\',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    \'Phân loại (Categories)\',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (_categories.isEmpty)
                    const Text(
                      \'Chưa có category. Hãy tạo trong tab Categories.\',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final id = cat[\'id\'] as int;
                        final selected = selectedCatIds.contains(id);
                        return FilterChip(
                          label: Text(cat[\'name\']?.toString() ?? \'\'),
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(\'Huỷ\'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(\'Lưu\'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final payload = {
      \'title\': titleCtrl.text.trim(),
      \'description\': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      \'image_url\': imageCtrl.text.trim().isEmpty ? null : imageCtrl.text.trim(),
    };

    try {
      Map<String, dynamic> result;
      if (isEditing) {
        result = await widget.api.updateSegmentTopic(topic[\'id\'] as int, payload);
      } else {
        result = await widget.api.createSegmentTopic(payload);
      }
      await widget.api.setSegmentTopicCategories(
          result[\'id\'] as int, selectedCatIds.toList());
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(\'Đã lưu Segment Topic!\')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(\'Lỗi: $e\')));
    }
  }

  Future<void> _deleteTopic(Map<String, dynamic> topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(\'Xoá Segment Topic?\'),
        content: Text(\'"\${topic[\'title\']}" sẽ bị xoá. Segments sẽ bị gỡ khỏi topic.\'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(\'Huỷ\')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminPalette.errorRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(\'Xoá\'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteSegmentTopic(topic[\'id\'] as int);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(\'Không thể xoá: $e\')));
    }
  }

  Future<void> _openManageSegmentsDialog(Map<String, dynamic> topic) async {
    final topicId = topic[\'id\'] as int;
    final assignedIds = ((topic[\'segments\'] as List?) ?? [])
        .map((s) => (s as Map)[\'id\'] as int)
        .toSet();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) {
          final available = _allSegments.where((s) {
            final stid = s[\'segment_topic_id\'];
            return stid == null || stid == topicId;
          }).toList();

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.manage_search_rounded, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    \'Segments của: \${topic[\'title\']}\',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 680,
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    \'\${assignedIds.length} segment đang thuộc topic này\',
                    style: const TextStyle(color: AdminPalette.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: available.isEmpty
                        ? const Center(
                            child: Text(
                              \'Không có segment nào để gán.\\nTạo segment ở tab Shadowing Segments trước.\',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: available.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (_, i) {
                              final seg = available[i];
                              final segId = seg[\'id\'] as int;
                              final isAssigned = assignedIds.contains(segId);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isAssigned
                                      ? AdminPalette.sidebarSelectedBackground
                                          .withValues(alpha: 0.2)
                                      : AdminPalette.surfaceMuted,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isAssigned
                                        ? AdminPalette.sidebarSelectedForeground
                                            .withValues(alpha: 0.4)
                                        : AdminPalette.borderSoft,
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
                                            (seg[\'kanji_content\'] ??
                                                    seg[\'title\'] ??
                                                    \'ID $segId\')
                                                .toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: AdminPalette.textPrimary,
                                            ),
                                          ),
                                          if ((seg[\'translation_vi\'] ?? \'\')
                                              .toString()
                                              .isNotEmpty)
                                            Text(
                                              seg[\'translation_vi\'].toString(),
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
                                                        Text(\'Lỗi: $e\')));
                                          }
                                        }
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isAssigned
                                            ? AdminPalette.errorRed
                                                .withValues(alpha: 0.15)
                                            : AdminPalette
                                                .sidebarSelectedBackground,
                                        foregroundColor: isAssigned
                                            ? AdminPalette.errorRed
                                            : AdminPalette
                                                .sidebarSelectedForeground,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        textStyle:
                                            const TextStyle(fontSize: 12),
                                      ),
                                      child: Text(
                                          isAssigned ? \'Gỡ ra\' : \'Gán vào\'),
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
                child: const Text(\'Xong\'),
              ),
            ],
          );
        },
      ),
    );
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
            Text(\'\${_topics.length} segment topics\',
                style: const TextStyle(color: AdminPalette.textMuted)),
            const Spacer(),
            AdminPrimaryButton(
              label: \'Tạo Topic mới\',
              onPressed: _openTopicDialog,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_topics.isEmpty)
          const Expanded(
            child: AdminEmptyState(
              title: \'Chưa có Segment Topic nào\',
              subtitle: \'Tạo topic để nhóm segments theo chủ đề.\\nMỗi topic thuộc nhiều categories.\',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: _topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final topic = _topics[i];
                final cats = (topic[\'categories\'] as List?) ?? [];
                final segs = (topic[\'segments\'] as List?) ?? [];
                final imgUrl = (topic[\'image_url\'] ?? \'\').toString();
                final fullImg = imgUrl.isNotEmpty
                    ? (imgUrl.startsWith(\'http\')
                        ? imgUrl
                        : \'\${widget.api.baseUrl}$imgUrl\')
                    : \'\';

                return Container(
                  decoration: BoxDecoration(
                    color: AdminPalette.surfaceMuted,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AdminPalette.borderSoft),
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
                                  topic[\'title\']?.toString() ?? \'(Không tên)\',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AdminPalette.textPrimary),
                                ),
                                if ((topic[\'description\'] ?? \'\').toString().isNotEmpty)
                                  Text(
                                    topic[\'description\'].toString(),
                                    style: const TextStyle(
                                        color: AdminPalette.textMuted,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  \'ID: \${topic[\'id\']}  •  \${segs.length} segments\',
                                  style: const TextStyle(
                                      color: AdminPalette.textSecondary,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: \'Quản lý Segments\',
                            onPressed: () => _openManageSegmentsDialog(topic),
                            icon: const Icon(
                                Icons.playlist_add_check_rounded,
                                size: 20,
                                color: AdminPalette.sidebarSelectedForeground),
                          ),
                          IconButton(
                            tooltip: \'Chỉnh sửa\',
                            onPressed: () => _openTopicDialog(topic),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                          ),
                          IconButton(
                            tooltip: \'Xoá\',
                            onPressed: () => _deleteTopic(topic),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.redAccent),
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
                                      (c as Map)[\'name\']?.toString() ?? \'\',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor:
                                        AdminPalette.sidebarSelectedBackground,
                                    labelStyle: const TextStyle(
                                        color: AdminPalette
                                            .sidebarSelectedForeground,
                                        fontWeight: FontWeight.w600),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ))
                              .toList(),
                        ),
                      ],
                      if (segs.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AdminPalette.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(\'Segments:\',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AdminPalette.textSecondary)),
                              const SizedBox(height: 4),
                              ...segs.take(3).map((s) => Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Row(children: [
                                      const Icon(Icons.chevron_right,
                                          size: 14,
                                          color: AdminPalette.textMuted),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ((s as Map)[\'kanji_content\'] ??
                                                  s[\'title\'] ??
                                                  \'Segment \${s[\'id\']}\')
                                              .toString(),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AdminPalette.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ]),
                                  )),
                              if (segs.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                      \'... và \${segs.length - 3} segment khác\',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AdminPalette.textMuted)),
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
          color: AdminPalette.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdminPalette.borderSoft),
        ),
        child: const Icon(Icons.folder_copy_outlined, color: Colors.grey),
      );
}
'''

final = head + new_tab

with open(path, 'w', encoding='utf-8') as f:
    f.write(final)

print("Done! Written", len(final), "chars as UTF-8.")

# Verify
with open(path, 'rb') as f:
    check = f.read(4)
print("First bytes:", check.hex())  # should NOT start with EF BB BF (BOM), just normal UTF-8
