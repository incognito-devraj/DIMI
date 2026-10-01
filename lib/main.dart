import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/database.dart';
import 'providers/database_provider.dart';
import 'providers/task_providers.dart';
import 'providers/reminder_providers.dart';
import 'routing/app_router.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'config/supabase_config.dart';
import 'services/sync_service.dart';
import 'features/youtube_playlist/models/youtube_playlist.dart';
import 'features/youtube_playlist/models/youtube_video.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create and expose the local database before the first frame. All other
  // startup work continues in the background so Android never shows a blank
  // window while Supabase, notifications, sync, and rescheduling initialize.
  final db = AppDatabase();
  NotificationService.instance.attachDatabase(db);

  // Establish a real local account before the first frame. Account-scoped
  // writes must never be allowed to observe the sentinel account id 0.
  await db.localAccountDao.ensureOfflineAccount();

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const DimiApp(),
    ),
  );

  unawaited(_finishStartup(db));

  // Let the first frame/splash finish before opening Android settings. The
  // permission flow must never interrupt app launch.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        return NotificationService.instance.requestPermissions();
      }),
    );
  });
}

Future<void> _finishStartup(AppDatabase db) async {
  await SupabaseBootstrap.initialize();

  // Initialise notifications before anything else.
  await NotificationService.instance.init();

  final restoredUser = SupabaseBootstrap.client?.auth.currentUser;
  if (restoredUser != null) {
    await AuthService.instance.synchronizeAuthState(db, restoredUser);
    try {
      await SyncService(db).syncNow();
    } catch (error, stackTrace) {
      // A remote/RLS outage must not prevent the local-first UI from opening.
      // SyncService has already logged the detailed remote error; preserve
      // the startup exception and stack trace for device diagnostics.
      debugPrint('[DIMI sync] startup sync failed; continuing locally: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  } else {
    await db.localAccountDao.ensureOfflineAccount();
  }
  await db.reminderDao.repairNotificationIds();
  final expiredReminderIds = await db.reminderDao.expirePastStandardReminders();
  for (final id in expiredReminderIds) {
    await NotificationService.instance.cancelReminder(id);
  }
  // Reschedule all enabled future reminders (handles post-reboot case too).
  final reminders = await db.reminderDao.getAllEnabled();
  await NotificationService.instance.rescheduleAll(reminders);
}

class DimiApp extends ConsumerStatefulWidget {
  const DimiApp({super.key});
  @override
  ConsumerState<DimiApp> createState() => _DimiAppState();
}

class _DimiAppState extends ConsumerState<DimiApp> with WidgetsBindingObserver {
  Timer? _syncTimer;
  StreamSubscription? _authSubscription;
  late final SyncService _syncService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncService = SyncService(ref.read(databaseProvider));
    NotificationService.instance.onLocalActionCommitted =
        _refreshLocalNotificationState;
    NotificationService.instance.onOpenPlaylistUnwatched =
        _openPlaylistUnwatched;
    _startForegroundSync();
    _authSubscription = SupabaseBootstrap.authChanges.listen((authState) {
      final db = ref.read(databaseProvider);
      SupabaseBootstrap.offlineMode = false;
      // Supabase can emit a transient null session while restoring persisted
      // auth during process/background resume. Do not switch the UI to the
      // offline account for that transient event; an explicit sign-out still
      // clears the local active context below.
      if (authState.session == null &&
          authState.event != AuthChangeEvent.signedOut) {
        return;
      }
      unawaited(
        AuthService.instance
            .synchronizeAuthState(db, authState.session?.user)
            .then((_) => _syncService.syncNow()),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.onLocalActionCommitted = null;
    NotificationService.instance.onOpenPlaylistUnwatched = null;
    _syncTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Notification actions may have committed through the background
      // isolate's SQLite connection while the app was paused. Re-read the
      // local Drift rows before starting any remote sync so Planner reflects
      // the local completion immediately.
      unawaited(_restoreAccountThenSync());
      _startForegroundSync();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _syncTimer?.cancel();
      _syncTimer = null;
    }
  }

  Future<void> _restoreAccountThenSync() async {
    _refreshLocalNotificationState();
    await _expirePastReminders();
    final user = AuthService.instance.currentUser;
    if (user != null) {
      await AuthService.instance.synchronizeAuthState(
        ref.read(databaseProvider),
        user,
      );
    }
    try {
      await _syncService.syncNow();
    } catch (error, stackTrace) {
      // Resume must remain local-first when the network/session is transient.
      debugPrint('[DIMI sync] resume sync failed; keeping local data: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _refreshLocalNotificationState() {
    if (!mounted) return;
    ref.invalidate(tasksForDateProvider);
    ref.invalidate(tasksForWeekProvider);
    ref.invalidate(plannerTasksForMonthProvider);
    ref.invalidate(plannerHeatmapProvider);
    ref.invalidate(allRemindersProvider);
    ref.invalidate(todaysRemindersProvider);
    ref.invalidate(upcomingRemindersProvider);
    ref.invalidate(allTodosProvider);
    ref.invalidate(homeTodosProvider);
    ref.invalidate(allTasksProvider);
  }

  Future<void> _openPlaylistUnwatched(int playlistId) async {
    final db = ref.read(databaseProvider);
    final row = await db.youtubePlaylistDao.getById(playlistId);
    if (!mounted || row == null) return;
    final videos = await db.youtubePlaylistDao.getVideos(row.id);
    if (!mounted) return;
    appRouter.go(
      '${AppRoutes.playlistDetails}?filter=unwatched',
      extra: YouTubePlaylist(
        localId: row.id,
        playlistId: row.youtubePlaylistId,
        title: row.title,
        channelTitle: row.channelTitle,
        description: row.description,
        thumbnailUrl: row.thumbnailUrl,
        totalVideos: row.totalVideos,
        totalDurationSeconds: row.totalDurationSeconds,
        videos: videos
            .map(
              (video) => YouTubeVideo(
                localId: video.id,
                videoId: video.youtubeVideoId,
                title: video.title,
                thumbnailUrl: video.thumbnailUrl,
                position: video.position,
                durationISO: video.durationIso,
                durationSeconds: video.durationSeconds,
                isCompleted: video.completed,
                watchedAt: video.watchedAt,
              ),
            )
            .toList(),
      ),
    );
  }

  void _startForegroundSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_expirePastReminders());
      unawaited(_syncService.syncNow());
    });
  }

  Future<void> _expirePastReminders() async {
    final ids = await ref
        .read(databaseProvider)
        .reminderDao
        .expirePastStandardReminders();
    for (final id in ids) {
      await NotificationService.instance.cancelReminder(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DIMI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
