import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'data/seed_data.dart';
import 'providers/database_provider.dart';
import 'routing/app_router.dart';
import 'services/notification_service.dart';
import 'features/transaction_detection/transaction_detection_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise notifications before anything else.
  await NotificationService.instance.init();

  // Create DB eagerly so we can seed / reschedule before first frame.
  final db = AppDatabase();
  // Drain events captured while the Flutter UI was closed. Parsing remains
  // local and happens after the first database connection is available.
  await TransactionDetectionService(db).syncPendingEvents();

  if (kDebugMode) {
    final profile = await db.profileDao.getProfile();
    if (profile == null) {
      await seedDatabase(db);
    }
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
  @override ConsumerState<DimiApp> createState() => _DimiAppState();
}

class _DimiAppState extends ConsumerState<DimiApp> {
  Timer? _syncTimer;
  @override void initState() {
    super.initState();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) => TransactionDetectionService(ref.read(databaseProvider)).syncPendingEvents());
  }
  @override void dispose() { _syncTimer?.cancel(); super.dispose(); }
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
