import 'package:drift/drift.dart';

class YoutubePlaylists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get youtubePlaylistId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get channelTitle => text().withDefault(const Constant(''))();
  TextColumn get thumbnailUrl => text().withDefault(const Constant(''))();
  IntColumn get totalVideos => integer().withDefault(const Constant(0))();
  IntColumn get totalDurationSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{userId, youtubePlaylistId}];
}
