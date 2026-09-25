import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'providers/database_provider.dart';
import 'routing/app_router.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'config/supabase_config.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseBootstrap.initialize();

  // Initialise notifications before anything else.
  await NotificationService.instance.init();

  // Create DB eagerly so local records are ready before the first frame.
  final db = AppDatabase();

  // Attach DB to notification service so action callbacks can write completions.
  NotificationService.instance.attachDatabase(db);
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
  final expiredReminderIds = await db.reminderDao.expirePastStandardReminders();
  for (final id in expiredReminderIds) {
    await NotificationService.instance.cancelReminder(id);
  }
  // Reschedule all enabled future reminders (handles post-reboot case too).
  final reminders = await db.reminderDao.getAllEnabled();
  await NotificationService.instance.rescheduleAll(reminders);

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const DimiApp(),
    ),
  );
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
    _startForegroundSync();
    _authSubscription = SupabaseBootstrap.authChanges.listen((authState) {
      final db = ref.read(databaseProvider);
      SupabaseBootstrap.offlineMode = false;
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
    _syncTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_expirePastReminders());
      unawaited(_syncService.syncNow());
      _startForegroundSync();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _syncTimer?.cancel();
      _syncTimer = null;
    }
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
