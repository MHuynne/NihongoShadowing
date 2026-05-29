import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/features/roadmap/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _targetLevelKey = 'profile_target_level';

  final _auth = AuthService();
  Future<_ProfileData>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfileData();
  }

  Future<_ProfileData> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final targetLevel = prefs.getString(_targetLevelKey) ?? 'N3';
    final progress = await ProgressService.getAllProgress();
    return _ProfileData(
      targetLevel: targetLevel,
      stats: _ProfileStats.fromProgress(progress),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = _loadProfileData();
    });
    await _profileFuture;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground(context),
      body: SafeArea(
        child: FutureBuilder<_ProfileData>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final data = snapshot.data ?? _ProfileData.empty();
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return RefreshIndicator(
              color: AppColors.toriiRed,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                child: Column(
                  children: [
                    _ProfileHeader(
                      user: user,
                      targetLevel: data.targetLevel,
                      streakDays: data.stats.streakDays,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 22),
                    _ExperienceCard(stats: data.stats),
                    const SizedBox(height: 14),
                    _StatsGrid(stats: data.stats),
                    const SizedBox(height: 18),
                    _ActivityHistoryCard(stats: data.stats),
                    const SizedBox(height: 18),
                    _AccountActions(
                      user: user,
                      onEditProfile: () => _showEditProfileSheet(
                        user: user,
                        targetLevel: data.targetLevel,
                      ),
                      onVerifyEmail: _sendVerificationEmail,
                      onResetPassword: () => _sendPasswordReset(user?.email),
                      onChangePassword: _showChangePasswordDialog,
                      onDeleteAccount: _confirmDeleteAccount,
                      onSignOut: () => _confirmSignOut(context),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showEditProfileSheet({
    required User? user,
    required String targetLevel,
  }) async {
    final nameController = TextEditingController(
      text: user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!.trim()
          : '',
    );
    final photoController = TextEditingController(text: user?.photoURL ?? '');
    var selectedLevel = targetLevel;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetHandle(),
                  const SizedBox(height: 18),
                  Text(
                    'Edit profile',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ProfileTextField(
                    controller: nameController,
                    label: 'Display name',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  _ProfileTextField(
                    controller: photoController,
                    label: 'Avatar image URL',
                    icon: Icons.image_outlined,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Target JLPT level',
                    style: TextStyle(
                      color: AppColors.secondaryText(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['N5', 'N4', 'N3', 'N2', 'N1'].map((level) {
                      final selected = selectedLevel == level;
                      return ChoiceChip(
                        label: Text(level),
                        selected: selected,
                        selectedColor: AppColors.lightPinkBackground,
                        checkmarkColor: AppColors.toriiRed,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.toriiRed
                              : AppColors.primaryText(context),
                          fontWeight: FontWeight.w900,
                        ),
                        onSelected: (_) {
                          setSheetState(() => selectedLevel = level);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.toriiRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          _showSnack('Display name is required.');
                          return;
                        }

                        try {
                          await _auth.updateProfile(
                            displayName: nameController.text,
                            photoUrl: photoController.text,
                          );
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            _targetLevelKey,
                            selectedLevel,
                          );
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop(true);
                          }
                        } on FirebaseAuthException catch (e) {
                          _showSnack(AuthService.getVietnameseError(e));
                        } catch (e) {
                          _showSnack('Could not update profile: $e');
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    photoController.dispose();

    if (saved == true && mounted) {
      _showSnack('Profile updated.');
      await _refresh();
      setState(() {});
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await _auth.sendEmailVerification();
      _showSnack('Verification email sent.');
    } on FirebaseAuthException catch (e) {
      _showSnack(AuthService.getVietnameseError(e));
    } catch (e) {
      _showSnack('Could not send verification email: $e');
    }
  }

  Future<void> _sendPasswordReset(String? email) async {
    if (email == null || email.trim().isEmpty) {
      _showSnack('This account has no email address.');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email);
      _showSnack('Password reset email sent.');
    } on FirebaseAuthException catch (e) {
      _showSnack(AuthService.getVietnameseError(e));
    } catch (e) {
      _showSnack('Could not send reset email: $e');
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.toriiRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final password = controller.text.trim();
              if (password.length < 6) {
                _showSnack('Password must be at least 6 characters.');
                return;
              }
              if (password != confirmController.text.trim()) {
                _showSnack('Passwords do not match.');
                return;
              }

              try {
                await _auth.updatePassword(password);
                if (context.mounted) Navigator.of(context).pop(true);
              } on FirebaseAuthException catch (e) {
                _showSnack(AuthService.getVietnameseError(e));
              } catch (e) {
                _showSnack('Could not change password: $e');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    controller.dispose();
    confirmController.dispose();
    if (changed == true) _showSnack('Password updated.');
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This removes your Firebase account from this device session. You may need to sign in again recently before Firebase allows deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _auth.deleteAccount();
    } on FirebaseAuthException catch (e) {
      _showSnack(AuthService.getVietnameseError(e));
    } catch (e) {
      _showSnack('Could not delete account: $e');
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will return to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.toriiRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && context.mounted) {
      await _auth.signOut();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileData {
  final String targetLevel;
  final _ProfileStats stats;

  const _ProfileData({
    required this.targetLevel,
    required this.stats,
  });

  factory _ProfileData.empty() {
    return _ProfileData(
      targetLevel: 'N3',
      stats: _ProfileStats.empty(),
    );
  }
}

class _ProfileStats {
  final int totalXp;
  final int lessonsDone;
  final int flashcardsDone;
  final int studyMinutes;
  final int averageAccuracy;
  final int streakDays;
  final List<int> xpLast7Days;

  const _ProfileStats({
    required this.totalXp,
    required this.lessonsDone,
    required this.flashcardsDone,
    required this.studyMinutes,
    required this.averageAccuracy,
    required this.streakDays,
    required this.xpLast7Days,
  });

  factory _ProfileStats.empty() {
    return const _ProfileStats(
      totalXp: 0,
      lessonsDone: 0,
      flashcardsDone: 0,
      studyMinutes: 0,
      averageAccuracy: 0,
      streakDays: 0,
      xpLast7Days: [0, 0, 0, 0, 0, 0, 0],
    );
  }

  factory _ProfileStats.fromProgress(List<Map<String, dynamic>> progress) {
    if (progress.isEmpty) return _ProfileStats.empty();

    var lessonsDone = 0;
    var flashcardsDone = 0;
    var studyMinutes = 0;
    var totalXp = 0;
    final scores = <double>[];
    final xpByDay = <DateTime, int>{};
    final activeDays = <DateTime>{};

    for (final item in progress) {
      final flashcardDone = item['flashcard_done'] == true;
      final lessonCompleted = item['lesson_completed'] == true;
      final testScore = _asDouble(item['test_score']);
      final shadowingScore = _asDouble(item['shadowing_score']);
      final updatedAt = _parseDate(item['updated_at']);
      final day = updatedAt == null ? null : _dateOnly(updatedAt);

      if (flashcardDone) {
        flashcardsDone++;
        studyMinutes += 5;
        totalXp += 20;
      }
      if (testScore != null) {
        scores.add(testScore);
        studyMinutes += 8;
        totalXp += testScore.round();
      }
      if (shadowingScore != null) {
        scores.add(shadowingScore);
        studyMinutes += 10;
        totalXp += shadowingScore.round();
      }
      if (lessonCompleted) {
        lessonsDone++;
        totalXp += 120;
      }
      if (day != null &&
          (flashcardDone || testScore != null || shadowingScore != null)) {
        activeDays.add(day);
        xpByDay[day] = (xpByDay[day] ?? 0) +
            _xpForRecord(
              flashcardDone: flashcardDone,
              lessonCompleted: lessonCompleted,
              testScore: testScore,
              shadowingScore: shadowingScore,
            );
      }
    }

    final now = _dateOnly(DateTime.now());
    final xpLast7Days = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return xpByDay[day] ?? 0;
    });

    return _ProfileStats(
      totalXp: totalXp,
      lessonsDone: lessonsDone,
      flashcardsDone: flashcardsDone,
      studyMinutes: studyMinutes,
      averageAccuracy: scores.isEmpty
          ? 0
          : (scores.reduce((a, b) => a + b) / scores.length).round(),
      streakDays: _streakFromDays(activeDays),
      xpLast7Days: xpLast7Days,
    );
  }

  static int _xpForRecord({
    required bool flashcardDone,
    required bool lessonCompleted,
    required double? testScore,
    required double? shadowingScore,
  }) {
    return (flashcardDone ? 20 : 0) +
        (lessonCompleted ? 120 : 0) +
        (testScore?.round() ?? 0) +
        (shadowingScore?.round() ?? 0);
  }

  static int _streakFromDays(Set<DateTime> activeDays) {
    if (activeDays.isEmpty) return 0;
    var cursor = _dateOnly(DateTime.now());
    if (!activeDays.contains(cursor)) {
      final yesterday = cursor.subtract(const Duration(days: 1));
      if (!activeDays.contains(yesterday)) return 0;
      cursor = yesterday;
    }

    var streak = 0;
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class _ProfileHeader extends StatelessWidget {
  final User? user;
  final String targetLevel;
  final int streakDays;
  final bool isLoading;

  const _ProfileHeader({
    required this.user,
    required this.targetLevel,
    required this.streakDays,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'Learner';
    final email = user?.email ?? 'No email';
    final photoUrl = user?.photoURL;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(8),
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
                borderRadius: BorderRadius.circular(22),
                child: _Avatar(photoUrl: photoUrl, displayName: displayName),
              ),
            ),
            Positioned(
              bottom: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: user?.emailVerified == true
                      ? AppColors.progressTeal
                      : AppColors.warningYellow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  user?.emailVerified == true ? 'VERIFIED' : 'UNVERIFIED',
                  style: const TextStyle(
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
            const Icon(Icons.school_outlined,
                color: AppColors.toriiRed, size: 14),
            const SizedBox(width: 5),
            Text(
              'JLPT $targetLevel Aspirant',
              style: const TextStyle(
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
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.warningYellow, size: 16),
              const SizedBox(width: 6),
              Text(
                isLoading ? 'Loading...' : '$streakDays day streak',
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

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;

  const _Avatar({
    required this.photoUrl,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _InitialsAvatar(displayName: displayName),
      );
    }
    return _InitialsAvatar(displayName: displayName);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String displayName;

  const _InitialsAvatar({required this.displayName});

  @override
  Widget build(BuildContext context) {
    final initials = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lightPinkBackground, AppColors.lightTealGreen],
        ),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? 'U' : initials,
          style: const TextStyle(
            color: AppColors.toriiRed,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final _ProfileStats stats;

  const _ExperienceCard({required this.stats});

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
                            '${stats.totalXp} XP',
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
                      decoration: const BoxDecoration(
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
  final _ProfileStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        _StatTile(
          icon: Icons.style_outlined,
          label: 'FLASHCARDS DONE',
          value: '${stats.flashcardsDone}',
          accent: AppColors.toriiRed,
        ),
        _StatTile(
          icon: Icons.schedule_rounded,
          label: 'STUDY TIME',
          value: _formatStudyTime(stats.studyMinutes),
          accent: AppColors.matcha,
        ),
        _StatTile(
          icon: Icons.check_circle_outline_rounded,
          label: 'LESSONS DONE',
          value: '${stats.lessonsDone}',
          accent: AppColors.goldAccent,
        ),
        _StatTile(
          icon: Icons.trending_up_rounded,
          label: 'ACCURACY',
          value: '${stats.averageAccuracy}%',
          accent: AppColors.progressTeal,
        ),
      ],
    );
  }

  static String _formatStudyTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return remain == 0 ? '${hours}h' : '${hours}h ${remain}m';
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
  final _ProfileStats stats;

  const _ActivityHistoryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalWeekXp = stats.xpLast7Days.fold<int>(0, (a, b) => a + b);

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
                child: Text(
                  '$totalWeekXp XP',
                  style: const TextStyle(
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
                values: stats.xpLast7Days,
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
  final List<int> values;
  final Color barColor;
  final Color mutedColor;
  final Color gridColor;
  final Color textColor;

  const _ActivityChartPainter({
    required this.values,
    required this.barColor,
    required this.mutedColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final safeValues = values.length == 7 ? values : [0, 0, 0, 0, 0, 0, 0];
    final maxValue = safeValues.fold<int>(0, (a, b) => a > b ? a : b);
    final today = DateTime.now();
    final days = List.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      return names[day.weekday - 1];
    });
    const bottomLabelHeight = 24.0;
    final chartHeight = size.height - bottomLabelHeight;
    final slotWidth = size.width / safeValues.length;
    final barWidth = slotWidth * 0.54;
    final radius = Radius.circular(barWidth / 2);

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartHeight * (0.18 + i * 0.22);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < safeValues.length; i++) {
      final normalized = maxValue == 0 ? 0.06 : safeValues[i] / maxValue;
      final left = slotWidth * i + (slotWidth - barWidth) / 2;
      final height = chartHeight * normalized.clamp(0.06, 1.0);
      final top = chartHeight - height;
      final rect = Rect.fromLTWH(left, top, barWidth, height);
      final isPeak = safeValues[i] == maxValue && maxValue > 0;
      final paint = Paint()
        ..color = isPeak
            ? barColor
            : Color.lerp(mutedColor, barColor, normalized * 0.35)!
                .withValues(alpha: maxValue == 0 ? 0.28 : 0.58);

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

  @override
  bool shouldRepaint(covariant _ActivityChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.barColor != barColor ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}

class _AccountActions extends StatelessWidget {
  final User? user;
  final VoidCallback onEditProfile;
  final VoidCallback onVerifyEmail;
  final VoidCallback onResetPassword;
  final VoidCallback onChangePassword;
  final VoidCallback onDeleteAccount;
  final VoidCallback onSignOut;

  const _AccountActions({
    required this.user,
    required this.onEditProfile,
    required this.onVerifyEmail,
    required this.onResetPassword,
    required this.onChangePassword,
    required this.onDeleteAccount,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final needsVerification = user?.emailVerified == false;

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
            onTap: onEditProfile,
          ),
          if (needsVerification) ...[
            Divider(height: 1, color: AppColors.divider(context)),
            _ActionRow(
              icon: Icons.mark_email_unread_outlined,
              label: 'Verify email',
              color: AppColors.warningYellow,
              onTap: onVerifyEmail,
            ),
          ],
          Divider(height: 1, color: AppColors.divider(context)),
          _ActionRow(
            icon: Icons.password_outlined,
            label: 'Reset password by email',
            onTap: onResetPassword,
          ),
          Divider(height: 1, color: AppColors.divider(context)),
          _ActionRow(
            icon: Icons.lock_reset_outlined,
            label: 'Change password',
            onTap: onChangePassword,
          ),
          Divider(height: 1, color: AppColors.divider(context)),
          _ActionRow(
            icon: Icons.delete_outline,
            label: 'Delete account',
            color: AppColors.errorRed,
            onTap: onDeleteAccount,
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

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.inputFill(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.divider(context),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
