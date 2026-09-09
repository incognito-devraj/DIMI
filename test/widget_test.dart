// Smoke test — verifies the full widget tree renders without throwing.
// Uses an in-memory Drift database so no disk I/O is needed in CI.
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dimi_app/main.dart';
import 'package:dimi_app/data/database.dart';
import 'package:dimi_app/providers/database_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // In-memory DB — no seed, no disk access.
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DimiApp(),
      ),
    );

    // Allow the router and first frame to settle.
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(milliseconds: 100));

    // App should be running — no exceptions.
    expect(find.byType(DimiApp), findsOneWidget);

    await db.close();
  });
}
