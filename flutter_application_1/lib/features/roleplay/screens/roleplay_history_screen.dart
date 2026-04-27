import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../roleplay_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/grammar_feedback_box.dart';

class RoleplayHistoryScreen extends StatefulWidget {
  const RoleplayHistoryScreen({super.key});

  @override
  State<RoleplayHistoryScreen> createState() => _RoleplayHistoryScreenState();
}

class _RoleplayHistoryScreenState extends State<RoleplayHistoryScreen> {
  final RoleplayService _apiService = RoleplayService();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.getChatHistory();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = _apiService.getChatHistory();
    });
    await _historyFuture;
  }

  String _formatDate(dynamic rawValue) {
    if (rawValue == null) return '';

    try {
      final date = DateTime.parse(rawValue.toString()).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return rawValue.toString();
    }
  }

  String _modeLabel(String? mode) {
    return mode == 'keigo' ? 'Kính ngữ' : 'Plain';
  }

  String _messagePreview(Map<String, dynamic> session) {
    final message = (session['last_message'] ?? '').toString().trim();
    if (message.isEmpty) return 'Chưa có nội dung';

    final role = session['last_role'] == 'user' ? 'Bạn' : 'Sensei';
    return '$role: $message';
  }

  void _openSession(Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoleplayHistoryDetailScreen(
          sessionId: session['id'] as int,
          fallbackTitle: session['scenario_title']?.toString() ?? 'Roleplay',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        foregroundColor: AppColors.primaryText(context),
        title: const Text('Lịch sử roleplay'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _HistoryStatus(
              icon: Icons.cloud_off_rounded,
              title: 'Không tải được lịch sử',
              message: 'Kiểm tra backend rồi thử lại.',
              actionLabel: 'Thử lại',
              onPressed: _refreshHistory,
            );
          }

          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return _HistoryStatus(
              icon: Icons.history_rounded,
              title: 'Chưa có lịch sử chat',
              message:
                  'Sau khi bạn trò chuyện, các phiên roleplay sẽ xuất hiện ở đây.',
              actionLabel: 'Làm mới',
              onPressed: _refreshHistory,
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _HistorySessionTile(
                  title: session['scenario_title']?.toString() ?? 'Roleplay',
                  description: session['scenario_description']?.toString(),
                  mode: _modeLabel(session['mode']?.toString()),
                  date: _formatDate(
                      session['last_message_at'] ?? session['created_at']),
                  messageCount: session['message_count'] as int? ?? 0,
                  preview: _messagePreview(session),
                  onTap: () => _openSession(session),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class RoleplayHistoryDetailScreen extends StatefulWidget {
  final int sessionId;
  final String fallbackTitle;

  const RoleplayHistoryDetailScreen({
    super.key,
    required this.sessionId,
    required this.fallbackTitle,
  });

  @override
  State<RoleplayHistoryDetailScreen> createState() =>
      _RoleplayHistoryDetailScreenState();
}

class _RoleplayHistoryDetailScreenState
    extends State<RoleplayHistoryDetailScreen> {
  final RoleplayService _apiService = RoleplayService();
  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _apiService.getChatHistoryDetail(widget.sessionId);
  }

  String _modeLabel(String? mode) {
    return mode == 'keigo' ? 'Lịch sự / Kính ngữ' : 'Thân mật / Plain';
  }

  List<Widget> _buildHistoryItems(List<dynamic> messages) {
    final items = <Widget>[];

    for (final rawMessage in messages) {
      if (rawMessage is! Map<String, dynamic>) continue;

      final isUser = rawMessage['role'] == 'user';
      items.add(ChatBubble(
        text: rawMessage['content']?.toString() ?? '',
        isUser: isUser,
      ));

      final feedback = rawMessage['grammar_correction'];
      if (feedback is Map<String, dynamic>) {
        items.add(GrammarFeedbackBox(
          error: feedback['error']?.toString() ?? '',
          correction: feedback['correction']?.toString() ?? '',
          explanation: feedback['explanation']?.toString() ?? '',
        ));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        foregroundColor: AppColors.primaryText(context),
        title: Text(
          widget.fallbackTitle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _HistoryStatus(
              icon: Icons.error_outline_rounded,
              title: 'Không mở được phiên chat',
              message: 'Phiên này có thể đã bị xóa hoặc backend chưa sẵn sàng.',
              actionLabel: 'Quay lại',
              onPressed: () => Navigator.of(context).pop(),
            );
          }

          final detail = snapshot.data!;
          final messages = detail['messages'] as List<dynamic>? ?? [];
          final items = _buildHistoryItems(messages);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  border: Border(
                    bottom: BorderSide(color: AppColors.border(context)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_fix_high,
                      size: 16,
                      color: AppColors.primary.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _modeLabel(detail['mode']?.toString()),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: items[index],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistorySessionTile extends StatelessWidget {
  final String title;
  final String? description;
  final String mode;
  final String date;
  final int messageCount;
  final String preview;
  final VoidCallback onTap;

  const _HistorySessionTile({
    required this.title,
    required this.description,
    required this.mode,
    required this.date,
    required this.messageCount,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.softAccentSurface(
                          context, AppColors.primary),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primaryText(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (description != null && description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.secondaryText(context),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.tertiaryText(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.translate_rounded,
                    label: mode,
                  ),
                  _InfoPill(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '$messageCount tin nhắn',
                  ),
                  _InfoPill(
                    icon: Icons.schedule_rounded,
                    label: date,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputFill(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondaryText(context)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryStatus extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onPressed;

  const _HistoryStatus({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.tertiaryText(context)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
