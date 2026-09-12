import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/section_card.dart';
import '../models/youtube_playlist.dart';
import '../widgets/youtube_playlist_widgets.dart';

class PlaylistDetailsScreen extends StatelessWidget {
  const PlaylistDetailsScreen({super.key, required this.playlist});
  final YouTubePlaylist playlist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            4,
            AppSpacing.screenHorizontal,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              SizedBox(
                height: 145,
                width: double.infinity,
                child: PlaylistThumbnail(
                  label: playlist.thumbnailLabel,
                  large: true,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                playlist.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                playlist.channelName,
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                children: ['Development', 'Flutter', 'Mobile App']
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        labelStyle: Theme.of(context).textTheme.labelSmall,
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: AppColors.divider),
                        backgroundColor: AppColors.surface,
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 10),
              Text(
                playlist.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),

              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${(playlist.progress * 100).round()}%',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              progressLine(playlist.progress),
              const SizedBox(height: 6),
              Text(
                '${playlist.watchedCount} of ${playlist.videos.length} videos watched',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  PlaylistStat(
                    icon: Icons.schedule_outlined,
                    value: _format(playlist.remainingDuration),
                    label: 'Left',
                  ),
                  const SizedBox(width: 8),
                  PlaylistStat(
                    icon: Icons.format_list_bulleted_rounded,
                    value: '${playlist.remainingCount}',
                    label: 'Videos left',
                  ),
                  const SizedBox(width: 8),
                  PlaylistStat(
                    icon: Icons.playlist_play_rounded,
                    value: '${playlist.videos.length}',
                    label: 'Total',
                  ),
                ],
              ),

              const SizedBox(height: 14),
              PlaylistPrimaryButton(
                label: 'Continue Watching',
                icon: Icons.play_arrow_rounded,
                onPressed: () => context.push(
                  AppRoutes.videoDetails,
                  extra: playlist.currentVideo,
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                height: 46,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.playlistVideos, extra: playlist),
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: const Text('Shuffle Playlist'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),

              const SizedBox(height: 22),
              Text(
                'About this Playlist',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 9),
              SectionCard(
                child: Column(
                  children: [
                    _info(context, 'Channel', playlist.channelName),
                    _info(context, 'Total Duration', _format(playlist.totalDuration)),
                    _info(context, 'Videos', '${playlist.totalVideos}', last: true),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.playlistVideos, extra: playlist),
                icon: const Icon(Icons.playlist_play_rounded),
                label: const Text('View all videos'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(
    BuildContext context,
    String label,
    String value, {
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  String _format(Duration value) {
    final h = value.inHours;
    final m = value.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}
