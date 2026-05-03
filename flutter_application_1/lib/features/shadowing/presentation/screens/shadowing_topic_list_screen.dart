import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/shadowing/presentation/screens/shadowing_screen.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _kBg = Color(0xFFF8F5F5);
const _kSurface = Color(0xFFFFFFFF);
const _kOnSurface = Color(0xFF1E1E1E);
const _kSubtext = Color(0xFF6D7A77);
const _kMint = Color(0xFFFFECED);

class ShadowingTopicListScreen extends StatefulWidget {
  const ShadowingTopicListScreen({super.key});

  @override
  State<ShadowingTopicListScreen> createState() =>
      _ShadowingTopicListScreenState();
}

class _ShadowingTopicListScreenState extends State<ShadowingTopicListScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _topics = [];
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = ['Tất cả', 'Giao tiếp', 'Công việc', 'Du lịch', 'JLPT N3'];

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    String apiUrl = 'http://localhost:8000/shadowing/topics/';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      apiUrl = 'http://10.0.2.2:8000/shadowing/topics/';
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _topics = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Lỗi HTTP ${response.statusCode}';
            _isLoading = false;
          });
        }
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

  List<dynamic> get _filteredTopics {
    if (_selectedCategory == 'Tất cả') return _topics;
    return _topics.where((t) {
      final level = (t['level'] ?? '').toString();
      switch (_selectedCategory) {
        case 'JLPT N3':
          return level == 'N3';
        case 'Giao tiếp':
          return level == 'N5' || level == 'N4';
        case 'Công việc':
          return level == 'N3' || level == 'N2';
        case 'Du lịch':
          return level == 'N4' || level == 'N5';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Soft Sakura background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color(0xFFF5E8E9),
                    Color(0xFFEEDFE1),
                    Colors.white,
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),
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

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.toriiRed.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  border: Border.all(color: AppColors.toriiRed, width: 2),
                  color: _kMint,
                ),
                child: const Icon(Icons.record_voice_over_rounded,
                    color: AppColors.toriiRed, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Shadowing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.toriiRed,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kMint,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.tune_rounded, color: AppColors.toriiRed, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        // Hero header
        const Text(
          'Shadowing Topics',
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
          'Chọn chủ đề bạn muốn luyện tập hôm nay.',
          style: TextStyle(
            fontSize: 14,
            color: _kSubtext.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        // Category filter chips
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final selected = _selectedCategory == _categories[index];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedCategory = _categories[index]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.toriiRed : _kSurface,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: selected ? AppColors.toriiRed : const Color(0xFFE8D5D6),
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.toriiRed.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    _categories[index],
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

        // Topic cards
        if (_filteredTopics.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
              child: Text('Không có chủ đề nào',
                  style: TextStyle(color: _kSubtext)),
            ),
          )
        else
          ...List.generate(
            _filteredTopics.length,
            (i) => _buildTopicCard(_filteredTopics[i], i),
          ),
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
                backgroundColor: AppColors.toriiRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchTopics();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(dynamic topic, int index) {
    final title = topic['title']?.toString() ?? 'Chủ đề';
    final level = topic['level']?.toString() ?? 'N4';
    final duration = topic['total_duration'];
    final imageUrl = topic['image_url']?.toString();

    // Tiến độ demo
    final double progress = (index % 3 == 0)
        ? 0.6
        : (index % 3 == 1)
            ? 0.12
            : 1.0;
    final bool isCompleted = progress >= 1.0;
    final String progressLabel = isCompleted
        ? 'Hoàn tất'
        : (progress > 0 ? 'Đang học' : 'Chưa bắt đầu');

    // Level badge colours
    final Color badgeColor;
    final Color badgeBg;
    switch (level) {
      case 'N5':
      case 'N4':
        badgeBg = const Color(0xFFE8F5E9);
        badgeColor = const Color(0xFF2E7D32);
        break;
      case 'N3':
        badgeBg = const Color(0xFFE3F2FD);
        badgeColor = const Color(0xFF1565C0);
        break;
      case 'N2':
        badgeBg = const Color(0xFFFFF3E0);
        badgeColor = const Color(0xFFE65100);
        break;
      default:
        badgeBg = _kMint;
        badgeColor = AppColors.toriiRed;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ShadowingScreen(topicId: topic['id'])),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.toriiRed.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image banner
              SizedBox(
                height: 180,
                width: double.infinity,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => _buildImagePlaceholder(level),
                      )
                    : _buildImagePlaceholder(level),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge + duration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'JLPT $level',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13, color: _kSubtext.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              duration != null
                                  ? '${duration.round()} phút'
                                  : '3 phút',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _kSubtext.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kOnSurface,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Japanese subtitle from segments
                    Text(
                      _getJapaneseSubtitle(topic),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kSubtext.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),

                    // Progress row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 38,
                              height: 38,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 3.5,
                                    color: const Color(0xFFEEDFDF),
                                  ),
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 3.5,
                                    color: AppColors.toriiRed,
                                    strokeCap: StrokeCap.round,
                                  ),
                                  Center(
                                    child: Text(
                                      '${(progress * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.toriiRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              progressLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kSubtext,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.toriiRed.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.toriiRed,
                            size: 22,
                          ),
                        ),
                      ],
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

  String _getJapaneseSubtitle(dynamic topic) {
    final segments = topic['segments'] as List?;
    if (segments != null && segments.isNotEmpty) {
      final first = segments[0];
      return first['kanji_content']?.toString() ??
          first['furigana']?.toString() ??
          '日本語の練習';
    }
    final script = topic['full_script_ja']?.toString() ?? '';
    if (script.isNotEmpty) return script.split('\n').first;
    return '日本語の練習';
  }

  Widget _buildImagePlaceholder(String level) {
    return Container(
      color: _kMint,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.record_voice_over_rounded,
                size: 48, color: AppColors.toriiRed.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              'JLPT $level',
              style: TextStyle(
                  color: AppColors.toriiRed.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
