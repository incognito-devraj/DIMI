import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Shared shell — 4-tab bottom navigation.
///
/// Tabs:
///   0  Home       /home
///   1  Planner    /planner
///   2  Expense    /money
///   3  Reminders  /reminders
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  final Widget child;
  final int currentIndex;

  static const List<_NavItem> _items = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: '/home',
    ),
    _NavItem(
      label: 'Planner',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      route: '/planner',
    ),
    _NavItem(
      label: 'Expense',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      route: '/money',
    ),
    _NavItem(
      label: 'Reminders',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      route: '/reminders',
    ),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    context.go(_items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      // The tab routes use context.go(), so they do not create a browser/
      // Navigator history entry. Intercept back on non-home tabs and return
      // to Home; allow the platform to exit when Home is already active.
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && currentIndex != 0) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: child,
        bottomNavigationBar: _DimiBottomNav(
          currentIndex: currentIndex,
          onTap: (i) => _onTap(context, i),
        ),
      ),
    );
  }
}

// ── Custom bottom nav ─────────────────────────────────────────────────────────

class _DimiBottomNav extends StatelessWidget {
  const _DimiBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(
              AppScaffold._items.length,
              (i) => _NavTile(
                item: AppScaffold._items[i],
                isActive: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                size: 22,
                color: isActive ? AppColors.surface : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
}
