// Regression tests for the YouTube video completion sync bug.
//
// Root cause that was fixed:
//   _applyRemote() in SyncService unconditionally overwrote ALL fields from
//   the remote row — including `completed`, `watched_at`,
//   `last_position_seconds`, and `progress_updated_at` — on every pull and
//   conflict-resolution pass.  If the remote row still had completed = false
//   the local completion state was silently reset to false.
//
// Fix applied:
//   • _Field gained `preserveOnRemoteApply: true` for the four user-progress
//     columns in the video _SyncSpec.  _applyRemote skips those columns when
//     updating an existing local row.  They are still sent to Supabase via
//     the push payload so Supabase receives the correct completed value.
//   • setCompleted now uses a single SyncVersionProtocol.localMutationTimestamp
//     call so completed, watchedAt, progressUpdatedAt and updatedAt are all
//     stamped with the same coherent instant, avoiding CAS anchor ambiguity.
//   • SyncService accepts an optional testContext to bypass the Supabase auth
//     guard in unit tests.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dimi_app/data/database.dart';
import 'package:dimi_app/data/daos/sync_outbox_dao.dart';
import 'package:dimi_app/data/sync/sync_remote_api.dart';
import 'package:dimi_app/services/sync_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Minimal in-memory remote mock
// ─────────────────────────────────────────────────────────────────────────────

class _InMemoryRemote implements SyncRemoteApi {
  final _store = <String, Map<String, dynamic>>{};
  int insertCount = 0;
  int updateCount = 0;

  static String _databaseTimestamp() {
    // PostgreSQL timestamptz retains sub-second precision. Drift's local
    // DateTime columns do not, so this ensures the test exercises the same
    // CAS version boundary as Supabase.
    return DateTime.now().toUtc().toIso8601String();
  }

  String _key(String table, String id) => '$table:$id';

  @override
  Future<Map<String, dynamic>?> getRow(String table, String serverId) async =>
      _store[_key(table, serverId)];

  @override
  Future<Map<String, dynamic>> insertRow(
    String table,
    Map<String, dynamic> payload,
  ) async {
    insertCount++;
    final id = payload['id'] as String;
    // Simulate the Supabase trigger that sets updated_at on insert.
    // Also normalize SQLite 0/1 integers to Dart bools for boolean columns so
    // the mock behaves like a real Postgres/Supabase response.
    final row = payload.map((k, v) => MapEntry(k, _normalize(v, k)))
      ..['updated_at'] = _databaseTimestamp();
    _store[_key(table, id)] = row;
    return row;
  }

  @override
  Future<Map<String, dynamic>?> updateRow(
    String table,
    String serverId,
    DateTime expectedUpdatedAt,
    Map<String, dynamic> payload,
  ) async {
    updateCount++;
    final key = _key(table, serverId);
    final existing = _store[key];
    if (existing == null) return null;
    final remoteAt = existing['updated_at'] as String?;
    if (remoteAt == null) return null;
    // CAS: reject if the expected version doesn't match the stored version.
    final remoteVersion = DateTime.parse(remoteAt).toUtc();
    if (remoteVersion != expectedUpdatedAt.toUtc()) return null;
    final updated = payload.map((k, v) => MapEntry(k, _normalize(v, k)))
      ..['updated_at'] = _databaseTimestamp();
    _store[key] = updated;
    return updated;
  }

  @override
  Future<List<Map<String, dynamic>>> pullRows(
    String table,
    String userId,
    DateTime? after,
  ) async => _store.entries
      .where((e) => e.key.startsWith('$table:'))
      .map((e) => e.value)
      .toList();

  /// Directly overwrite a remote row (simulates a stale pull arriving before
  /// the local push has propagated to Supabase).
  void overwrite(String table, Map<String, dynamic> row) {
    final id = row['id'] as String;
    _store[_key(table, id)] = row.map((k, v) => MapEntry(k, _normalize(v)));
  }

  /// Normalize known boolean columns from SQLite 0/1 integers to Dart bools
  /// so that the mock behaves like a real Postgres/Supabase JSON response.
  static final _boolColumns = {
    'completed',
    'is_completed',
    'is_planner_entry',
    'is_enabled',
  };
  static Object? _normalize(Object? v, [String? key]) {
    if (key != null && _boolColumns.contains(key) && v is int) return v == 1;
    return v;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Test setup helpers
// ─────────────────────────────────────────────────────────────────────────────

const _fakeUserId = 'test-user-00000000-0000-0000-0000-000000000001';

/// Creates a local "authenticated" account row (authProvider = 'supabase')
/// and returns a synthetic auth context that can be injected into SyncService
/// via the testContext parameter, bypassing the Supabase auth guard.
Future<({int localAccountId, String authUserId, int generation})>
_makeAuthContext(AppDatabase db) async {
  final accountId = await db.localAccountDao.ensureAuthenticatedAccount(
    userId: _fakeUserId,
    email: 'test@dimi.test',
    displayName: 'Test User',
    avatarUrl: null,
  );
  return (localAccountId: accountId, authUserId: _fakeUserId, generation: 0);
}

SyncService _service(
  AppDatabase db,
  _InMemoryRemote remote,
  SharedPreferences prefs,
  ({int localAccountId, String authUserId, int generation}) ctx,
) => SyncService(db, remote: remote, preferences: prefs, testContext: ctx);

/// Insert a playlist + one video, push the creates to the in-memory remote,
/// then return the local video's row id and the server_id assigned by the push.
Future<({int playlistId, int videoId, String videoServerId})> _seedAndSync(
  AppDatabase db,
  _InMemoryRemote remote,
  SharedPreferences prefs,
  ({int localAccountId, String authUserId, int generation}) ctx,
) async {
  final now = DateTime.utc(2026, 1, 1, 10);
  final playlistId = await db.youtubePlaylistDao.savePlaylist(
    playlist: YoutubePlaylistsCompanion.insert(
      youtubePlaylistId: 'PL_test',
      title: 'Test Playlist',
      description: const Value(''),
      channelTitle: const Value('Channel'),
      thumbnailUrl: const Value(''),
      totalVideos: const Value(1),
      totalDurationSeconds: const Value(120),
      createdAt: now,
      updatedAt: now,
      lastSyncedAt: Value(now),
    ),
    videos: [
      YoutubeVideosCompanion(
        youtubeVideoId: const Value('VID_1'),
        title: const Value('Video One'),
        position: const Value(1),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    ],
  );

  // Push the create operations so the video has a server_id.
  await _service(db, remote, prefs, ctx).syncNow();

  final videos = await db.youtubePlaylistDao.getVideos(playlistId);
  final v = videos.single;
  assert(
    v.serverId != null,
    'server_id must be assigned after the create push',
  );
  return (playlistId: playlistId, videoId: v.id, videoServerId: v.serverId!);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late _InMemoryRemote remote;
  late SharedPreferences prefs;
  late ({int localAccountId, String authUserId, int generation}) ctx;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ctx = await _makeAuthContext(db);
    remote = _InMemoryRemote();
  });

  tearDown(() => db.close());

  // ── A. false → true is synced ─────────────────────────────────────────────

  test('A: false → true is synced to Supabase', () async {
    final seed = await _seedAndSync(db, remote, prefs, ctx);

    // Remote starts with completed = false after the create push.
    expect(
      remote._store['dim_youtube_videos:${seed.videoServerId}']!['completed'],
      isFalse,
    );

    // Mark completed locally.
    await db.youtubePlaylistDao.setCompleted(seed.videoId, true);

    // Local DB must reflect the change immediately.
    final local = await (db.select(
      db.youtubeVideos,
    )..where((v) => v.id.equals(seed.videoId))).getSingle();
    expect(local.completed, isTrue);
    expect(local.watchedAt, isNotNull);
    expect(local.progressUpdatedAt, isNotNull);

    // Outbox must have a pending update entry.
    final outbox =
        await (db.select(db.syncOutbox)..where(
              (o) =>
                  o.localRowId.equals(seed.videoId) &
                  o.entityType.equals(OutboxEntity.video),
            ))
            .getSingle();
    expect(outbox.operation, OutboxOperation.update);
    expect(outbox.state, OutboxState.pending);

    // Sync → completed = true must be pushed to Supabase.
    await _service(db, remote, prefs, ctx).syncNow();

    expect(
      remote._store['dim_youtube_videos:${seed.videoServerId}']!['completed'],
      isTrue,
      reason: 'Supabase must have completed = true after the push',
    );
  });

  // ── B. true → false is synced ─────────────────────────────────────────────

  test('B: true → false is synced to Supabase', () async {
    final seed = await _seedAndSync(db, remote, prefs, ctx);

    // Mark true and sync.
    await db.youtubePlaylistDao.setCompleted(seed.videoId, true);
    await _service(db, remote, prefs, ctx).syncNow();
    expect(
      remote._store['dim_youtube_videos:${seed.videoServerId}']!['completed'],
      isTrue,
    );

    // Mark false.
    await db.youtubePlaylistDao.setCompleted(seed.videoId, false);

    final local = await (db.select(
      db.youtubeVideos,
    )..where((v) => v.id.equals(seed.videoId))).getSingle();
    expect(local.completed, isFalse);
    expect(local.watchedAt, isNull);

    // Sync → completed = false must reach Supabase.
    await _service(db, remote, prefs, ctx).syncNow();
    expect(
      remote._store['dim_youtube_videos:${seed.videoServerId}']!['completed'],
      isFalse,
      reason: 'Supabase must have completed = false after the un-watch push',
    );
  });

  // ── C. Offline completion is queued and syncs after reconnect ─────────────

  test('C: offline completion is queued and syncs after reconnect', () async {
    final seed = await _seedAndSync(db, remote, prefs, ctx);

    // Mark completed while "offline" (no syncNow call).
    await db.youtubePlaylistDao.setCompleted(seed.videoId, true);

    // Local must be true.
    final local = await (db.select(
      db.youtubeVideos,
    )..where((v) => v.id.equals(seed.videoId))).getSingle();
    expect(local.completed, isTrue);

    // Outbox must hold a pending entry.
    expect(
      await db.syncOutboxDao.pendingCount(db.activeAccountId),
      greaterThanOrEqualTo(1),
    );

    // "Reconnect": run a sync and verify Supabase is updated.
    await _service(db, remote, prefs, ctx).syncNow();
    expect(
      remote._store['dim_youtube_videos:${seed.videoServerId}']!['completed'],
      isTrue,
      reason: 'offline completion must sync after reconnect',
    );
  });

  // ── D. Metadata refresh (savePlaylist) preserves completion state ─────────

  test(
    'D: savePlaylist metadata refresh does not reset a completed video',
    () async {
      final seed = await _seedAndSync(db, remote, prefs, ctx);

      // Mark completed and sync so the outbox entry is cleared.
      await db.youtubePlaylistDao.setCompleted(seed.videoId, true);
      await _service(db, remote, prefs, ctx).syncNow();

      // Simulate a metadata refresh: re-save the playlist with fresh API data.
      // Fresh API data carries completed = false (default value in the schema);
      // the DAO must detect the existing row and preserve completed = true.
      final refreshNow = DateTime.now().toUtc();
      await db.youtubePlaylistDao.savePlaylist(
        playlist: YoutubePlaylistsCompanion.insert(
          youtubePlaylistId: 'PL_test',
          title: 'Test Playlist (refreshed title)',
          description: const Value(''),
          channelTitle: const Value('Channel'),
          thumbnailUrl: const Value(''),
          totalVideos: const Value(1),
          totalDurationSeconds: const Value(120),
          createdAt: refreshNow,
          updatedAt: refreshNow,
          lastSyncedAt: Value(refreshNow),
        ),
        videos: [
          YoutubeVideosCompanion(
            youtubeVideoId: const Value('VID_1'),
            title: const Value('Video One (refreshed)'),
            position: const Value(1),
            createdAt: Value(refreshNow),
            updatedAt: Value(refreshNow),
          ),
        ],
      );

      // Local completion must still be true after the metadata refresh.
      final local = await (db.select(
        db.youtubeVideos,
      )..where((v) => v.id.equals(seed.videoId))).getSingle();
      expect(
        local.completed,
        isTrue,
        reason: 'savePlaylist metadata refresh must preserve completed = true',
      );
      expect(local.watchedAt, isNotNull);
    },
  );

  // ── D2. Remote pull after a successful push preserves completed = true ─────

  test(
    'D2: remote pull after a successful push preserves completed = true',
    () async {
      final seed = await _seedAndSync(db, remote, prefs, ctx);

      // Mark completed and push successfully.
      await db.youtubePlaylistDao.setCompleted(seed.videoId, true);
      await _service(db, remote, prefs, ctx).syncNow();
      expect(
        remote._store['dim_youtube_videos:${seed.videoServerId}']!['completed'],
        isTrue,
      );

      // Run a second full sync cycle (includes a pull pass).
      // The pull may return the same row; local completed must remain true.
      await _service(db, remote, prefs, ctx).syncNow();

      final local = await (db.select(
        db.youtubeVideos,
      )..where((v) => v.id.equals(seed.videoId))).getSingle();
      expect(
        local.completed,
        isTrue,
        reason: 'pull pass must not reset completed after a successful push',
      );
    },
  );

  // ── D3. Stale pull (completed=false) does not overwrite local completed=true

  test('D3: stale remote pull (completed=false) does not overwrite '
      'pending local completed=true', () async {
    final seed = await _seedAndSync(db, remote, prefs, ctx);

    // Mark completed locally but do NOT sync yet (outbox entry is pending).
    await db.youtubePlaylistDao.setCompleted(seed.videoId, true);

    // Inject a stale remote row with completed = false into the pull store,
    // simulating a pull arriving before the local push has propagated.
    final stale = Map<String, dynamic>.from(
      remote._store['dim_youtube_videos:${seed.videoServerId}']!,
    )..['completed'] = false;
    remote.overwrite('dim_youtube_videos', stale);

    // Sync: push should send completed = true; pull should see the pending
    // outbox entry and skip the stale row.
    await _service(db, remote, prefs, ctx).syncNow();

    final local = await (db.select(
      db.youtubeVideos,
    )..where((v) => v.id.equals(seed.videoId))).getSingle();
    expect(
      local.completed,
      isTrue,
      reason: 'stale pull must not overwrite a pending local completion',
    );
    // Supabase must now have completed = true from the push.
    expect(
      remote._store['dim_youtube_videos:${seed.videoServerId}']!['completed'],
      isTrue,
    );
  });

  // ── E. Repeated completion changes coalesce safely ────────────────────────

  test(
    'E: repeated completion toggles coalesce to a single outbox entry',
    () async {
      final seed = await _seedAndSync(db, remote, prefs, ctx);

      // Toggle multiple times without syncing.
      await db.youtubePlaylistDao.setCompleted(seed.videoId, true);
      await db.youtubePlaylistDao.setCompleted(seed.videoId, false);
      await db.youtubePlaylistDao.setCompleted(seed.videoId, true);

      // Must be exactly one outbox entry for this video.
      final entries =
          await (db.select(db.syncOutbox)..where(
                (o) =>
                    o.localRowId.equals(seed.videoId) &
                    o.entityType.equals(OutboxEntity.video),
              ))
              .get();
      expect(
        entries,
        hasLength(1),
        reason: 'repeated toggles must coalesce to one outbox entry',
      );
      expect(entries.single.operation, OutboxOperation.update);

      // Sync — the final state (true) must be what reaches Supabase.
      await _service(db, remote, prefs, ctx).syncNow();
      expect(
        remote._store['dim_youtube_videos:${seed.videoServerId}']!['completed'],
        isTrue,
        reason: 'last toggle (true) must be what is synced',
      );

      // Local state must match.
      final local = await (db.select(
        db.youtubeVideos,
      )..where((v) => v.id.equals(seed.videoId))).getSingle();
      expect(local.completed, isTrue);
    },
  );

  // ── F. Tombstone (deletePlaylist) behavior unchanged ─────────────────────

  test('F: deleting a playlist creates tombstones and does not affect '
      'other playlists', () async {
    final seed = await _seedAndSync(db, remote, prefs, ctx);

    // Mark the video completed and sync.
    await db.youtubePlaylistDao.setCompleted(seed.videoId, true);
    await _service(db, remote, prefs, ctx).syncNow();

    // Add a second, unrelated playlist to verify ownership isolation.
    final now2 = DateTime.now().toUtc();
    final playlist2Id = await db.youtubePlaylistDao.savePlaylist(
      playlist: YoutubePlaylistsCompanion.insert(
        youtubePlaylistId: 'PL_other',
        title: 'Other Playlist',
        description: const Value(''),
        channelTitle: const Value('Channel'),
        thumbnailUrl: const Value(''),
        totalVideos: const Value(1),
        totalDurationSeconds: const Value(60),
        createdAt: now2,
        updatedAt: now2,
        lastSyncedAt: Value(now2),
      ),
      videos: [
        YoutubeVideosCompanion(
          youtubeVideoId: const Value('VID_2'),
          title: const Value('Video Two'),
          position: const Value(1),
          createdAt: Value(now2),
          updatedAt: Value(now2),
        ),
      ],
    );
    await _service(db, remote, prefs, ctx).syncNow();

    // Delete the first playlist.
    await db.youtubePlaylistDao.deletePlaylist(seed.playlistId);

    // First video must be soft-deleted (tombstone).
    final v1 = await (db.select(
      db.youtubeVideos,
    )..where((v) => v.id.equals(seed.videoId))).getSingle();
    expect(
      v1.deletedAt,
      isNotNull,
      reason: 'video in deleted playlist must have a deletedAt tombstone',
    );

    // Second playlist's videos must be untouched.
    final p2videos = await db.youtubePlaylistDao.getVideos(playlist2Id);
    expect(
      p2videos,
      hasLength(1),
      reason: 'other playlist must not be affected by the tombstone',
    );
    expect(p2videos.single.deletedAt, isNull);

    // Outbox must have a delete entry for the first video.
    final tombstone =
        await (db.select(db.syncOutbox)..where(
              (o) =>
                  o.localRowId.equals(seed.videoId) &
                  o.entityType.equals(OutboxEntity.video),
            ))
            .getSingleOrNull();
    expect(tombstone, isNotNull);
    expect(tombstone!.operation, OutboxOperation.delete);
  });

  // ── Monotonic timestamp ───────────────────────────────────────────────────

  test('G: YouTube videos remain isolated to the active account', () async {
    final seed = await _seedAndSync(db, remote, prefs, ctx);
    final otherAccount = await db.localAccountDao.ensureAuthenticatedAccount(
      userId: 'test-user-00000000-0000-0000-0000-000000000002',
      email: 'other@dimi.test',
      displayName: 'Other User',
      avatarUrl: null,
    );

    expect(db.activeAccountId, otherAccount);
    expect(await db.youtubePlaylistDao.getVideos(seed.playlistId), isEmpty);

    await db.localAccountDao.activate(ctx.localAccountId);
    expect(
      (await db.youtubePlaylistDao.getVideos(seed.playlistId)).single.id,
      seed.videoId,
    );
  });

  test('existing remote video promotes stale CREATE to UPDATE', () async {
    final seed = await _seedAndSync(db, remote, prefs, ctx);
    final insertsBefore = remote.insertCount;
    final updatesBefore = remote.updateCount;

    // Reproduce an interrupted create entry whose remote row already exists.
    await db.syncOutboxDao.enqueue(
      localAccountId: db.activeAccountId,
      entityType: OutboxEntity.video,
      localRowId: seed.videoId,
      operation: OutboxOperation.create,
      serverId: seed.videoServerId,
      dependencyRank: OutboxDependencyRank.video,
    );
    await db.youtubePlaylistDao.setCompleted(seed.videoId, true);
    final queued = await (db.select(db.syncOutbox)
          ..where((o) =>
              o.localRowId.equals(seed.videoId) &
              o.entityType.equals(OutboxEntity.video)))
        .getSingle();
    expect(queued.operation, OutboxOperation.create);

    await _service(db, remote, prefs, ctx).syncNow();

    expect(remote.insertCount, insertsBefore);
    expect(remote.updateCount, updatesBefore + 1);
    expect(
      remote._store['dim_youtube_videos:${seed.videoServerId}']!['completed'],
      isTrue,
    );
  });

  test('profile pull coerces remote scalars and does not block video sync',
      () async {
    final seed = await _seedAndSync(db, remote, prefs, ctx);
    final profile = <String, dynamic>{
      'id': 'profile-server-id',
      'user_id': _fakeUserId,
      'role': 'Student',
      'phone': '123',
      'college': 'DIMI',
      'semester': '6',
      'points': '42',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'deleted_at': null,
    };
    remote.overwrite('dim_profile_data', profile);

    await db.youtubePlaylistDao.setCompleted(seed.videoId, true);
    await _service(db, remote, prefs, ctx).syncNow();

    final localProfile = await (db.select(db.profileData)
          ..where((p) => p.localAccountId.equals(db.activeAccountId)))
        .getSingle();
    expect(localProfile.points, 42);
    expect(
      remote._store['dim_youtube_videos:${seed.videoServerId}']!['completed'],
      isTrue,
    );
  });

  test('setCompleted stamps completed/watchedAt/progressUpdatedAt/updatedAt '
      'with the same monotonically-increasing instant', () async {
    final seed = await _seedAndSync(db, remote, prefs, ctx);

    final before = await (db.select(
      db.youtubeVideos,
    )..where((v) => v.id.equals(seed.videoId))).getSingle();

    await db.youtubePlaylistDao.setCompleted(seed.videoId, true);

    final after = await (db.select(
      db.youtubeVideos,
    )..where((v) => v.id.equals(seed.videoId))).getSingle();

    // updatedAt must be strictly after (or equal to) the pre-mutation value.
    expect(
      after.updatedAt.millisecondsSinceEpoch >=
          before.updatedAt.millisecondsSinceEpoch,
      isTrue,
      reason: 'updatedAt must be monotonically non-decreasing',
    );
    // All three progress timestamps must share the same instant.
    expect(
      after.progressUpdatedAt?.millisecondsSinceEpoch,
      equals(after.updatedAt.millisecondsSinceEpoch),
      reason: 'progressUpdatedAt must equal updatedAt',
    );
    expect(
      after.watchedAt?.millisecondsSinceEpoch,
      equals(after.updatedAt.millisecondsSinceEpoch),
      reason: 'watchedAt must equal updatedAt when completing',
    );
  });
}
