import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/dimi_progress_bar.dart';
import '../models/youtube_video.dart';

// ── Thumbnail placeholder ─────────────────────────────────────────────────────

class PlaylistThumbnail extends StatelessWidget {
  const PlaylistThumbnail({super.key, required this.label, this.large = false});
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (label.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(large ? 16 : 10),
        child: Image.network(
          label,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stack) => _fallback(context),
        ),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(large ? 16 : 10),
        color: const Color(0xFF1E3F6A),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(large ? 16 : 10),
        child: Stack(
          children: [
            Positioned(
              left: large ? 24 : 8,
              top: large ? 18 : 8,
              child: Icon(
                Icons.flutter_dash,
                size: large ? 74 : 28,
                color: const Color(0xFF62C6F5),
              ),
            ),
            Positioned(
              right: large ? 18 : 6,
              bottom: large ? 16 : 5,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: large ? 12 : 5,
                  vertical: large ? 6 : 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  maxLines: large ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: large ? 15 : 7,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Primary action button ─────────────────────────────────────────────────────

class PlaylistPrimaryButton extends StatelessWidget {
  const PlaylistPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class PlaylistStat extends StatelessWidget {
  const PlaylistStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video list tile ───────────────────────────────────────────────────────────

class VideoListTile extends StatelessWidget {
  const VideoListTile({super.key, required this.video, required this.onTap});
  final YouTubeVideo video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '${video.position}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            SizedBox(
              width: 76,
              height: 48,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PlaylistThumbnail(label: video.thumbnailLabel),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 3,
                    child: Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        formatDuration(video.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    video.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              video.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 20,
              color: video.isCompleted
                  ? AppColors.accent
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact now-playing bar ───────────────────────────────────────────────────

class CompactNowPlaying extends StatelessWidget {
  const CompactNowPlaying({
    super.key,
    required this.video,
    required this.onTap,
  });
  final YouTubeVideo video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              height: 34,
              child: PlaylistThumbnail(label: video.thumbnailLabel),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Up next',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onTap,
              icon: const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.accent,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String formatDuration(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return value.inHours > 0
      ? '${value.inHours}:$minutes:$seconds'
      : '${value.inMinutes}:$seconds';
}

Widget progressLine(double value) => DimiProgressBar(value: value, height: 7);
