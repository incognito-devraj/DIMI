import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// "More" hub — gives access to the sections not in the primary bottom nav.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _sections = [
    _MoreItem(
      label: 'Expense',
      icon: Icons.account_balance_wallet_outlined,
      route: '/expense',
      color: AppColors.danger,
    ),
    _MoreItem(
      label: 'Notes',
      icon: Icons.sticky_note_2_outlined,
      route: '/notes',
      color: AppColors.info,
    ),
    _MoreItem(
      label: 'Reminders',
      icon: Icons.notifications_outlined,
      route: '/reminders',
      color: AppColors.accent,
    ),
    _MoreItem(
      label: 'Documents',
      icon: Icons.folder_outlined,
      route: '/documents',
      color: AppColors.success,
    ),
    _MoreItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      route: '/profile',
      color: AppColors.surfaceDark,
    ),
    _MoreItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: '/settings',
      color: AppColors.textSecondary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                20,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: Text(
                'More',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            const SizedBox(height: 20),
            // ── Grid ──────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.cardGap,
                  crossAxisSpacing: AppSpacing.cardGap,
                  childAspectRatio: 1,
                  children: _sections.map((s) => _MoreTile(item: s)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.item});
  final _MoreItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.route),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 24, color: item.color),
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.color,
  });
  final String label;
  final IconData icon;
  final String route;
  final Color color;
}
