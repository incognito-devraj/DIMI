import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';
import '../../../theme/app_theme.dart';
import '../models/youtube_playlist.dart';
import '../models/youtube_video.dart';
import '../providers.dart';
import '../widgets/youtube_playlist_widgets.dart';

/// Screen 1 — Playlist Overview.
/// Shows thumbnail, title, channel, stats, progress and the Continue Watching
/// button. Navigates to PlaylistVideosScreen on Continue Watching.
class PlaylistDetailsScreen extends ConsumerWidget {
  const PlaylistDetailsScreen({super.key, required this.playlist});
  final YouTubePlaylist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch live video data from drift so progress is always current.
    final videosAsync = ref.watch(_videosProvider(playlist));

    return videosAsync.when(
      data: (videos) => _Body(playlist: playlist, videos: videos),
      loading: () => _Body(playlist: playlist, videos: playlist.videos),
      error: (_, __) => _Body(playlist: playlist, videos: playlist.videos),
    );
  }
}

// Live videos provider — scoped to the playlist's local DB id.
final _videosProvider =
    StreamProvider.family<List<YouTubeVideo>, YouTubePlaylist>((ref, playlist) {
      // playlist.playlistId is the YouTube id string; we need the local int id.
      // The home card builds a full model with localId on each video; if available
      // we use the first video's playlist reference. Fallback: return model videos.
      final dao = ref.watch(youtubePlaylistDaoProvider);
      // We watch playlists to find the local id.
      return ref
          .watch(youtubePlaylistsProvider)
          .when(
            data: (rows) {
              final row = rows
                  .where((r) => r.youtubePlaylistId == playlist.playlistId)
                  .firstOrNull;
              if (row == null) {
                return Stream.value(playlist.videos);
              }
              return dao
                  .watchVideos(row.id)
                  .map(
                    (dbVideos) => dbVideos
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
            },
            loading: () => Stream.value(playlist.videos),
            error: (_, __) => Stream.value(playlist.videos),
          );
    });

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.playlist, required this.videos});
  final YouTubePlaylist playlist;
  final List<YouTubeVideo> videos;

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final watched = videos.where((v) => v.isCompleted).length;
    final total = videos.isEmpty ? playlist.totalVideos : videos.length;
    final progress = total == 0 ? 0.0 : watched / total;
    final pct = (progress * 100).round();
    final totalDur = Duration(seconds: playlist.totalDurationSeconds);

    // First unwatched video for Continue Watching
    final nextVideo =
        videos.where((v) => !v.isCompleted).firstOrNull ??
        (videos.isEmpty ? null : videos.last);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.more_vert_rounded),
              ),
            ],
            pinned: false,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.screenHorizontal,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Thumbnail ─────────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: PlaylistThumbnail(
                        label: playlist.thumbnailUrl,
                        large: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Title + channel ───────────────────────────────────
                  Text(
                    playlist.title,
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        playlist.channelTitle,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Stats row ─────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        _Stat(
                          icon: Icons.play_arrow_rounded,
                          value: '$total',
                          label: 'Videos',
                        ),
                        _StatDivider(),
                        _Stat(
                          icon: Icons.access_time_rounded,
                          value: _fmt(totalDur),
                          label: 'Total length',
                        ),
                        _StatDivider(),
                        _Stat(
                          icon: Icons.smart_display_outlined,
                          value: 'YouTube',
                          label: 'Playlist',
                          iconColor: const Color(0xFFFF0000),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Progress section ──────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Progress',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '$watched of $total watched',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: AppColors.accentSoft,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$pct%',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Continue Watching button ───────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.playlistVideos,
                        extra: playlist,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: Text(
                        nextVideo == null || watched == 0
                            ? 'Start Watching'
                            : 'Continue Watching',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  if (nextVideo != null && watched > 0) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Video ${nextVideo.position} · ${nextVideo.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat widget ───────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: iconColor ?? AppColors.accent),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.divider);
  }
}
