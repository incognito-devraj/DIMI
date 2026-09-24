import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers/profile_providers.dart';
import '../../providers/task_providers.dart';
import '../../routing/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dimi_hero.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) => profile == null
              ? const _NoProfileState()
              : _ProfileBody(profile: profile),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

// ── Logout ────────────────────────────────────────────────────────────────────

// ── No profile state ──────────────────────────────────────────────────────────

class _NoProfileState extends StatelessWidget {
  const _NoProfileState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.person_outline_rounded,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No profile yet.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main profile body ─────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final ProfileTableData profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasksAsync = ref.watch(allTasksProvider);
    final allTasks = allTasksAsync.valueOrNull ?? [];

    final goalsInProgress = allTasks.where((task) => !task.isCompleted).length;

    // Calculate completed dates.
    final completedByDate = <DateTime>{};

    for (final task in allTasks) {
      if (task.isCompleted) {
        completedByDate.add(
          DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day),
        );
      }
    }

    // Calculate current streak.
    int dayStreak = 0;
    var checkDate = DateTime.now();

    while (completedByDate.contains(
      DateTime(checkDate.year, checkDate.month, checkDate.day),
    )) {
      dayStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Calculate active days.
    final activeDays = <DateTime>{};

    for (final task in allTasks) {
      activeDays.add(
        DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ────────────────────────────────────────────────────────────────────
        // HERO + PROFILE CARD
        //
        // These MUST live inside the same Stack.
        // This guarantees the profile card paints above the hero.
        // ────────────────────────────────────────────────────────────────────

        SliverToBoxAdapter(
          child: SizedBox(
            height: 420,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Hero background.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: DimiHero(
                    title: 'Profile',
                    subtitle: 'Good to see you back!',
                    height: 180,
                    trailing: DimiHeroCircleButton(
                      icon: Icons.settings_outlined,
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ),
                ),

                // Profile card.
                //
                // Positioned ABOVE the hero rather than being a separate
                // sliver translated upward.
                Positioned(
                  top: 200,
                  left: AppSpacing.screenHorizontal,
                  right: AppSpacing.screenHorizontal,
                  child: _HeroCard(
                    profile: profile,
                    dayStreak: dayStreak,
                    activeDays: activeDays.length,
                    goalsInProgress: goalsInProgress,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 0)),

        // ── Personal Information ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: _EditProfileButton(profile: profile),
          ),
        ),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 12, left: 20, right: 20),
            child: Text(
              'Keep going. You’re doing great. ♥',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 4)),

        // ── Go Premium ──────────────────────────────────────────────────────
        // ── Sync Status ─────────────────────────────────────────────────────
        // ── Remaining actions ───────────────────────────────────────────────

        // DIMI footer — pinned to the bottom of the visible screen
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'DIMI',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Digital Interface For Monitoring and Improvement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Created by incognito-devraj',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.profile});

  final ProfileTableData profile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _EditProfileSheet(profile: profile),
        ),
        icon: const Icon(Icons.edit_outlined, size: 19),
        label: const Text('Edit profile'),
      ),
    );
  }
}

class _HeroCard extends ConsumerStatefulWidget {
  const _HeroCard({
    required this.profile,
    required this.dayStreak,
    required this.activeDays,
    required this.goalsInProgress,
  });

  final ProfileTableData profile;
  final int dayStreak;
  final int activeDays;
  final int goalsInProgress;

  @override
  ConsumerState<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends ConsumerState<_HeroCard> {
  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121C1C1E),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 27, 12, 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar intentionally overlaps the profile card edge.
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: _ProfileAvatar(profile: p),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          p.role.isNotEmpty ? p.role : 'CS Engineering Student',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),

            _ProgressRow(
              dayStreak: widget.dayStreak,
              activeDays: widget.activeDays,
              goalsInProgress: widget.goalsInProgress,
              achievements: p.points,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final ProfileTableData profile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.photoPath;
    final hasAvatar = avatarUrl != null && avatarUrl.startsWith('http');
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x181C1C1E),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(avatarUrl!, fit: BoxFit.cover)
            : Container(
                color: AppColors.accent,
                alignment: Alignment.center,
                child: Text(
                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Personal information ──────────────────────────────────────────────────────

class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard({required this.profile});

  final ProfileTableData profile;

  void _openEdit(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _EditProfileSheet(profile: profile);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final joinedText = DateFormat('MMMM yyyy').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081C1C1E),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 0),
            child: Row(
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () => _openEdit(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 2),

          _InfoLine(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: profile.email.isNotEmpty ? profile.email : 'Not set',
          ),

          const Divider(
            height: 1,
            indent: 42,
            endIndent: 12,
            color: AppColors.divider,
          ),

          _InfoLine(
            icon: Icons.calendar_today_outlined,
            label: 'Joined',
            value: joinedText,
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress ──────────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.dayStreak,
    required this.activeDays,
    required this.goalsInProgress,
    required this.achievements,
  });

  final int dayStreak;
  final int activeDays;
  final int goalsInProgress;
  final int achievements;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: _ProgressStat(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFFF6B35),
                value: '$dayStreak',
                label: 'Day Streak',
              ),
            ),

            Container(width: 1, height: 31, color: AppColors.divider),

            Expanded(
              child: _ProgressStat(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFF9B59B6),
                value: '$activeDays',
                label: 'Days Active',
              ),
            ),

            Container(width: 1, height: 31, color: AppColors.divider),

            Expanded(
              child: _ProgressStat(
                icon: Icons.track_changes_rounded,
                iconColor: AppColors.success,
                value: '$goalsInProgress',
                label: 'Goals in\nProgress',
              ),
            ),

            Container(width: 1, height: 31, color: AppColors.divider),

            Expanded(
              child: _ProgressStat(
                icon: Icons.star_rounded,
                iconColor: AppColors.accent,
                value: '$achievements',
                label: 'Achievements',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 19, color: iconColor),

        const SizedBox(height: 2),

        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 8.5,
            color: AppColors.textSecondary,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

// ── Go Premium ────────────────────────────────────────────────────────────────

class _GoPremiumCard extends StatelessWidget {
  const _GoPremiumCard();

  @override
  Widget build(BuildContext context) {
    return _CompactMenuCard(
      icon: const Text('👑', style: TextStyle(fontSize: 17)),
      iconBackground: const Color(0xFFFFF0CC),
      title: 'Go Premium',
      subtitle: 'Unlock advanced insights',
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ── Sync ──────────────────────────────────────────────────────────────────────

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context) {
    return _CompactMenuCard(
      icon: const Icon(
        Icons.cloud_outlined,
        size: 18,
        color: Color(0xFF4A90D9),
      ),
      iconBackground: const Color(0xFFE8F4FD),
      title: 'Sync Status',
      subtitle: 'Local-only mode — no sync',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 3),

          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ── Action card ───────────────────────────────────────────────────────────────

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DimiSurface(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withAlpha(24),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compact menu card ─────────────────────────────────────────────────────────

class _CompactMenuCard extends StatelessWidget {
  const _CompactMenuCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final Widget icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return DimiSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: icon,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            trailing,
          ],
        ),
      ),
    );
  }
}

// ── Logout button ─────────────────────────────────────────────────────────────

class _CompactLogoutButton extends StatelessWidget {
  const _CompactLogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DimiSurface(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 22,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log Out',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.danger,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Sign out from your account',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
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
}

// ── Edit profile sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile});

  final ProfileTableData profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _collegeCtrl;
  late final TextEditingController _semesterCtrl;
  String _educationType = 'College';

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final p = widget.profile;

    _nameCtrl = TextEditingController(text: p.name);

    _roleCtrl = TextEditingController(text: p.role);

    _emailCtrl = TextEditingController(text: p.email);

    _phoneCtrl = TextEditingController(text: p.phone);

    _collegeCtrl = TextEditingController(text: p.college);
    _semesterCtrl = TextEditingController(text: p.semester);
    _educationType = p.semester.trim().toLowerCase().startsWith('class')
        ? 'School'
        : 'College';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _collegeCtrl.dispose();
    _semesterCtrl.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    await ref
        .read(profileDaoProvider)
        .upsertProfile(
          ProfileTableCompanion(
            id: const Value(1),
            name: Value(_nameCtrl.text.trim()),
            role: Value(_roleCtrl.text.trim()),
            email: Value(_emailCtrl.text.trim()),
            phone: Value(_phoneCtrl.text.trim()),
            college: Value(_collegeCtrl.text.trim()),
            semester: Value(_semesterCtrl.text.trim()),
            quote: const Value(null),
            photoPath: Value(
              widget.profile.photoPath?.startsWith('http') == true
                  ? widget.profile.photoPath
                  : null,
            ),
            points: Value(widget.profile.points),
          ),
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Row(
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Field(
                      'Name',
                      _nameCtrl,
                      hint: 'Your full name',
                      caps: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),

                    const SizedBox(height: 12),

                    _Field(
                      'Google account',
                      _emailCtrl,
                      hint: 'your@email.com',
                      keyboard: TextInputType.emailAddress,
                      readOnly: true,
                      suffixIcon: const Icon(Icons.lock_outline, size: 17),
                    ),

                    const SizedBox(height: 12),

                    _Field(
                      'Phone',
                      _phoneCtrl,
                      hint: '+91 XXXXX XXXXX',
                      keyboard: TextInputType.phone,
                    ),

                    const SizedBox(height: 12),

                    _Field(
                      'Occupation / role',
                      _roleCtrl,
                      hint: 'e.g. Student, Engineer, Nurse',
                      caps: TextCapitalization.words,
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _educationType,
                      decoration: InputDecoration(
                        labelText: 'Education',
                        prefixIcon: const Icon(Icons.school_outlined, size: 20),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.divider,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.accent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'College',
                          child: Text('College'),
                        ),
                        DropdownMenuItem(
                          value: 'School',
                          child: Text('School'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _educationType = value);
                      },
                    ),

                    const SizedBox(height: 12),

                    _Field(
                      _educationType == 'School'
                          ? 'School name'
                          : 'College name',
                      _collegeCtrl,
                      hint: _educationType == 'School'
                          ? 'Your school name'
                          : 'Your college name',
                      caps: TextCapitalization.words,
                    ),

                    const SizedBox(height: 12),

                    _Field(
                      _educationType == 'School' ? 'Class' : 'Semester',
                      _semesterCtrl,
                      hint: _educationType == 'School'
                          ? 'e.g. Class 12'
                          : 'e.g. Semester 5',
                      caps: TextCapitalization.words,
                    ),

                    const SizedBox(height: 12),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable form field ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field(
    this.label,
    this.controller, {
    this.hint = '',
    this.keyboard = TextInputType.text,
    this.caps = TextCapitalization.none,
    this.maxLines = 1,
    this.readOnly = false,
    this.suffixIcon,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboard;
  final TextCapitalization caps;
  final int maxLines;
  final bool readOnly;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 6),

        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          textCapitalization: caps,
          maxLines: maxLines,
          readOnly: readOnly,
          validator: validator,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffixIcon),
        ),
      ],
    );
  }
}
