import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/youtube_playlist/providers.dart';
import '../features/youtube_playlist/screens/add_youtube_playlist_sheet.dart';
import '../features/youtube_playlist/widgets/youtube_playlist_widgets.dart';
import '../features/youtube_playlist/models/youtube_playlist.dart';
import '../features/youtube_playlist/models/youtube_video.dart';
import '../theme/app_theme.dart';
import '../routing/app_router.dart';
import 'package:go_router/go_router.dart';

class YoutubePlaylistCard extends ConsumerWidget {
  const YoutubePlaylistCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(youtubePlaylistsProvider).valueOrNull ?? const [];
    final p = playlists.isEmpty ? null : playlists.first;
    return GestureDetector(
      onTap: () => p == null ? showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: AppColors.background, builder: (_) => const AddYouTubePlaylistSheet()) : null,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFFCF5EC), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFEADFCE)), boxShadow: const [BoxShadow(color: Color(0x0F1C1C1E), blurRadius: 16, offset: Offset(0, 3))]),
        padding: const EdgeInsets.all(16),
        child: p == null ? _empty(context) : StreamBuilder(
          stream: ref.read(youtubePlaylistDaoProvider).watchVideos(p.id),
          builder: (context, snapshot) {
            final videos = snapshot.data ?? const [];
            final watched = videos.where((v) => v.completed == true).length;
            final remaining = videos.where((v) => v.completed != true).fold<int>(0, (s, v) => s + v.durationSeconds);
            final pct = p.totalVideos == 0 ? 0.0 : watched / p.totalVideos;
            final model = YouTubePlaylist(playlistId: p.youtubePlaylistId, title: p.title, channelTitle: p.channelTitle, description: p.description, thumbnailUrl: p.thumbnailUrl, totalVideos: p.totalVideos, totalDurationSeconds: p.totalDurationSeconds, videos: videos.map<YouTubeVideo>((v) => YouTubeVideo(localId: v.id, videoId: v.youtubeVideoId, title: v.title, thumbnailUrl: v.thumbnailUrl, position: v.position, durationISO: v.durationIso, durationSeconds: v.durationSeconds, isCompleted: v.completed)).toList());
            return GestureDetector(onTap: () => context.push(AppRoutes.playlistDetails, extra: model), child: _content(context, p, watched, remaining, pct));
          },
        ),
      ),
    );
  }
  Widget _empty(BuildContext c) => Row(children: [const Icon(Icons.play_circle_outline_rounded, color: Color(0xFFFF2727), size: 34), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('YOUTUBE PLAYLIST', style: Theme.of(c).textTheme.labelSmall), Text('Add a playlist to start learning', style: Theme.of(c).textTheme.titleMedium)])), const Icon(Icons.add_circle_outline_rounded)]);
  Widget _content(BuildContext c, dynamic p, int watched, int remaining, double progress) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 105, height: 125, child: PlaylistThumbnail(label: p.thumbnailUrl)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('YOUTUBE PLAYLIST', style: Theme.of(c).textTheme.labelSmall), const SizedBox(height: 7), Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.titleLarge), Text(p.channelTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.bodySmall), const SizedBox(height: 12), progressLine(progress), const SizedBox(height: 5), Text('$watched of ${p.totalVideos} videos watched', style: Theme.of(c).textTheme.labelSmall), Text('${p.totalVideos - watched} videos left · ${_duration(remaining)} remaining', style: Theme.of(c).textTheme.labelSmall)]))]);
  String _duration(int seconds) { final h = seconds ~/ 3600; final m = (seconds % 3600) ~/ 60; return h > 0 ? '${h}h ${m}m' : '${m}m'; }
}
