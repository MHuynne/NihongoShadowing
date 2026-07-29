import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/shadowing/presentation/screens/shadowing_screen.dart';
import 'package:flutter_application_1/core/theme/sakura_theme.dart';
import 'package:flutter_application_1/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter_application_1/core/network/app_http_client.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/core/services/user_prefs_service.dart';

const _kPrimary = SNJ.sakura;

class ShadowingTopicListScreen extends StatefulWidget {
  const ShadowingTopicListScreen({super.key});

  @override
  State<ShadowingTopicListScreen> createState() =>
      _ShadowingTopicListScreenState();
}

class _ShadowingTopicListScreenState extends State<ShadowingTopicListScreen> {
  bool _isLoading = true;
  String? _error;
  String _userLevel = 'N5';
  List<Map<String, dynamic>> _topics = [];
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

  List<Map<String, dynamic>> get _filteredTopics {
    final byLevel = _topics.where((topic) {
      final topicLevel = (topic['level'] ?? '').toString();
      return topicLevel.isEmpty || topicLevel == _userLevel;
    }).toList();

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
      backgroundColor: Colors.transparent,
      body: SakuraNightBackground(
        child: SafeArea(
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
      ),
    );
  }

  Widget _buildTopBar() {
    Color levelColor;
    switch (_userLevel) {
      case 'N4':
        levelColor = const Color(0xFF60A5FA);
        break;
      case 'N3':
        levelColor = const Color(0xFFF59E0B);
        break;
      case 'N2':
        levelColor = const Color(0xFFC084FC);
        break;
      case 'N1':
        levelColor = SNJ.sakura;
        break;
      default:
        levelColor = const Color(0xFF34D399);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1.0,
          ),
        ),
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
                  gradient: SNJ.sakuraGradient,
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shadowing',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: levelColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Cấp độ: $_userLevel',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.tune_rounded,
                  color: Colors.white, size: 20),
              onPressed: _loadLevelAndData,
              tooltip: 'Tải lại',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollBody() {
    final filtered = _filteredTopics;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        const SizedBox(height: 24),
        const Text(
          'Luyện tập phát âm',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Chủ đề luyện tập cấp độ $_userLevel — chọn bài bạn muốn luyện hôm nay.',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFCCB8D8),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
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
                    gradient: selected ? SNJ.sakuraGradient : null,
                    color: selected ? null : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.08),
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _kPrimary.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFCCB8D8),
                      fontWeight:
                          selected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
              child: Text(
                'Không có nội dung nào',
                style: TextStyle(color: Color(0xFFCCB8D8), fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          ...filtered.map((topic) => _buildTopicCard(topic)),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFFCCB8D8)),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Lỗi không xác định',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFCCB8D8), fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: SNJ.sakuraGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    final title = (topic['title'] ?? '').toString().trim();
    final description = (topic['description'] ?? '').toString();
    final segmentsCount = (topic['segments'] as List?)?.length ?? 0;

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
        child: GlassCard(
          neonBorder: true,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
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
                    Positioned(
                      top: 12,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Text(
                          '$segmentsCount segments',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SNJ.sakuraGradient,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isNotEmpty ? title : 'Chưa có tiêu đề',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
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
                          color: Color(0xFFCCB8D8),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (catNames.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: catNames.map((name) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _kPrimary.withOpacity(0.2)),
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
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
            _kPrimary.withOpacity(0.12),
            _kPrimary.withOpacity(0.02),
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
            fontWeight: FontWeight.w900,
            color: _kPrimary.withOpacity(0.35),
            letterSpacing: title.isNotEmpty ? 0 : 1,
          ),
        ),
      ),
    );
  }
}