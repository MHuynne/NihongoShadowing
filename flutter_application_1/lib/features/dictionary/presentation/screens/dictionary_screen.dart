import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/dictionary/models/dictionary_models.dart';
import 'package:flutter_application_1/features/dictionary/services/dictionary_service.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<DictionaryEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  String _lastQuery = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<String> _recentSearches = [
    '日本語', '勉強する', '桜', '電車', '食べる', 'kawaii', 'arigatou',
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Search logic ─────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _entries = []; _error = null; _lastQuery = ''; });
      _animCtrl.reset();
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 700),
      () => _doSearch(value.trim()),
    );
  }

  Future<void> _doSearch(String query) async {
    if (query == _lastQuery && _entries.isNotEmpty) return;
    _lastQuery = query;
    setState(() { _isLoading = true; _error = null; });
    _animCtrl.reset();

    try {
      final result = await DictionaryService.search(query);
      if (!mounted) return;
      setState(() { _entries = result.entries; _isLoading = false; });
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      }
      _animCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải kết quả.\nKiểm tra server backend đang chạy.';
        _isLoading = false;
      });
    }
  }

  void _searchChip(String word) {
    _searchCtrl.text = word;
    _focusNode.unfocus();
    _doSearch(word);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Purple-tinted gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF3E8FF), Color(0xFFFCF7FF), Colors.white],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                const SizedBox(height: 4),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColors.slate700),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '辞書 • Từ điển',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9333EA),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Nhật - Việt',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFFD946EF)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.translate_rounded,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          onSubmitted: (v) { if (v.trim().isNotEmpty) _doSearch(v.trim()); },
          style: const TextStyle(fontSize: 17, color: AppColors.slate800),
          decoration: InputDecoration(
            hintText: 'Nhập tiếng Nhật, romaji, tiếng Việt...',
            hintStyle:
                const TextStyle(color: AppColors.slate400, fontSize: 14),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 10),
              child: Icon(Icons.search_rounded,
                  color: Color(0xFF9333EA), size: 24),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 52, minHeight: 52),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(Icons.cancel_rounded,
                          color: AppColors.slate300, size: 20),
                    ),
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 42, minHeight: 42),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          ),
        ),
      ),
    );
  }

  // ── Body dispatcher ───────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_entries.isNotEmpty) return _buildResults();
    return _buildEmpty();
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: const Color(0xFF9333EA),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Đang tra từ điển và dịch sang tiếng Việt...',
              style: TextStyle(color: AppColors.slate500, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('(có thể mất vài giây)',
              style: TextStyle(color: AppColors.slate400, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 40, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.slate600, fontSize: 15, height: 1.5)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _doSearch(_lastQuery),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.history_rounded, size: 18, color: Color(0xFF9333EA)),
              SizedBox(width: 6),
              Text('Tìm kiếm gần đây',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate700)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map(_buildChip).toList(),
          ),
          const SizedBox(height: 28),
          _buildTipsCard(),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return GestureDetector(
      onTap: () => _searchChip(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF9333EA).withValues(alpha: 0.25)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Color(0xFF7E22CE),
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF9333EA).withValues(alpha: 0.07),
          const Color(0xFFD946EF).withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF9333EA).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.tips_and_updates_rounded,
                size: 18, color: Color(0xFF9333EA)),
            SizedBox(width: 8),
            Text('Mẹo tìm kiếm',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7E22CE))),
          ]),
          const SizedBox(height: 10),
          ...[
            '🇯🇵  Kanji:     食べる、勉強',
            '🔤  Hiragana:  たべる、べんきょう',
            '🔠  Romaji:    taberu, benkyou',
            '🇻🇳  Tiếng Việt: ăn, học',
            '🇬🇧  Tiếng Anh:  eat, study',
          ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(t,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate600,
                        height: 1.4)),
              )),
        ],
      ),
    );
  }

  // ── Results list ──────────────────────────────────────────────────────────

  Widget _buildResults() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _EntryCard(entry: _entries[i]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Entry Card — hiển thị 1 từ
// ════════════════════════════════════════════════════════════════════════════

class _EntryCard extends StatefulWidget {
  final DictionaryEntry entry;
  const _EntryCard({required this.entry});

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final entry      = widget.entry;
    final jlptLabel  = entry.jlptLabel;
    final firstSense = entry.senses.isNotEmpty ? entry.senses.first : null;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _expanded
                ? const Color(0xFF9333EA).withValues(alpha: 0.45)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA)
                  .withValues(alpha: _expanded ? 0.13 : 0.06),
              blurRadius: _expanded ? 18 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: word + reading + badges ────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.displayWord,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate800,
                            height: 1.1,
                          ),
                        ),
                        if (entry.reading.isNotEmpty &&
                            entry.reading != entry.word) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.reading,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9333EA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (jlptLabel.isNotEmpty)
                        _buildBadge(
                          jlptLabel,
                          _jlptColor(jlptLabel),
                        ),
                      if (entry.isCommon) ...[
                        const SizedBox(height: 5),
                        _buildBadge(
                          '✓ Thường dùng',
                          AppColors.matcha,
                          bgColor: AppColors.matchaLight,
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── First sense (preview) ──────────────────────────────────
              if (firstSense != null) _buildSenseTile(firstSense, index: 1),

              // ── Expanded: remaining senses ─────────────────────────────
              SizeTransition(
                sizeFactor: _expandAnim,
                child: Column(
                  children: [
                    for (int i = 1; i < entry.senses.length; i++) ...[
                      const Divider(height: 18, thickness: 0.5),
                      _buildSenseTile(entry.senses[i], index: i + 1),
                    ],
                    // Kanji variants
                    if (entry.japanese.length > 1) ...[
                      const Divider(height: 18, thickness: 0.5),
                      _buildVariantsRow(entry.japanese),
                    ],
                  ],
                ),
              ),

              // ── Expand toggle ──────────────────────────────────────────
              if (entry.senses.length > 1) ...[
                const SizedBox(height: 6),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.slate400, size: 20),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _expanded
                            ? 'Thu gọn'
                            : 'Xem thêm ${entry.senses.length - 1} nghĩa',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.slate400),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSenseTile(DictionarySense sense, {required int index}) {
    final posList   = sense.displayPos;
    final viDefs    = sense.viDefinitions;
    final enDefs    = sense.englishDefinitions;
    final hasVi     = viDefs.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Index circle
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 1),
          decoration: const BoxDecoration(
            color: Color(0xFFF3E8FF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$index',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9333EA))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Parts of speech
              if (posList.isNotEmpty)
                Text(
                  posList.join(' · '),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9333EA),
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (posList.isNotEmpty) const SizedBox(height: 4),

              // Vietnamese definition (chính)
              if (hasVi)
                Text(
                  viDefs.join(', '),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.slate800,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),

              // English definition (phụ, nhỏ hơn)
              if (enDefs.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  enDefs.join('; '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate400,
                    height: 1.35,
                  ),
                ),
              ],

              // Info / tags
              if (sense.info.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '📝 ${sense.info.join(', ')}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.slate400),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariantsRow(List<Map<String, dynamic>> japanese) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Các dạng viết:',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.slate400,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: japanese.map((j) {
            final w = j['word']    as String? ?? '';
            final r = j['reading'] as String? ?? '';
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                w.isNotEmpty ? (r.isNotEmpty ? '$w【$r】' : w) : r,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7E22CE),
                    fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color textColor,
      {Color? bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? textColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor)),
    );
  }

  Color _jlptColor(String label) {
    switch (label) {
      case 'N1': return const Color(0xFFDC2626);
      case 'N2': return const Color(0xFFEA580C);
      case 'N3': return const Color(0xFFCA8A04);
      case 'N4': return const Color(0xFF16A34A);
      case 'N5': return const Color(0xFF2563EB);
      default:   return AppColors.slate500;
    }
  }
}
