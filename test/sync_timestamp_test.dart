import 'package:flutter_test/flutter_test.dart';

import 'package:dimi_app/data/sync/sync_timestamp.dart';

void main() {
  test('tombstone timestamp serialized from epoch seconds stays current', () {
    final expected = DateTime.utc(2026, 9, 19, 12, 34, 56, 988);
    final epochSeconds = expected.millisecondsSinceEpoch ~/ 1000;

    final serialized = SyncTimestamp.toUtcIso8601(epochSeconds)!;

    expect(DateTime.parse(serialized).year, 2026);
    expect(DateTime.parse(serialized).year, isNot(1970));
    expect(serialized, startsWith('2026-09-19T'));
  });

  test('DateTime timestamps serialize as ISO-8601 UTC', () {
    final serialized = SyncTimestamp.toUtcIso8601(
      DateTime.utc(2026, 9, 19, 12, 34, 56),
    );

    expect(serialized, '2026-09-19T12:34:56.000Z');
  });
}
