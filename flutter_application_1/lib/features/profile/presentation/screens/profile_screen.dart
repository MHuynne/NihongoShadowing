import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'Alex Sora';
    final email = user?.email ?? 'alex.sora@example.com';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          child: Column(
            children: [
              _ProfileHeader(
                displayName: displayName,
                email: email,
              ),
              const SizedBox(height: 22),
              const _ExperienceCard(),
              const SizedBox(height: 14),
              const _StatsGrid(),
              const SizedBox(height: 18),
              const _ActivityHistoryCard(),
              const SizedBox(height: 18),
              _AccountActions(
                onSignOut: () => _confirmSignOut(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dang xuat?'),
        content: const Text('Ban se quay lai man hinh dang nhap.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.toriiRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Dang xuat'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && context.mounted) {
      await AuthService().signOut();
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;

  const _ProfileHeader({
    required this.displayName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 92,
              height: 92,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow(context, opacity: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/fuji_bg.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const Center(
                      child: Text(
                        '東京',
                        style: TextStyle(
                          color: AppColors.toriiRed,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.toriiRed,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.toriiRed.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              color: AppColors.toriiRed,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              'JLPT N3 Aspirant',
              style: TextStyle(
                color: AppColors.toriiRed,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.warningYellow,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '84 Days',
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.tertiaryText(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context, opacity: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Row(
          children: [
            Container(width: 4, height: 96, color: AppColors.toriiRed),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL EXPERIENCE',
                            style: TextStyle(
                              color: AppColors.tertiaryText(context),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.9,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '15,400 XP',
                            style: TextStyle(
                              color: AppColors.primaryText(context),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.lightPinkBackground,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        color: AppColors.toriiRed,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: const [
        _StatTile(
          icon: Icons.menu_book_outlined,
          label: 'KANJI MASTERED',
          value: '450',
          accent: AppColors.toriiRed,
        ),
        _StatTile(
          icon: Icons.schedule_rounded,
          label: 'STUDY TIME',
          value: '120 hrs',
          accent: AppColors.matcha,
        ),
        _StatTile(
          icon: Icons.check_circle_outline_rounded,
          label: 'LESSONS DONE',
          value: '68',
          accent: AppColors.goldAccent,
        ),
        _StatTile(
          icon: Icons.trending_up_rounded,
          label: 'ACCURACY',
          value: '92%',
          accent: AppColors.progressTeal,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context, opacity: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accent, size: 21),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.tertiaryText(context),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityHistoryCard extends StatelessWidget {
  const _ActivityHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context, opacity: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity History',
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'XP gain over the last 7 days',
                      style: TextStyle(
                        color: AppColors.tertiaryText(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightPinkBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '+12% vs LW',
                  style: TextStyle(
                    color: AppColors.toriiRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _ActivityChartPainter(
                barColor: AppColors.toriiRed,
                mutedColor: AppColors.lightPinkBackground,
                gridColor: AppColors.divider(context),
                textColor: AppColors.tertiaryText(context),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChartPainter extends CustomPainter {
  final Color barColor;
  final Color mutedColor;
  final Color gridColor;
  final Color textColor;

  const _ActivityChartPainter({
    required this.barColor,
    required this.mutedColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final values = [0.42, 0.34, 0.55, 0.28, 0.48, 0.92, 0.62];
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const bottomLabelHeight = 24.0;
    final chartHeight = size.height - bottomLabelHeight;
    final slotWidth = size.width / values.length;
    final barWidth = slotWidth * 0.54;
    final radius = Radius.circular(barWidth / 2);

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartHeight * (0.18 + i * 0.22);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawKana(canvas, size, chartHeight);

    for (var i = 0; i < values.length; i++) {
      final left = slotWidth * i + (slotWidth - barWidth) / 2;
      final height = chartHeight * values[i];
      final top = chartHeight - height;
      final rect = Rect.fromLTWH(left, top, barWidth, height);
      final isPeak = i == 5;
      final paint = Paint()
        ..color = isPeak
            ? barColor
            : Color.lerp(mutedColor, barColor, values[i] * 0.32)!
                .withValues(alpha: isPeak ? 1 : 0.48);

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: radius,
          topRight: radius,
          bottomLeft: const Radius.circular(6),
          bottomRight: const Radius.circular(6),
        ),
        paint,
      );

      final dayPainter = TextPainter(
        text: TextSpan(
          text: days[i],
          style: TextStyle(
            color: isPeak ? barColor : textColor,
            fontSize: 9,
            fontWeight: isPeak ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      dayPainter.paint(
        canvas,
        Offset(
          slotWidth * i + (slotWidth - dayPainter.width) / 2,
          chartHeight + 10,
        ),
      );
    }
  }

  void _drawKana(Canvas canvas, Size size, double chartHeight) {
    final kana = [
      ('あ', Offset(size.width * 0.28, chartHeight * 0.28), 34.0),
      ('A', Offset(size.width * 0.42, chartHeight * 0.18), 28.0),
      ('a', Offset(size.width * 0.51, chartHeight * 0.43), 42.0),
      ('日', Offset(size.width * 0.72, chartHeight * 0.32), 30.0),
    ];

    for (final item in kana) {
      final painter = TextPainter(
        text: TextSpan(
          text: item.$1,
          style: TextStyle(
            color: barColor.withValues(alpha: 0.07),
            fontSize: item.$3,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, item.$2);
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityChartPainter oldDelegate) {
    return oldDelegate.barColor != barColor ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}

class _AccountActions extends StatelessWidget {
  final VoidCallback onSignOut;

  const _AccountActions({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.edit_outlined,
            label: 'Edit profile',
            onTap: () {},
          ),
          Divider(height: 1, color: AppColors.divider(context)),
          _ActionRow(
            icon: Icons.logout_rounded,
            label: 'Sign out',
            color: AppColors.toriiRed,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryText(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.tertiaryText(context),
            ),
          ],
        ),
      ),
    );
  }
}
