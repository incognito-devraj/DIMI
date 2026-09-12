import 'package:drift/drift.dart';
import 'youtube_playlists.dart';

class YoutubeVideos extends Table {
  IntColumn get id => integer().autoIncrement()();
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

  @override
  List<Set<Column>> get uniqueKeys => [{playlistLocalId, youtubeVideoId}];
}
