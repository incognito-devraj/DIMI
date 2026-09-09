import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';

/// Single instance of AppDatabase for the whole app lifetime.
/// Disposed automatically when the ProviderScope is disposed.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
