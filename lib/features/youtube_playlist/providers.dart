import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../../providers/local_account_provider.dart';
import '../../services/auth_service.dart';
import '../../config/supabase_config.dart';
import 'data/youtube_playlist_repository.dart';

final youtubePlaylistRepositoryProvider = Provider(
  (_) => YouTubePlaylistRepository(),
);

/// Tracks the current user-ID reactively.
///
/// Re-emits whenever the Supabase auth state changes (login / logout /
/// token refresh). Offline users always get 'local'.
final _currentUserIdProvider = StreamProvider<String>((ref) async* {
  // Emit the current value immediately so there is no loading gap.
  yield AuthService.instance.currentUser?.id ?? 'local';

  // Then follow every subsequent auth-state change.
  await for (final event in SupabaseBootstrap.authChanges) {
    yield event.session?.user.id ?? 'local';
  }
});

/// Streams the saved playlists for whoever is currently signed in.
///
/// Automatically switches between the Google user-ID and 'local' as auth
/// state changes, so the correct list is always visible regardless of how
/// the user launched the app.
final youtubePlaylistsProvider = StreamProvider((ref) {
  ref.watch(activeAccountIdProvider);
  final userIdAsync = ref.watch(_currentUserIdProvider);
  final userId = userIdAsync.valueOrNull ?? 'local';
  return ref.watch(databaseProvider).youtubePlaylistDao.watchForUser(userId);
});

final youtubePlaylistDaoProvider = Provider(
  (ref) => ref.watch(databaseProvider).youtubePlaylistDao,
);
