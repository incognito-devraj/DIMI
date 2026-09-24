import 'package:drift/drift.dart';
import 'youtube_playlists.dart';

@TableIndex(name: 'idx_videos_playlist_completed', columns: {#playlistLocalId, #completed})
@TableIndex(name: 'idx_videos_playlist_position', columns: {#playlistLocalId, #position})
class YoutubeVideos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable().unique()();
  /// Exact Supabase version used by the sync worker's CAS updates. Drift's
  /// DateTime columns are stored at SQLite second precision.
  TextColumn get remoteUpdatedAt =>
      text().nullable().named('remote_updated_at')();
  IntColumn get playlistLocalId => integer().references(YoutubePlaylists, #id)();
  TextColumn get youtubeVideoId => text()();
  TextColumn get title => text()();
  TextColumn get thumbnailUrl => text().withDefault(const Constant(''))();
  IntColumn get position => integer()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get durationIso => text().withDefault(const Constant(''))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get watchedAt => dateTime().nullable()();
  IntColumn get lastPositionSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get progressUpdatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{playlistLocalId, youtubeVideoId}];

}
