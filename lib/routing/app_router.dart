import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/planner/planner_screen.dart';
import '../screens/todos/todos_screen.dart';
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
import '../features/youtube_playlist/data/mock_youtube_playlist.dart';
import '../features/youtube_playlist/models/youtube_playlist.dart';
import '../features/youtube_playlist/models/youtube_video.dart';
import '../features/youtube_playlist/screens/playlist_details_screen.dart';
import '../features/youtube_playlist/screens/video_details_screen.dart';

/// Route path constants.
abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const planner = '/planner';
  static const todos = '/todos';
  static const expense = '/expense';
  static const money = expense;
  static const legacyMoney = '/money';
  static const reminders = '/reminders';
  static const settings = '/settings';
  static const notificationDetector = '/settings/notification-detector';
  static const profile = '/profile';
  static const playlistDetails = '/youtube-playlist';
  static const videoDetails = '/youtube-playlist/video';
}

int _tabIndex(String location) {
  if (location.startsWith('/home')) return 0;
  if (location.startsWith('/todos')) return 1;
  if (location.startsWith('/planner')) return 2;
  if (location.startsWith('/expense') || location.startsWith('/money')) {
    return 3;
  }
  if (location.startsWith('/reminders')) return 4;
  return 0;
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: SupabaseAuthRefreshNotifier(SupabaseBootstrap.authChanges),
  onException: (context, state, router) {
    // supabase_flutter consumes this URI through its deep-link observer. If
    // the platform also forwards it to Flutter's route information parser,
    // keep it inside startup instead of exposing it as an app route.
    if (_isSupabaseCallback(state.uri)) {
      router.go(AppRoutes.splash);
    }
  },
  redirect: (context, state) async {
    final path = state.uri.path;

    if (_isSupabaseCallback(state.uri)) return AppRoutes.splash;

    // Splash never redirects itself.
    if (path == AppRoutes.splash) return null;

    // ── Offline mode: user tapped "Continue offline" ─────────────────────
    // Allow free navigation — no session required.
    if (SupabaseBootstrap.offlineMode) {
      // Keep them off the login screen once they've chosen offline.
      if (path == AppRoutes.login) return AppRoutes.home;
      return null;
    }

    // ── No Supabase configured (CI / offline-only build) ─────────────────
    if (!SupabaseConfig.isConfigured) {
      if (path == AppRoutes.login) return null;
      // Block until user picks an auth path (Google or offline).
      return AppRoutes.login;
    }

    // ── Supabase IS configured ───────────────────────────────────────────
    final hasSession = SupabaseBootstrap.client?.auth.currentSession != null;

    if (path == AppRoutes.login) {
      if (hasSession) return AppRoutes.home;
      return null;
    }

    // Block protected routes until session is started.
    return hasSession ? null : AppRoutes.login;
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
          path: AppRoutes.todos,
          pageBuilder: (ctx, state) => _fade(state, const TodosScreen()),
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

    GoRoute(
      path: AppRoutes.playlistDetails,
      pageBuilder: (context, state) => _slide(
        state,
        PlaylistDetailsScreen(
          playlist: state.extra is YouTubePlaylist
              ? state.extra! as YouTubePlaylist
              : mockYouTubePlaylist,
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.videoDetails,
      pageBuilder: (context, state) => _slide(
        state,
        VideoDetailsScreen(
          video: state.extra is YouTubeVideo
              ? state.extra! as YouTubeVideo
              : mockYouTubePlaylist.currentVideo,
        ),
      ),
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

bool _isSupabaseCallback(Uri uri) =>
    uri.scheme == 'com.dimi.dimi' || uri.path == '/login-callback';

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: DimiMotion.normal,
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
