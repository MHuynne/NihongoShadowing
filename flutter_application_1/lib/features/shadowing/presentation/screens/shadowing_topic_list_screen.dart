import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/shadowing/presentation/screens/shadowing_screen.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/core/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _kBg      = Color(0xFFF4F6F9);
const _kSurface = Colors.white;
const _kOnSurface = Color(0xFF1E293B);
const _kSubtext   = Color(0xFF64748B);
const _kPrimary   = Color(0xFFFF5238);


class ShadowingTopicListScreen extends StatefulWidget {
  const ShadowingTopicListScreen({super.key});

  @override
  State<ShadowingTopicListScreen> createState() =>
      _ShadowingTopicListScreenState();
}

class _ShadowingTopicListScreenState extends State<ShadowingTopicListScreen> {
  bool _isLoading = true;
  String? _error;

  /// Tất cả segments từ API
  List<Map<String, dynamic>> _segments = [];

  /// Danh sách categories từ DB (thêm "Tất cả" ở đầu)
  List<String> _categoryNames = ['Tất cả'];

  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String get _base => ApiConfig.baseUrl;

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Gọi song song: segments + categories
      final results = await Future.wait([
        http.get(Uri.parse('$_base/shadowing/segments/all')),
        http.get(Uri.parse('$_base/categories/')),
      ]);

      final segRes = results[0];
      final catRes = results[1];

      if (segRes.statusCode != 200) {
        throw Exception('Lỗi tải segments: HTTP ${segRes.statusCode}');
      }
      if (catRes.statusCode != 200) {
        throw Exception('Lỗi tải categories: HTTP ${catRes.statusCode}');
      }

      final List<dynamic> rawSegs = json.decode(utf8.decode(segRes.bodyBytes));
      final List<dynamic> rawCats = json.decode(utf8.decode(catRes.bodyBytes));

      final segs = rawSegs
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Tên categories từ DB
      final catNames = rawCats
          .map((c) => (c as Map)['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _segments = segs;
          _categoryNames = ['Tất cả', ...catNames];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không kết nối được tới server: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Filter segments theo category đang chọn
  List<Map<String, dynamic>> get _filteredSegments {
    if (_selectedCategory == 'Tất cả') return _segments;
    return _segments.where((seg) {
      final cats = (seg['categories'] as List?) ?? [];
      return cats.any((c) =>
          (c as Map)['name']?.toString() == _selectedCategory);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: AppColors.toriiRed))
                      : _error != null
                          ? _buildError()
                          : _buildScrollBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kPrimary, width: 2),
                  color: Colors.white,
                ),
                child: const Icon(Icons.record_voice_over_rounded,
                    color: _kPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Shadowing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.tune_rounded,
                  color: _kPrimary, size: 20),
              onPressed: _fetchData,
              tooltip: 'Tải lại',
            ),
          ),
        ],
      ),
    );
  }

  // ── Scroll body ──────────────────────────────────────────────────────────────

  Widget _buildScrollBody() {
    final filtered = _filteredSegments;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        const SizedBox(height: 20),
        // Hero header
        const Text(
          'Shadowing',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _kOnSurface,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Chọn chủ đề bạn muốn luyện tập hôm nay.',
          style: TextStyle(
            fontSize: 14,
            color: _kSubtext,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        // ── Category filter chips (từ DB) ──────────────────────────────────
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categoryNames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final cat = _categoryNames[index];
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _kPrimary : _kSurface,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: selected
                          ? _kPrimary
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color:
                                  _kPrimary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? Colors.white : _kSubtext,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // ── Segment cards ──────────────────────────────────────────────────
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
              child: Text('Không có nội dung nào',
                  style: TextStyle(color: _kSubtext)),
            ),
          )
        else
          ...filtered.map((seg) => _buildSegmentCard(seg)),
      ],
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: _kSubtext),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Lỗi không xác định',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSubtext, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Segment card ─────────────────────────────────────────────────────────────

  Widget _buildSegmentCard(Map<String, dynamic> seg) {
    final title = (seg['title'] ?? '').toString().trim();
    final kanji = (seg['kanji_content'] ?? '').toString();
    final romaji = (seg['romaji'] ?? '').toString();
    final meaning = (seg['translation_vi'] ?? '').toString();

    // Tiêu đề hiển thị: ưu tiên title, fallback sang kanji/romaji
    final displayTitle = title.isNotEmpty
        ? title
        : (kanji.isNotEmpty ? kanji : romaji);
    // Sub-title: nếu có title riêng thì show kanji bên dưới
    final displaySub = title.isNotEmpty
        ? (kanji.isNotEmpty ? kanji : meaning)
        : meaning;

    // Categories chips
    final cats = (seg['categories'] as List?) ?? [];
    final catNames =
        cats.map((c) => (c as Map)['name']?.toString() ?? '').toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShadowingScreen(
              segmentId: seg['id'] as int,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Banner / Image ──────────────────────────────────────────────
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (seg['image_url'] != null && seg['image_url'].toString().isNotEmpty)
                      Image.network(
                        seg['image_url'].toString().startsWith('http') 
                          ? seg['image_url'].toString() 
                          : '${ApiConfig.baseUrl}${seg['image_url']}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildGradientFallback(title, kanji),
                      )
                    else
                      _buildGradientFallback(title, kanji),

                    // ID badge góc trái
                    Positioned(
                      top: 12,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kBg.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Text(
                          '#${seg['id']}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kSubtext,
                          ),
                        ),
                      ),
                    ),
                    // Play icon góc phải
                    Positioned(
                      right: 14,
                      bottom: 12,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                        ),
                        child: const Icon(Icons.play_circle_filled_rounded,
                            color: _kPrimary, size: 32),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (tiêu đề chính)
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _kOnSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (displaySub.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        displaySub,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kSubtext,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Category chips
                    if (catNames.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: catNames.map((name) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                              ),
                            ),
                          );
                        }).toList(),
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

  Widget _buildGradientFallback(String title, String kanji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kPrimary.withValues(alpha: 0.12),
            _kPrimary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Text(
          title.isNotEmpty
              ? (title.length > 14 ? '${title.substring(0, 14)}…' : title)
              : (kanji.isNotEmpty
                  ? (kanji.length > 10 ? '${kanji.substring(0, 10)}…' : kanji)
                  : '日本語'),
          style: TextStyle(
            fontSize: title.isNotEmpty ? 18 : 24,
            fontWeight: FontWeight.w800,
            color: AppColors.toriiRed.withValues(alpha: 0.35),
            letterSpacing: title.isNotEmpty ? 0 : 1,
          ),
        ),
      ),
    );
  }
}
