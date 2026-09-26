import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database.dart';
import '../tables/youtube_playlists.dart';
import '../tables/youtube_videos.dart';
import '../sync/sync_version_protocol.dart';
import '../sync/sync_timestamp.dart';
import 'sync_outbox_dao.dart';

part 'youtube_playlist_dao.g.dart';

@DriftAccessor(tables: [YoutubePlaylists, YoutubeVideos])
class YoutubePlaylistDao extends DatabaseAccessor<AppDatabase>
    with _$YoutubePlaylistDaoMixin {
  YoutubePlaylistDao(super.db);

  Stream<List<YoutubePlaylist>> watchForUser(String userId) =>
      (select(youtubePlaylists)
            ..where(
              (p) =>
                  p.localAccountId.equals(db.activeAccountId) &
                  p.deletedAt.isNull(),
            )
            ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
          .watch();

  Stream<YoutubePlaylist?> watchById(int id) =>
      (select(youtubePlaylists)..where(
            (p) =>
                p.id.equals(id) &
                p.localAccountId.equals(db.activeAccountId) &
                p.deletedAt.isNull(),
          ))
          .watchSingleOrNull();

  Future<YoutubePlaylist?> getByYoutubeId(String userId, String playlistId) =>
      (select(youtubePlaylists)..where(
            (p) =>
                p.localAccountId.equals(db.activeAccountId) &
                p.deletedAt.isNull() &
                p.youtubePlaylistId.equals(playlistId),
          ))
          .getSingleOrNull();

  Future<YoutubePlaylist?> getByTitle(String title) =>
      (select(youtubePlaylists)..where(
            (p) =>
                p.localAccountId.equals(db.activeAccountId) &
                p.deletedAt.isNull() &
                p.title.equals(title),
          ))
          .getSingleOrNull();

  Stream<List<YoutubeVideo>> watchVideos(int playlistId) =>
      (select(youtubeVideos).join([
              innerJoin(
                youtubePlaylists,
                youtubePlaylists.id.equalsExp(youtubeVideos.playlistLocalId),
              ),
            ])
            ..where(
              youtubePlaylists.id.equals(playlistId) &
                  youtubePlaylists.localAccountId.equals(db.activeAccountId) &
                  youtubePlaylists.deletedAt.isNull() &
                  youtubeVideos.deletedAt.isNull(),
            )
            ..orderBy([OrderingTerm.asc(youtubeVideos.position)]))
          .watch()
          .map(
            (rows) => rows.map((row) => row.readTable(youtubeVideos)).toList(),
          );

  Future<List<YoutubeVideo>> getVideos(int playlistId) async {
    final rows =
        await (select(youtubeVideos).join([
                innerJoin(
                  youtubePlaylists,
                  youtubePlaylists.id.equalsExp(youtubeVideos.playlistLocalId),
                ),
              ])
              ..where(
                youtubePlaylists.id.equals(playlistId) &
                    youtubePlaylists.localAccountId.equals(db.activeAccountId) &
                    youtubePlaylists.deletedAt.isNull() &
                    youtubeVideos.deletedAt.isNull(),
              )
              ..orderBy([OrderingTerm.asc(youtubeVideos.position)]))
            .get();
    return rows.map((row) => row.readTable(youtubeVideos)).toList();
  }

  Future<int> savePlaylist({
    required YoutubePlaylistsCompanion playlist,
    required List<YoutubeVideosCompanion> videos,
  }) async {
    return transaction(() async {
      final existing =
          await (select(youtubePlaylists)..where(
                (p) =>
                    p.localAccountId.equals(db.activeAccountId) &
                    p.deletedAt.isNull() &
                    p.youtubePlaylistId.equals(
                      playlist.youtubePlaylistId.value,
                    ),
              ))
              .getSingleOrNull();
      final localId = existing == null
          ? await into(youtubePlaylists).insert(
              playlist.copyWith(localAccountId: Value(db.activeAccountId)),
            )
          : await (update(
              youtubePlaylists,
            )..where((p) => p.id.equals(existing.id))).write(
              playlist.copyWith(
                id: Value(existing.id),
                localAccountId: Value(db.activeAccountId),
              ),
            );
      final playlistRow = await (select(
        youtubePlaylists,
      )..where((p) => p.id.equals(localId))).getSingle();
      await db.syncOutboxDao.enqueue(
        localAccountId: db.activeAccountId,
        entityType: OutboxEntity.playlist,
        localRowId: localId,
        operation: existing == null
            ? OutboxOperation.create
            : OutboxOperation.update,
        serverId: playlistRow.serverId,
        baseRemoteUpdatedAt: existing?.updatedAt,
        localMutationAt: playlistRow.updatedAt,
        dependencyRank: OutboxDependencyRank.playlist,
      );
      final existingVideos =
          await (select(youtubeVideos)..where(
                (v) => v.playlistLocalId.equals(localId) & v.deletedAt.isNull(),
              ))
              .get();
      final progressByVideoId = {
        for (final video in existingVideos) video.youtubeVideoId: video,
      };
      for (final video in videos) {
        final previous = progressByVideoId[video.youtubeVideoId.value];
        final metadata = video.copyWith(
          playlistLocalId: Value(localId),
          completed: previous == null
              ? const Value(false)
              : Value(previous.completed),
          watchedAt: previous == null
              ? const Value(null)
              : Value(previous.watchedAt),
          lastPositionSeconds: previous == null
              ? const Value(0)
              : Value(previous.lastPositionSeconds),
          progressUpdatedAt: previous == null
              ? const Value(null)
              : Value(previous.progressUpdatedAt),
        );
        if (previous == null) {
          await into(youtubeVideos).insert(metadata);
        } else {
          // The natural key is (playlist_local_id, youtube_video_id), not the
          // local integer id. Update the existing row explicitly so metadata
          // refreshes cannot create a duplicate or lose local progress.
          await (update(youtubeVideos)
                ..where((v) => v.id.equals(previous.id)))
              .write(metadata.copyWith(id: Value(previous.id)));
        }
        final savedVideo =
            await (select(youtubeVideos)..where(
                  (v) =>
                      v.playlistLocalId.equals(localId) &
                      v.youtubeVideoId.equals(video.youtubeVideoId.value),
                ))
                .getSingle();
        await db.syncOutboxDao.enqueue(
          localAccountId: db.activeAccountId,
          entityType: OutboxEntity.video,
          localRowId: savedVideo.id,
          operation: previous == null
              ? OutboxOperation.create
              : OutboxOperation.update,
          serverId: savedVideo.serverId,
          baseRemoteUpdatedAt: _remoteVersion(previous),
          localMutationAt: savedVideo.updatedAt,
          dependencyRank: OutboxDependencyRank.video,
        );
      }
      return localId;
    });
  }

  Future<void> setCompleted(int videoId, bool value) async {
    final before =
        await (select(youtubeVideos)
              ..where((v) => v.id.equals(videoId) & v.deletedAt.isNull()))
            .getSingleOrNull();
    if (before == null) {
      debugPrint('[DIMI youtube completion] DAO missing video localId=$videoId');
      return;
    }
    final owned =
        await (select(youtubeVideos).join([
              innerJoin(
                youtubePlaylists,
                youtubePlaylists.id.equalsExp(youtubeVideos.playlistLocalId),
              ),
            ])..where(
              youtubeVideos.id.equals(videoId) &
                  youtubeVideos.deletedAt.isNull() &
                  youtubePlaylists.localAccountId.equals(db.activeAccountId) &
                  youtubePlaylists.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (owned == null) {
      debugPrint(
        '[DIMI youtube completion] DAO rejected unowned video '
        'localId=$videoId activeAccount=${db.activeAccountId}',
      );
      return;
    }
    debugPrint(
      '[DIMI youtube completion] DAO before localId=$videoId '
      'account=${db.activeAccountId} serverId=${before.serverId} '
      'completed=${before.completed} desired=$value '
      'remoteVersion=${before.remoteUpdatedAt}',
    );
    // Use a single, strictly-increasing timestamp for this mutation so that
    // completed, watchedAt, progressUpdatedAt and updatedAt are all coherent
    // and the outbox baseRemoteUpdatedAt CAS anchor is unambiguous.
    final now = SyncVersionProtocol.localMutationTimestamp(
      now: DateTime.now().toUtc(),
      previousLocalUpdatedAt: before.updatedAt,
    );
    await (update(youtubeVideos)..where((v) => v.id.equals(videoId))).write(
      YoutubeVideosCompanion(
        completed: Value(value),
        watchedAt: Value(value ? now : null),
        progressUpdatedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final video = await (select(
      youtubeVideos,
    )..where((v) => v.id.equals(videoId))).getSingle();
    debugPrint(
      '[DIMI youtube completion] DAO after localId=${video.id} '
      'account=${db.activeAccountId} serverId=${video.serverId} '
      'completed=${video.completed} watchedAt=${video.watchedAt} '
      'updatedAt=${video.updatedAt}',
    );
    await db.syncOutboxDao.enqueue(
      localAccountId: db.activeAccountId,
      entityType: OutboxEntity.video,
      localRowId: videoId,
      operation: OutboxOperation.update,
      serverId: video.serverId,
      baseRemoteUpdatedAt: _remoteVersion(before),
      localMutationAt: video.updatedAt,
      dependencyRank: OutboxDependencyRank.video,
    );
    final outbox = await (db.select(db.syncOutbox)
          ..where((o) =>
              o.localAccountId.equals(db.activeAccountId) &
              o.entityType.equals(OutboxEntity.video) &
              o.localRowId.equals(video.id)))
        .getSingleOrNull();
    debugPrint(
      '[DIMI youtube completion] DAO outbox localId=${video.id} '
      'account=${db.activeAccountId} entity=${outbox?.entityType} '
      'operation=${outbox?.operation} serverId=${outbox?.serverId} '
      'state=${outbox?.state} base=${outbox?.baseRemoteUpdatedAt}',
    );
  }

  /// Completes videos in this playlist that were watched today. This is used
  /// by the notification action so "Mark done" performs the same local-first
  /// completion write as the playlist screen.
  Future<int> markWatchedToday(int playlistId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final videos = await (select(youtubeVideos).join([
          innerJoin(
            youtubePlaylists,
            youtubePlaylists.id.equalsExp(youtubeVideos.playlistLocalId),
          ),
        ])
          ..where(
            youtubeVideos.playlistLocalId.equals(playlistId) &
                youtubeVideos.deletedAt.isNull() &
                youtubePlaylists.localAccountId.equals(db.activeAccountId) &
                youtubePlaylists.deletedAt.isNull() &
                youtubeVideos.watchedAt.isBiggerOrEqualValue(start) &
                youtubeVideos.watchedAt.isSmallerThanValue(end),
          ))
        .get();
    for (final row in videos.map((row) => row.readTable(youtubeVideos))) {
      if (!row.completed) await setCompleted(row.id, true);
    }
    return videos.length;
  }

  Future<void> deletePlaylist(int playlistId) async {
    await transaction(() async {
      final owned =
          await (select(youtubePlaylists)..where(
                (p) =>
                    p.id.equals(playlistId) &
                    p.localAccountId.equals(db.activeAccountId) &
                    p.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (owned == null) return;
      final now = DateTime.now();
      final videos =
          await (select(youtubeVideos)..where(
                (video) =>
                    video.playlistLocalId.equals(playlistId) &
                    video.deletedAt.isNull(),
              ))
              .get();
      await (update(youtubeVideos)..where(
            (video) =>
                video.playlistLocalId.equals(playlistId) &
                video.deletedAt.isNull(),
          ))
          .write(
            YoutubeVideosCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      for (final video in videos) {
        await db.syncOutboxDao.enqueue(
          localAccountId: db.activeAccountId,
          entityType: OutboxEntity.video,
          localRowId: video.id,
          operation: OutboxOperation.delete,
          serverId: video.serverId,
          baseRemoteUpdatedAt: _remoteVersion(video),
          localMutationAt: now,
          dependencyRank: OutboxDependencyRank.video,
        );
      }
      await (update(youtubePlaylists)..where(
            (playlist) =>
                playlist.id.equals(playlistId) &
                playlist.localAccountId.equals(db.activeAccountId) &
                playlist.deletedAt.isNull(),
          ))
          .write(
            YoutubePlaylistsCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await db.syncOutboxDao.enqueue(
        localAccountId: db.activeAccountId,
        entityType: OutboxEntity.playlist,
        localRowId: playlistId,
        operation: OutboxOperation.delete,
        serverId: owned.serverId,
        baseRemoteUpdatedAt: owned.updatedAt,
        localMutationAt: now,
        dependencyRank: OutboxDependencyRank.playlist,
      );
    });
  }
}

DateTime? _remoteVersion(YoutubeVideo? video) =>
    video == null ? null : SyncTimestamp.parse(video.remoteUpdatedAt);
