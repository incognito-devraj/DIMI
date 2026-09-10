import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home/home_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/planner/planner_screen.dart';
import '../screens/money/money_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../widgets/app_scaffold.dart';
import '../core/motion/dimi_motion.dart';
import '../core/motion/dimi_page_transition.dart';

/// Route path constants.
abstract class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const planner = '/planner';
  static const expense = '/expense';
  static const money = expense;
  static const legacyMoney = '/money';
  static const reminders = '/reminders';
  static const settings = '/settings';
}

int _tabIndex(String location) {
  if (location.startsWith('/home')) return 0;
  if (location.startsWith('/planner')) return 1;
  if (location.startsWith('/expense') || location.startsWith('/money')) {
    return 2;
  }
  if (location.startsWith('/reminders')) return 3;
  return 0;
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  redirect: (context, state) async {
    if (state.uri.path == AppRoutes.onboarding) return null;
    final prefs = await SharedPreferences.getInstance();
    final hasOnboarded = prefs.getBool(kHasOnboardedKey) ?? false;
    if (!hasOnboarded) return AppRoutes.onboarding;
    return null;
  },
  routes: [
    // ── Onboarding (no bottom nav) ────────────────────────────────────────
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) => _fade(state, const OnboardingScreen()),
    ),

    // ── Main shell (bottom nav tabs 0–3) ──────────────────────────────────
    ShellRoute(
      builder: (context, state, child) =>
          AppScaffold(currentIndex: _tabIndex(state.uri.path), child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (ctx, state) => _fade(state, const HomeScreen()),
        ),
        GoRoute(
          path: AppRoutes.planner,
          pageBuilder: (ctx, state) => _fade(state, const PlannerScreen()),
        ),
        GoRoute(
          path: AppRoutes.money,
          pageBuilder: (ctx, state) => _fade(state, const MoneyScreen()),
        ),
        GoRoute(
          path: AppRoutes.legacyMoney,
          pageBuilder: (ctx, state) => _fade(state, const MoneyScreen()),
        ),
        GoRoute(
          path: AppRoutes.reminders,
          pageBuilder: (ctx, state) => _fade(state, const RemindersScreen()),
        ),
      ],
    ),

    // ── Settings — pushed on top (no bottom nav) ──────────────────────────
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (ctx, state) => _slide(state, const SettingsScreen()),
    ),
  ],
);

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: DimiMotion.smooth,
    transitionsBuilder: dimiPageTransition,
  );
}

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: DimiMotion.smooth,
    transitionsBuilder: (_, animation, _, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
