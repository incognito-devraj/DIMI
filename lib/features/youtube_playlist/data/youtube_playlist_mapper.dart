import 'package:drift/drift.dart';
import '../../../data/database.dart';
import '../models/youtube_playlist.dart';

YoutubePlaylistsCompanion playlistEntry(YouTubePlaylist p, String userId, DateTime now, {int? id}) => YoutubePlaylistsCompanion(
  id: id == null ? const Value.absent() : Value(id), localAccountId: const Value(1), youtubePlaylistId: Value(p.playlistId), title: Value(p.title),
  description: Value(p.description), channelTitle: Value(p.channelTitle), thumbnailUrl: Value(p.thumbnailUrl), totalVideos: Value(p.totalVideos),
  totalDurationSeconds: Value(p.totalDurationSeconds), createdAt: Value(now), updatedAt: Value(now), lastSyncedAt: Value(now));

List<YoutubeVideosCompanion> videoEntries(YouTubePlaylist p, DateTime now) => p.videos.map((v) => YoutubeVideosCompanion(
  youtubeVideoId: Value(v.videoId), title: Value(v.title), thumbnailUrl: Value(v.thumbnailUrl), position: Value(v.position),
  durationSeconds: Value(v.durationSeconds), durationIso: Value(v.durationISO), createdAt: Value(now), updatedAt: Value(now))).toList();
