import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/youtube_playlists.dart';
import '../tables/youtube_videos.dart';

part 'youtube_playlist_dao.g.dart';

@DriftAccessor(tables: [YoutubePlaylists, YoutubeVideos])
class YoutubePlaylistDao extends DatabaseAccessor<AppDatabase>
    with _$YoutubePlaylistDaoMixin {
  YoutubePlaylistDao(super.db);

  Stream<List<YoutubePlaylist>> watchForUser(String userId) =>
      (select(youtubePlaylists)..where((p) => p.userId.equals(userId))
            ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])).watch();

  Stream<YoutubePlaylist?> watchById(int id) =>
      (select(youtubePlaylists)..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<YoutubePlaylist?> getByYoutubeId(String userId, String playlistId) =>
      (select(youtubePlaylists)..where((p) => p.userId.equals(userId) & p.youtubePlaylistId.equals(playlistId)))
          .getSingleOrNull();

  Stream<List<YoutubeVideo>> watchVideos(int playlistId) =>
      (select(youtubeVideos)..where((v) => v.playlistLocalId.equals(playlistId))
            ..orderBy([(v) => OrderingTerm.asc(v.position)])).watch();

  Future<List<YoutubeVideo>> getVideos(int playlistId) =>
      (select(youtubeVideos)..where((v) => v.playlistLocalId.equals(playlistId))
            ..orderBy([(v) => OrderingTerm.asc(v.position)])).get();

  Future<int> savePlaylist({required YoutubePlaylistsCompanion playlist,
      required List<YoutubeVideosCompanion> videos}) async {
    return transaction(() async {
      final existing = await (select(youtubePlaylists)
            ..where((p) => p.userId.equals(playlist.userId.value) &
                p.youtubePlaylistId.equals(playlist.youtubePlaylistId.value)))
          .getSingleOrNull();
      final localId = existing == null
          ? await into(youtubePlaylists).insert(playlist)
          : await (update(youtubePlaylists)..where((p) => p.id.equals(existing.id)))
              .write(playlist.copyWith(id: Value(existing.id)));
      await (delete(youtubeVideos)..where((v) => v.playlistLocalId.equals(localId))).go();
      for (final video in videos) {
        await into(youtubeVideos).insert(video.copyWith(playlistLocalId: Value(localId)));
      }
      return localId;
    });
  }

  Future<void> setCompleted(int videoId, bool value) =>
      (update(youtubeVideos)..where((v) => v.id.equals(videoId))).write(
        YoutubeVideosCompanion(
          completed: Value(value),
          watchedAt: Value(value ? DateTime.now() : null),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
