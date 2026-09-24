import 'package:drift/drift.dart';
import 'local_accounts.dart';

@TableIndex(name: 'idx_playlists_account_updated', columns: {#localAccountId, #updatedAt})
class YoutubePlaylists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable().unique()();
  IntColumn get localAccountId => integer().withDefault(const Constant(1)).references(LocalAccounts, #id)();
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
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{localAccountId, youtubePlaylistId}];

}
