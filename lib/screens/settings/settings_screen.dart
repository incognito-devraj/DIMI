import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/database_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  20,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Settings',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                    // Handwritten-style subtitle
                    Text(
                      'Small settings\nBig progress.',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── App Preferences ───────────────────────────────────────────
            _SectionHeader(title: 'App Preferences'),
            _SectionCard(
              items: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.accent,
                  label: 'Notifications',
                  subtitle: 'Manage your reminders and alerts',
                  onTap: () async {
                    await NotificationService.instance.requestPermissions();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification permissions requested'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                _SettingsTile(
                  icon: Icons.color_lens_outlined,
                  iconColor: const Color(0xFF9B59B6),
                  label: 'Appearance',
                  subtitle: 'Light / Dark / System',
                  trailing: const Text(
                    'Light',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.language_outlined,
                  iconColor: AppColors.info,
                  label: 'Language',
                  subtitle: 'Choose your preferred language',
                  trailing: const Text(
                    'English',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Data & Sync ───────────────────────────────────────────────
            _SectionHeader(title: 'Data & Sync'),
            _SectionCard(
              items: [
                _SettingsTile(
                  icon: Icons.cloud_outlined,
                  iconColor: AppColors.info,
                  label: 'Sync & Backup',
                  subtitle: 'Keep your data safe across devices',
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.storage_outlined,
                  iconColor: const Color(0xFF27AE60),
                  label: 'Manage Data',
                  subtitle: 'View, edit or clear your data',
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  iconColor: const Color(0xFF1ABC9C),
                  label: 'Export Data',
                  subtitle: 'Download your data anytime',
                  onTap: () => _showComingSoon(context),
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
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.textSecondary,
                  label: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  onTap: () => _showComingSoon(context),
                ),
                _SettingsTile(
                  icon: Icons.verified_user_outlined,
                  iconColor: AppColors.textSecondary,
                  label: 'Terms of Service',
                  subtitle: 'Our terms and guidelines',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Account ───────────────────────────────────────────────────
            _SectionHeader(title: 'Account'),
            _SectionCard(
              items: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.danger,
                  label: 'Log Out',
                  subtitle: 'Sign out from your account',
                  labelColor: AppColors.danger,
                  onTap: () => _confirmLogout(context),
                  showChevron: false,
                ),
              ],
            ),

            // ── Debug-only developer section ──────────────────────────────
            if (kDebugMode) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              _SectionHeader(title: 'Developer'),
              _SectionCard(
                items: [
                  _SettingsTile(
                    icon: Icons.bug_report_outlined,
                    iconColor: AppColors.textSecondary,
                    label: 'Notification Detector',
                    onTap: () => context.push(AppRoutes.notificationDetector),
                  ),
                  _SettingsTile(
                    icon: Icons.cleaning_services_outlined,
                    iconColor: AppColors.textSecondary,
                    label: 'Remove invalid detected transactions',
                    onTap: () => _cleanupDetectedTransactions(context, ref),
                  ),
                ],
              ),
            ],

            // ── DIMI wordmark footer ──────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Text(
                      'DIMI',
                      style: TextStyle(
                        fontFamily: 'Poppins',
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
                        fontFamily: 'Poppins',
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming in a future update'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _cleanupDetectedTransactions(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final dao = ref.read(databaseProvider).moneyDao;
    final rows = await dao.suspiciousDetectedTransactions();
    if (!context.mounted) return;
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No obviously invalid detected transactions found.'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove invalid transactions?'),
        content: Text(
          '${rows.length} malformed automatic transaction(s) with Unknown merchant and Other category will be removed. Manual transactions are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final count = await dao.deleteSuspiciousDetectedTransactions();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count invalid transaction(s) removed.')),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: const Text(
          'Log Out?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will sign you out. Your local data is NOT deleted.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
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
    if (ok == true && context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

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
        child: Row(
          children: [
            _sectionIcon(title),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionIcon(String title) {
    final icons = <String, IconData>{
      'App Preferences': Icons.tune_rounded,
      'Data & Sync': Icons.storage_rounded,
      'Support & About': Icons.help_outline_rounded,
      'Account': Icons.person_outline_rounded,
      'Developer': Icons.code_rounded,
    };
    return Icon(
      icons[title] ?? Icons.settings_outlined,
      size: 18,
      color: AppColors.textPrimary,
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.items});
  final List<_SettingsTile> items;

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

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.trailing,
    this.labelColor,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final Color? labelColor;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
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
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: labelColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
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
