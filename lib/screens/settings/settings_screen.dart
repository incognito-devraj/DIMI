import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../providers/profile_providers.dart';
import '../../routing/app_router.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../features/transaction_detection/transaction_detection_service.dart';
import '../../providers/database_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
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
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('Settings', style: Theme.of(context).textTheme.displayMedium),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Account info ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _AccountCard(
                  name: profile?.name ?? 'Student',
                  role: profile?.role ?? '',
                  email: profile?.email ?? '',
                  photoPath: profile?.photoPath,
                  onEditTap: () => context.push(AppRoutes.profile),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (kDebugMode)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                  child: _SettingsGroup(title: 'Developer', items: [
                    _SettingsItem(icon: Icons.bug_report_outlined, label: 'Notification Detector', trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary), onTap: () => context.push(AppRoutes.notificationDetector)),
                    _SettingsItem(icon: Icons.cleaning_services_outlined, label: 'Remove invalid detected transactions', trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary), onTap: () => _cleanupDetectedTransactions(context, ref)),
                  ]),
                ),
              ),
            if (kDebugMode) const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Appearance ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _SettingsGroup(
                  title: 'Appearance',
                  items: [
                    _SettingsItem(
                      icon: Icons.color_lens_outlined,
                      label: 'Theme',
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
                    _SettingsItem(
                      icon: Icons.text_fields_outlined,
                      label: 'Font size',
                      trailing: const Text(
                        'Default',
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
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                child: _ExpenseDetectionSettings(ref: ref),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Notifications ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _SettingsGroup(
                  title: 'Notifications',
                  items: [
                    _SettingsItem(
                      icon: Icons.notifications_outlined,
                      label: 'Reminder notifications',
                      trailing: const Text(
                        'Manage',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: () async {
                        await NotificationService.instance.requestPermissions();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Notification permissions requested',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Data & Backup ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _SettingsGroup(
                  title: 'Data & Backup',
                  items: [
                    _SettingsItem(
                      icon: Icons.storage_outlined,
                      label: 'Local storage',
                      trailing: const Text(
                        'SQLite',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: null,
                    ),
                    _SettingsItem(
                      icon: Icons.cloud_sync_outlined,
                      label: 'Cloud sync',
                      trailing: const Text(
                        'Coming soon',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: () => _showComingSoon(context),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Security ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _SettingsGroup(
                  title: 'Security',
                  items: [
                    _SettingsItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'App lock',
                      trailing: const Text(
                        'Coming soon',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: () => _showComingSoon(context),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── About ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _SettingsGroup(
                  title: 'About',
                  items: [
                    _SettingsItem(
                      icon: Icons.info_outline_rounded,
                      label: 'Version',
                      trailing: const Text(
                        '1.0.0',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onTap: null,
                    ),
                    _SettingsItem(
                      icon: Icons.description_outlined,
                      label: 'Privacy Policy',
                      onTap: () => _showComingSoon(context),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Logout ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _LogoutButton(onTap: () => _confirmLogout(context)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Future<void> _cleanupDetectedTransactions(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(databaseProvider).moneyDao;
    final rows = await dao.suspiciousDetectedTransactions();
    if (!context.mounted) return;
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No obviously invalid detected transactions found.')));
      return;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Remove invalid transactions?'), content: Text('${rows.length} malformed automatic transaction(s) with Unknown merchant and Other category will be removed. Manual transactions are not affected.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove'))]));
    if (confirmed == true) {
      final count = await dao.deleteSuspiciousDetectedTransactions();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count invalid transaction(s) removed.')));
    }
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

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: const Text(
          'Logout?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will clear the onboarding flag and return you to the welcome screen. Your data is NOT deleted.',
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}

class _ExpenseDetectionSettings extends StatefulWidget {
  const _ExpenseDetectionSettings({required this.ref});
  final WidgetRef ref;
  @override State<_ExpenseDetectionSettings> createState() => _ExpenseDetectionSettingsState();
}

class _ExpenseDetectionSettingsState extends State<_ExpenseDetectionSettings> {
  String _mode = 'Detect & Ask';
  bool _enabled = false;
  late final TransactionDetectionService _service;
  @override void initState() { super.initState(); _service = TransactionDetectionService(widget.ref.read(databaseProvider)); _refresh(); _loadMode(); }
  Future<void> _loadMode() async { final mode = await _service.detectionMode(); if (mounted) setState(() => _mode = mode); }
  Future<void> _refresh() async { final value = await _service.isNotificationAccessEnabled(); if (mounted) setState(() => _enabled = value); }
  @override Widget build(BuildContext context) => _SettingsGroup(title: 'Expense Detection', items: [
    _SettingsItem(icon: Icons.account_balance_wallet_outlined, label: 'Automatic detection', trailing: Text(_mode, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)), onTap: () async { final value = await showModalBottomSheet<String>(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: ['Off', 'Detect & Ask', 'Auto-add high confidence'].map((item) => ListTile(title: Text(item), onTap: () => Navigator.pop(ctx, item))).toList()))); if (value != null) { await _service.setDetectionMode(value); if (value == 'Auto-add high confidence') await _service.autoAddPendingHighConfidence(); if (mounted) setState(() => _mode = value); } }),
    _SettingsItem(icon: Icons.notifications_active_outlined, label: 'Notification access', trailing: Text(_enabled ? 'Enabled' : 'Not enabled', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary)), onTap: () async { await _service.openNotificationAccessSettings(); }),
    _SettingsItem(icon: Icons.info_outline, label: 'Why this is needed', trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary), onTap: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Expense detection'), content: const Text('DIMI reads relevant payment notifications locally to suggest expenses. Notification access can be revoked at any time; notification contents are not uploaded.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]))),
  ]);
}

// ── Account card ──────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.role,
    required this.email,
    this.photoPath,
    required this.onEditTap,
  });
  final String name;
  final String role;
  final String email;
  final String? photoPath;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(color: Color(0x0A1B1B1B), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.accent,
            backgroundImage: photoPath == null ? null : FileImage(File(photoPath!)),
            child: Text(
              photoPath == null && name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.surfaceDark,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                    color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEditTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
              color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings group ────────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.items});
  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  items[i],
                  if (!isLast)
                    const Divider(height: 1, indent: 48, endIndent: 0),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            if (trailing != null) trailing!, // ignore: use_null_aware_elements
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Logout button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Logout'),
      ),
    );
  }
}
