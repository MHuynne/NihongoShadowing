import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/shadowing/presentation/screens/shadowing_screen.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/core/services/user_prefs_service.dart';

const _kBg      = Color(0xFFF8F9FE); // Light background with soft tint
const _kSurface = Colors.white;
const _kOnSurface = Color(0xFF2D3142); // Softer dark text
const _kSubtext   = Color(0xFF9098A9);
const _kPrimary   = Color(0xFFFF4D6D); // Sakura Pink / Dark Cherry Blossom


class ShadowingTopicListScreen extends StatefulWidget {
  const ShadowingTopicListScreen({super.key});

  @override
  State<ShadowingTopicListScreen> createState() =>
      _ShadowingTopicListScreenState();
}

class _ShadowingTopicListScreenState extends State<ShadowingTopicListScreen> {
  bool _isLoading = true;
  String? _error;

  /// Level đã chọn của user (từ onboarding)
  String _userLevel = 'N5';

  /// Tất cả segment topics từ API
  List<Map<String, dynamic>> _topics = [];

  /// Danh sách categories từ DB (thêm "Tất cả" ở đầu)
  List<String> _categoryNames = ['Tất cả'];

  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadLevelAndData();
  }

  Future<void> _loadLevelAndData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final level = await UserPrefsService().getLevel(uid);
      if (mounted && level != null) {
        setState(() => _userLevel = level);
      }
    }
    await _fetchData();
  }

  String get _base => ApiConfig.baseUrl;

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Gọi song song: topics + categories
      final results = await Future.wait([
        http.get(Uri.parse('$_base/segment-topics/')),
        http.get(Uri.parse('$_base/categories/')),
      ]);

      final topicRes = results[0];
      final catRes = results[1];

      if (topicRes.statusCode != 200) {
        throw Exception('Lỗi tải topics: HTTP ${topicRes.statusCode}');
      }
      if (catRes.statusCode != 200) {
        throw Exception('Lỗi tải categories: HTTP ${catRes.statusCode}');
      }

      final List<dynamic> rawTopics = json.decode(utf8.decode(topicRes.bodyBytes));
      final List<dynamic> rawCats = json.decode(utf8.decode(catRes.bodyBytes));

      final topics = rawTopics
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Tên categories từ DB
      final catNames = rawCats
          .map((c) => (c as Map)['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _topics = topics;
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

  /// Filter topics theo category đang chọn và level đã chọn
  List<Map<String, dynamic>> get _filteredTopics {
    // Lọc theo level trước
    final byLevel = _topics.where((topic) {
      final topicLevel = (topic['level'] ?? '').toString();
      // Nếu topic chưa gán level thì hiển thị cho tất cả (null/empty = không lọc)
      return topicLevel.isEmpty || topicLevel == _userLevel;
    }).toList();

    // Tiếp theo lọc theo category
    if (_selectedCategory == 'Tất cả') return byLevel;
    return byLevel.where((topic) {
      final cats = (topic['categories'] as List?) ?? [];
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
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: _kPrimary))
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
    // Màu badge theo level
    Color levelColor;
    switch (_userLevel) {
      case 'N4': levelColor = const Color(0xFF2196F3); break;
      case 'N3': levelColor = const Color(0xFFFF9800); break;
      case 'N2': levelColor = const Color(0xFF9C27B0); break;
      case 'N1': levelColor = const Color(0xFFE91E63); break;
      default:   levelColor = const Color(0xFF4CAF50); // N5
    }

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shadowing',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Level badge — chỉ hiển thị, không cho thay đổi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: levelColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Cấp độ: $_userLevel',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: levelColor,
                      ),
                    ),
                  ),
                ],
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
              onPressed: _loadLevelAndData,
              tooltip: 'Tải lại',
            ),
          ),
        ],
      ),
    );
  }

  // ── Scroll body ──────────────────────────────────────────────────────────────

  Widget _buildScrollBody() {
    final filtered = _filteredTopics;

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
        Text(
          'Chủ đề luyện tập cấp độ $_userLevel — chọn bài bạn muốn luyện hôm nay.',
          style: const TextStyle(
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
          ...filtered.map((topic) => _buildTopicCard(topic)),
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

  // ── Topic card ─────────────────────────────────────────────────────────────

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    final title = (topic['title'] ?? '').toString().trim();
    final description = (topic['description'] ?? '').toString();
    final segmentsCount = (topic['segments'] as List?)?.length ?? 0;

    // Categories chips
    final cats = (topic['categories'] as List?) ?? [];
    final catNames =
        cats.map((c) => (c as Map)['name']?.toString() ?? '').toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShadowingScreen(
              segmentTopicId: topic['id'] as int,
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
                    if (topic['image_url'] != null && topic['image_url'].toString().isNotEmpty)
                      Image.network(
                        topic['image_url'].toString().startsWith('http') 
                          ? topic['image_url'].toString() 
                          : '${ApiConfig.baseUrl}${topic['image_url']}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildGradientFallback(title, ''),
                      )
                    else
                      _buildGradientFallback(title, ''),

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
                          '$segmentsCount segments',
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
                      title.isNotEmpty ? title : 'Chưa có tiêu đề',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _kOnSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kSubtext,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
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
            color: _kPrimary.withValues(alpha: 0.35),
            letterSpacing: title.isNotEmpty ? 0 : 1,
          ),
        ),
      ),
    );
  }
}
