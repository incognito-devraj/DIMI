import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/supabase_config.dart';
import '../../routing/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../providers/database_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dimi_hero.dart';
import 'notification_type_sheet.dart';

// ─── Settings screen ──────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _currentVersion = info.version);
    });
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming in a future update'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: DimiHero(
                title: 'Settings',
                subtitle: '        Small settings. Big progress.',
                height: 200,
                leading: DimiHeroCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 5)),

            // ── Check for Updates card ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.updates),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A1C1C1E),
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.system_update_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Check for Updates',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    _currentVersion.isEmpty
                                        ? 'Loading…'
                                        : 'Current version: $_currentVersion',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
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
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Notifications ─────────────────────────────────────────────
            _SectionHeader(title: 'Notifications'),
            _SectionCard(items: [const _NotificationModeTile()]),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Data & Sync ───────────────────────────────────────────────
            _SectionHeader(title: 'Data & Sync'),
            _SectionCard(
              items: [
                _SettingsTile(
                  icon: Icons.storage_outlined,
                  iconColor: AppColors.success,
                  label: 'Manage Data',
                  subtitle: 'View, edit or clear your data',
                  onTap: _showComingSoon,
                ),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  iconColor: AppColors.info,
                  label: 'Export Data',
                  subtitle: 'Download your data anytime',
                  onTap: _showComingSoon,
                ),
              ],
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Support & About ───────────────────────────────────────────
            _SectionHeader(title: 'Support & About'),
            _SectionCard(
              items: [
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.textSecondary,
                  label: 'Help & Support',
                  subtitle: 'Get help or contact us',
                  onTap: () => context.push(AppRoutes.helpSupport),
                ),
                _SettingsTile(
                  icon: Icons.feedback_outlined,
                  iconColor: AppColors.textSecondary,
                  label: 'Feedback',
                  subtitle: 'Tell us how we can improve',
                  onTap: () => context.push(AppRoutes.feedback),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.textSecondary,
                  label: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
                _SettingsTile(
                  icon: Icons.verified_user_outlined,
                  iconColor: AppColors.textSecondary,
                  label: 'Terms of Service',
                  subtitle: 'Our terms and guidelines',
                  onTap: () => context.push(AppRoutes.terms),
                ),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.info,
                  label: 'About DIMI',
                  subtitle: 'Version info and creator credit',
                  onTap: () => context.push(AppRoutes.about),
                ),
              ],
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Account ───────────────────────────────────────────────────
            _SectionHeader(title: 'Account'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A1C1C1E),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const _AccountSection(),
                ),
              ),
            ),

            // ── DIMI wordmark footer ──────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
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
                      'Digital Interface for Monitoring and Improvement',
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
          ],
        ),
      ),
    );
  }
}

// ─── Notification mode tile ───────────────────────────────────────────────────

class _NotificationModeTile extends StatefulWidget {
  const _NotificationModeTile();

  @override
  State<_NotificationModeTile> createState() => _NotificationModeTileState();
}

class _NotificationModeTileState extends State<_NotificationModeTile> {
  late Future<bool> _mode;

  @override
  void initState() {
    super.initState();
    _mode = NotificationService.instance.isFullScreenModeEnabled();
  }

  // Called by the sheet AFTER it has already persisted the mode.
  // Only update local display state — do NOT call setNotificationMode again.
  void _onModeSaved(bool fullScreen) {
    if (!mounted) return;
    setState(() => _mode = Future.value(fullScreen));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _mode,
      builder: (context, snapshot) {
        final fullScreen = snapshot.data ?? false;
        return _SettingsTile(
          icon: Icons.notifications_active_outlined,
          iconColor: AppColors.accent,
          label: 'Notification Type',
          subtitle: fullScreen
              ? 'Full Screen Notification'
              : 'Normal Notification',
          onTap: () async {
            final isFS = await NotificationService.instance
                .isFullScreenModeEnabled();
            if (!context.mounted) return;
            showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => NotificationTypeSheet(
                initialFullScreen: isFS,
                onSaved: _onModeSaved,
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Account section ──────────────────────────────────────────────────────────

class _AccountSection extends StatefulWidget {
  const _AccountSection();

  @override
  State<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<_AccountSection> {
  bool _loggingOut = false;

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: const Text(
          'Log Out?',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will sign you out. Your local data is NOT deleted.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (!mounted) return;

    setState(() => _loggingOut = true);

    // Clear offline mode flag and its persisted preference regardless of
    // auth method, so the next launch shows the login screen.
    await SupabaseBootstrap.clearOfflineMode();

    // Sign out from Supabase if an active session exists.
    if (SupabaseBootstrap.client?.auth.currentSession != null) {
      try {
        await AuthService.instance.signOut(
          ProviderScope.containerOf(
            context,
            listen: false,
          ).read(databaseProvider),
        );
      } catch (_) {
        // Ignore errors — we still navigate to login.
      }
    }
    if (!mounted) return;
    setState(() => _loggingOut = false);
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.logout_rounded,
      iconColor: AppColors.danger,
      label: _loggingOut ? 'Signing out…' : 'Log Out',
      subtitle: 'Sign out from your account',
      labelColor: AppColors.danger,
      onTap: _loggingOut ? null : _confirmLogout,
      showChevron: false,
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          0,
          AppSpacing.screenHorizontal,
          8,
        ),
        child: DimiSectionHeading(
          icon: _iconForTitle(title),
          title: title,
          subtitle: _subtitleForTitle(title),
        ),
      ),
    );
  }

  IconData _iconForTitle(String title) {
    const icons = <String, IconData>{
      'Notifications': Icons.notifications_outlined,
      'Data & Sync': Icons.storage_rounded,
      'Support & About': Icons.help_outline_rounded,
      'Account': Icons.person_outline_rounded,
    };
    return icons[title] ?? Icons.settings_outlined;
  }

  String? _subtitleForTitle(String title) {
    const subtitles = <String, String>{
      'Notifications': 'Manage how DIMI notifies you',
      'Data & Sync': 'Your data, your control.',
      'Support & About': 'We\'re here for you.',
      'Account': 'Manage your account.',
    };
    return subtitles[title];
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.items});
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A1C1C1E),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  items[i],
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 54,
                      endIndent: 0,
                      color: AppColors.divider,
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Settings tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.labelColor,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: labelColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
