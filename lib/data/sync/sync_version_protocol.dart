/// Pure version and comparison rules for the future sync worker.
///
/// This file deliberately does not perform I/O or network work. Local
/// `updated_at` values are provisional; only a value returned by Supabase is
/// an authoritative row version.
enum SyncVersionRelation { localNewer, remoteNewer, equal, conflict }

enum SyncConflictWinner { local, remote }

class SyncVersionProtocol {
  const SyncVersionProtocol._();

  /// Produces a strictly increasing local mutation timestamp.
  ///
  /// This prevents two local writes, or a clock moving backwards, from
  /// collapsing local ordering. It is never used as the authority for a
  /// remote conflict.
  static DateTime localMutationTimestamp({
    required DateTime now,
    DateTime? previousLocalUpdatedAt,
  }) {
    final candidate = now.toUtc();
    if (previousLocalUpdatedAt == null) return candidate;
    final previous = previousLocalUpdatedAt.toUtc();
    return candidate.isAfter(previous)
        ? candidate
        : previous.add(const Duration(milliseconds: 1));
  }

  /// Classifies a pending local mutation against the row currently returned
  /// by Supabase. `baseRemoteUpdatedAt` is the server version observed before
  /// the local mutation was committed.
  static SyncVersionRelation classifyPendingPush({
    required DateTime? baseRemoteUpdatedAt,
    required DateTime? remoteUpdatedAt,
  }) {
    return _same(baseRemoteUpdatedAt, remoteUpdatedAt)
        ? SyncVersionRelation.localNewer
        : SyncVersionRelation.conflict;
  }

  /// Classifies a pull against the last server version applied locally.
  ///
  /// A pending local mutation is compared to its base, not to wall-clock
  /// timestamps. Without a pending mutation, any different server version is
  /// remote-newer, even if its textual timestamp is earlier than a skewed
  /// device clock.
  static SyncVersionRelation classifyPull({
    required DateTime? localServerUpdatedAt,
    required DateTime? remoteUpdatedAt,
    required bool hasPendingLocalMutation,
    DateTime? baseRemoteUpdatedAt,
    bool payloadsEqual = false,
  }) {
    if (hasPendingLocalMutation) {
      return classifyPendingPush(
        baseRemoteUpdatedAt: baseRemoteUpdatedAt,
        remoteUpdatedAt: remoteUpdatedAt,
      );
    }
    if (_same(localServerUpdatedAt, remoteUpdatedAt)) {
      return payloadsEqual
          ? SyncVersionRelation.equal
          : SyncVersionRelation.conflict;
    }
    return SyncVersionRelation.remoteNewer;
  }

  /// Normal entities use remote-wins after a compare-and-swap conflict.
  static SyncConflictWinner normalConflictWinner() =>
      SyncConflictWinner.remote;

  /// A pending tombstone wins over a live update for the same server_id. The
  /// worker must re-read and then write the tombstone as a new server version;
  /// it must not resurrect the old identity as live data.
  static SyncConflictWinner tombstoneConflictWinner() =>
      SyncConflictWinner.local;

  static bool _same(DateTime? left, DateTime? right) {
    if (left == null || right == null) return left == right;
    return left.toUtc() == right.toUtc();
  }
}
