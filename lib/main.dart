import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'providers/database_provider.dart';
import 'routing/app_router.dart';
import 'services/notification_service.dart';
import 'features/transaction_detection/transaction_detection_service.dart';
import 'theme/app_theme.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseBootstrap.initialize();

  // Initialise notifications before anything else.
  await NotificationService.instance.init();

  // Create DB eagerly so local records are ready before the first frame.
  final db = AppDatabase();
  await db.clearLegacyDemoContent();
  // Drain events captured while the Flutter UI was closed. Parsing remains
  // local and happens after the first database connection is available.
  await TransactionDetectionService(db).syncPendingEvents();

  if (SupabaseConfig.isConfigured) {
    await AuthService.instance.syncLocalProfile(db);
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

class _DimiAppState extends ConsumerState<DimiApp> {
  Timer? _syncTimer;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _syncTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) =>
          TransactionDetectionService(ref.read(databaseProvider))
              .syncPendingEvents(),
    );
    _authSubscription = SupabaseBootstrap.authChanges.listen((authState) {
      if (authState.session == null) {
        SupabaseBootstrap.offlineMode = false;
      }
      unawaited(
        AuthService.instance.syncLocalProfile(ref.read(databaseProvider)),
      );
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
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
