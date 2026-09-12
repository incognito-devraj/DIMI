import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/planner/planner_screen.dart';
import '../screens/money/money_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/notification_detector_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/app_scaffold.dart';
import '../core/motion/dimi_motion.dart';
import '../core/motion/dimi_page_transition.dart';
import '../config/supabase_config.dart';
import '../screens/auth/login_screen.dart';

/// Route path constants.
abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const planner = '/planner';
  static const expense = '/expense';
  static const money = expense;
  static const legacyMoney = '/money';
  static const reminders = '/reminders';
  static const settings = '/settings';
  static const notificationDetector = '/settings/notification-detector';
  static const profile = '/profile';
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
  initialLocation: AppRoutes.splash,
  refreshListenable: SupabaseAuthRefreshNotifier(SupabaseBootstrap.authChanges),
  redirect: (context, state) async {
    if (state.uri.path == AppRoutes.splash) return null;

    // If the user has a valid session, always let them through.
    final hasSession = SupabaseBootstrap.client?.auth.currentSession != null;

    if (state.uri.path == AppRoutes.login) {
      // Already signed in → skip login.
      if (hasSession) return AppRoutes.home;
      return null;
    }

    // Guard all other routes: only redirect to login when Supabase is
    // configured, the user has no session, AND hasn't chosen offline mode.
    if (SupabaseBootstrap.client != null &&
        !hasSession &&
        !SupabaseBootstrap.offlineMode) {
      return AppRoutes.login;
    }

    return null;
  },
  routes: [
    // Startup animation stays outside the main shell so the existing Home
    // screen and bottom navigation are reused unchanged after handoff.
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => _fade(state, const SplashScreen()),
    ),

    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) => _fade(state, const LoginScreen()),
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

    GoRoute(
      path: AppRoutes.profile,
      pageBuilder: (context, state) => _fade(state, const ProfileScreen()),
    ),

    // ── Settings — pushed on top (no bottom nav) ──────────────────────────
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (ctx, state) => _slide(state, const SettingsScreen()),
    ),

    GoRoute(
      path: AppRoutes.notificationDetector,
      pageBuilder: (ctx, state) =>
          _slide(state, const NotificationDetectorScreen()),
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
