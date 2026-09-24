import 'package:flutter_test/flutter_test.dart';

import 'package:dimi_app/data/sync/sync_version_protocol.dart';

void main() {
  final base = DateTime.utc(2026, 1, 1, 12, 0, 0, 100);
  final later = DateTime.utc(2026, 1, 1, 12, 0, 0, 200);

  test('local mutation timestamp is monotonic despite equal or skewed clocks', () {
    expect(
      SyncVersionProtocol.localMutationTimestamp(now: base),
      base,
    );
    expect(
      SyncVersionProtocol.localMutationTimestamp(now: base, previousLocalUpdatedAt: base),
      DateTime.utc(2026, 1, 1, 12, 0, 0, 101),
    );
    expect(
      SyncVersionProtocol.localMutationTimestamp(
        now: DateTime.utc(2025, 1, 1),
        previousLocalUpdatedAt: later,
      ),
      DateTime.utc(2026, 1, 1, 12, 0, 0, 201),
    );
  });

  test('pending local edit is newer when remote still equals its base', () {
    expect(
      SyncVersionProtocol.classifyPendingPush(
        baseRemoteUpdatedAt: base,
        remoteUpdatedAt: base,
      ),
      SyncVersionRelation.localNewer,
    );
    expect(
      SyncVersionProtocol.classifyPull(
        localServerUpdatedAt: base,
        remoteUpdatedAt: base,
        hasPendingLocalMutation: true,
        baseRemoteUpdatedAt: base,
      ),
      SyncVersionRelation.localNewer,
    );
  });

  test('remote change after the local base is a conflict, not local wins by clock', () {
    final deviceClockAhead = DateTime.utc(2035, 1, 1);
    expect(
      SyncVersionProtocol.classifyPendingPush(
        baseRemoteUpdatedAt: base,
        remoteUpdatedAt: later,
      ),
      SyncVersionRelation.conflict,
    );
    expect(SyncVersionProtocol.normalConflictWinner(), SyncConflictWinner.remote);
    expect(deviceClockAhead.isAfter(later), isTrue);
  });

  test('equal server version is equal only when payload is equal', () {
    expect(
      SyncVersionProtocol.classifyPull(
        localServerUpdatedAt: base,
        remoteUpdatedAt: base,
        hasPendingLocalMutation: false,
        payloadsEqual: true,
      ),
      SyncVersionRelation.equal,
    );
    expect(
      SyncVersionProtocol.classifyPull(
        localServerUpdatedAt: base,
        remoteUpdatedAt: base,
        hasPendingLocalMutation: false,
      ),
      SyncVersionRelation.conflict,
    );
  });

  test('a different remote version is remote-newer without comparing device clocks', () {
    expect(
      SyncVersionProtocol.classifyPull(
        localServerUpdatedAt: later,
        remoteUpdatedAt: base,
        hasPendingLocalMutation: false,
      ),
      SyncVersionRelation.remoteNewer,
    );
  });

  test('tombstone conflict is delete-wins', () {
    expect(SyncVersionProtocol.tombstoneConflictWinner(), SyncConflictWinner.local);
  });
}
