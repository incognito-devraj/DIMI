import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/section_card.dart';
import '../models/youtube_video.dart';
import '../widgets/youtube_playlist_widgets.dart';
import '../../../providers/database_provider.dart';

class VideoDetailsScreen extends ConsumerWidget {
  const VideoDetailsScreen({super.key, required this.video});
  final YouTubeVideo video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // Thumbnail with play button overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: PlaylistThumbnail(
                      label: video.thumbnailLabel,
                      large: true,
                    ),
                  ),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xD9FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 34,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                video.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 3),
              Text(
                video.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),

              // Meta row
              Row(
                children: [
                  Text(
                    'Video ${video.position}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '·',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatDuration(video.duration),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '·',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${formatDuration(video.remaining)} left',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              PlaylistPrimaryButton(
                label: video.isCompleted ? 'Completed' : 'Mark as Completed',
                icon: Icons.check_circle_rounded,
                onPressed: video.localId == null ? () {} : () async {
                  await ref.read(databaseProvider).youtubePlaylistDao.setCompleted(video.localId!, !video.isCompleted);
                },
              ),

              const SizedBox(height: 24),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SectionCard(
                color: const Color(0xFFFBFAF7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.notes_rounded,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Write your notes here...\n(Only for you)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _action(
                      context,
                      Icons.bookmark_border_rounded,
                      'Save for later',
                    ),
                    const Divider(),
                    _action(
                      context,
                      Icons.open_in_new_rounded,
                      'Open in YouTube',
                    ),
                    const Divider(),
                    _action(context, Icons.share_outlined, 'Share video'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Next video',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SectionCard(
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 46,
                      child: PlaylistThumbnail(label: 'Widgets'),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Understanding Widgets',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 19),
            const SizedBox(width: 14),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
