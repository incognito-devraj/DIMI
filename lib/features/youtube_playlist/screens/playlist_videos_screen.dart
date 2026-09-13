import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../models/youtube_playlist.dart';
import '../models/youtube_video.dart';
import '../providers.dart';
import '../widgets/youtube_playlist_widgets.dart';

/// Screen 2 — All Videos.
/// Shows the full video list. Tapping a checkbox immediately marks the video
/// completed/incomplete in the local drift database and reflects live progress.
class PlaylistVideosScreen extends ConsumerWidget {
  const PlaylistVideosScreen({super.key, required this.playlist});
  final YouTubePlaylist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve local playlist id then watch live videos.
    final playlistsAsync = ref.watch(youtubePlaylistsProvider);
    final localId = playlistsAsync.valueOrNull
        ?.where((r) => r.youtubePlaylistId == playlist.playlistId)
        .firstOrNull
        ?.id;

    if (localId != null) {
      // ── Live DB stream ──────────────────────────────────────────────────
      final videosAsync = ref.watch(_liveVideosProvider(localId));
      return videosAsync.when(
        data: (videos) => _VideoListPage(
          playlist: playlist,
          videos: videos,
          localId: localId,
        ),
        loading: () => _VideoListPage(
          playlist: playlist,
          videos: playlist.videos,
          localId: null,
        ),
        error: (_, __) => _VideoListPage(
          playlist: playlist,
          videos: playlist.videos,
          localId: null,
        ),
      );
    }

    // ── Fallback — model data, no persistence ─────────────────────────────
    return _VideoListPage(
      playlist: playlist,
      videos: playlist.videos,
      localId: null,
    );
  }
}

final _liveVideosProvider = StreamProvider.family<List<YouTubeVideo>, int>((
  ref,
  localId,
) {
  return ref
      .watch(youtubePlaylistDaoProvider)
      .watchVideos(localId)
      .map(
        (rows) => rows
            .map(
              (v) => YouTubeVideo(
                localId: v.id,
                videoId: v.youtubeVideoId,
                title: v.title,
                thumbnailUrl: v.thumbnailUrl,
                position: v.position,
                durationISO: v.durationIso,
                durationSeconds: v.durationSeconds,
                isCompleted: v.completed,
              ),
            )
            .toList(),
      );
});

// ── Stateful video list page ──────────────────────────────────────────────────

class _VideoListPage extends ConsumerStatefulWidget {
  const _VideoListPage({
    required this.playlist,
    required this.videos,
    required this.localId,
  });
  final YouTubePlaylist playlist;
  final List<YouTubeVideo> videos;
  final int? localId;

  @override
  ConsumerState<_VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends ConsumerState<_VideoListPage> {
  // Optimistic local overrides so the UI responds instantly before DB confirms.
  final Map<int, bool> _optimistic = {};

  bool _isCompleted(YouTubeVideo v) {
    if (v.localId != null && _optimistic.containsKey(v.localId)) {
      return _optimistic[v.localId]!;
    }
    return v.isCompleted;
  }

  Future<void> _toggle(YouTubeVideo v) async {
    if (v.localId == null) return;
    final next = !_isCompleted(v);
    setState(() => _optimistic[v.localId!] = next);
    try {
      await ref.read(youtubePlaylistDaoProvider).setCompleted(v.localId!, next);
    } catch (_) {
      // Revert on failure
      if (mounted) setState(() => _optimistic[v.localId!] = !next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videos = widget.videos;
    final watched = videos.where((v) => _isCompleted(v)).length;
    final total = videos.length;
    final progress = total == 0 ? 0.0 : watched / total;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.playlist.title,
          style: Theme.of(context).textTheme.titleLarge,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progress header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              8,
              AppSpacing.screenHorizontal,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Progress',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '$watched of $total watched',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AppColors.accentSoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Video list ────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                4,
                AppSpacing.screenHorizontal,
                40,
              ),
              itemCount: videos.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final video = videos[index];
                final completed = _isCompleted(video);
                return _VideoRow(
                  video: video,
                  completed: completed,
                  onToggle: () => _toggle(video),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Video row ─────────────────────────────────────────────────────────────────

class _VideoRow extends StatelessWidget {
  const _VideoRow({
    required this.video,
    required this.completed,
    required this.onToggle,
  });
  final YouTubeVideo video;
  final bool completed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Position number
          SizedBox(
            width: 26,
            child: Text(
              '${video.position}',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),

          // Thumbnail with duration overlay
          SizedBox(
            width: 96,
            height: 60,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: PlaylistThumbnail(label: video.thumbnailUrl),
                  ),
                ),
                Positioned(
                  right: 5,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      formatDuration(video.duration),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: completed
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                decoration: completed ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: completed ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: completed ? AppColors.accent : AppColors.textSecondary,
                  width: 1.5,
                ),
              ),
              child: completed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.surface,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
