import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';
import '../../../theme/app_theme.dart';
import '../widgets/youtube_playlist_widgets.dart';
import '../models/youtube_playlist.dart';

class PlaylistVideosScreen extends StatefulWidget {
  const PlaylistVideosScreen({super.key, required this.playlist});
  final YouTubePlaylist playlist;
  @override
  State<PlaylistVideosScreen> createState() => _PlaylistVideosScreenState();
}

class _PlaylistVideosScreenState extends State<PlaylistVideosScreen> {
  var _filter = 0;
  @override
  Widget build(BuildContext context) {
    final videos = widget.playlist.videos
        .where(
          (video) =>
              _filter == 0 ||
              (_filter == 1 ? !video.isCompleted : video.isCompleted),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text('Videos (${widget.playlist.videos.length})'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              6,
              AppSpacing.screenHorizontal,
              8,
            ),
            child: Row(
              children: List.generate(3, (index) {
                final labels = [
                  'All (${widget.playlist.videos.length})',
                  'Unwatched (${widget.playlist.remainingCount})',
                  'Watched (${widget.playlist.watchedCount})',
                ];
                final selected = _filter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(labels[index]),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = index),
                    selectedColor: AppColors.accentSoft,
                    side: BorderSide(
                      color: selected ? AppColors.accent : AppColors.divider,
                    ),
                    labelStyle: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                4,
                AppSpacing.screenHorizontal,
                90,
              ),
              itemCount: videos.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, index) => VideoListTile(
                video: videos[index],
                onTap: () =>
                    context.push(AppRoutes.videoDetails, extra: videos[index]),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CompactNowPlaying(
        video: widget.playlist.currentVideo,
        onTap: () => context.push(
          AppRoutes.videoDetails,
          extra: widget.playlist.currentVideo,
        ),
      ),
    );
  }
}
