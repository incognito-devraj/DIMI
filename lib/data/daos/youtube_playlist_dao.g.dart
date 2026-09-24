// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_playlist_dao.dart';

// ignore_for_file: type=lint
mixin _$YoutubePlaylistDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalAccountsTable get localAccounts => attachedDatabase.localAccounts;
  $YoutubePlaylistsTable get youtubePlaylists =>
      attachedDatabase.youtubePlaylists;
  $YoutubeVideosTable get youtubeVideos => attachedDatabase.youtubeVideos;
  YoutubePlaylistDaoManager get managers => YoutubePlaylistDaoManager(this);
}

class YoutubePlaylistDaoManager {
  final _$YoutubePlaylistDaoMixin _db;
  YoutubePlaylistDaoManager(this._db);
  $$LocalAccountsTableTableManager get localAccounts =>
      $$LocalAccountsTableTableManager(_db.attachedDatabase, _db.localAccounts);
  $$YoutubePlaylistsTableTableManager get youtubePlaylists =>
      $$YoutubePlaylistsTableTableManager(
        _db.attachedDatabase,
        _db.youtubePlaylists,
      );
  $$YoutubeVideosTableTableManager get youtubeVideos =>
      $$YoutubeVideosTableTableManager(_db.attachedDatabase, _db.youtubeVideos);
}
