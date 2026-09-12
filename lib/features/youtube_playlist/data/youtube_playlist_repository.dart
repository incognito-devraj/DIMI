import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';
import '../models/youtube_playlist.dart';

class YouTubePlaylistException implements Exception {
  const YouTubePlaylistException(this.message);
  final String message;
  @override String toString() => message;
}

class YouTubePlaylistRepository {
  Future<YouTubePlaylist> fetchPlaylist(String playlistUrl) async {
    final uri = Uri.tryParse(playlistUrl.trim());
    final id = uri == null || !{'youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be'}.contains(uri.host.toLowerCase())
        ? null : uri.queryParameters['list'];
    if (id == null || id.isEmpty) throw const YouTubePlaylistException('invalid');
    final client = SupabaseBootstrap.client;
    if (client == null) throw const YouTubePlaylistException('network');
    try {
      final response = await client.functions.invoke('youtube-playlist', body: {'playlistUrl': playlistUrl.trim()});
      if (response.status != 200 || response.data is! Map) throw const YouTubePlaylistException('unavailable');
      return YouTubePlaylist.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on YouTubePlaylistException { rethrow; }
    on FunctionException catch (e) {
      throw YouTubePlaylistException(e.status == 404 ? 'unavailable' : 'network');
    } catch (_) { throw const YouTubePlaylistException('network'); }
  }
}
