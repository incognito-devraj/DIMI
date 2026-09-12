import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../services/auth_service.dart';
import 'data/youtube_playlist_repository.dart';

final youtubePlaylistRepositoryProvider = Provider((_) => YouTubePlaylistRepository());
final youtubePlaylistsProvider = StreamProvider((ref) {
  final userId = AuthService.instance.currentUser?.id ?? 'local';
  return ref.watch(databaseProvider).youtubePlaylistDao.watchForUser(userId);
});
final youtubePlaylistDaoProvider = Provider((ref) => ref.watch(databaseProvider).youtubePlaylistDao);
