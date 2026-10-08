import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/database.dart';
import '../../../providers/database_provider.dart';
import '../../../services/notification_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/dimi_activity_heatmap.dart';
import '../models/youtube_playlist.dart';
import '../models/youtube_video.dart';
import '../providers.dart';
import '../widgets/youtube_playlist_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class PlaylistDetailsScreen extends ConsumerWidget {
  const PlaylistDetailsScreen({
    super.key,
    required this.playlist,
    this.initialFilter = 0,
  });
  final YouTubePlaylist playlist;
  final int initialFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(_videosProvider(playlist));
    return videosAsync.when(
      data: (videos) => _PlaylistPage(
        playlist: playlist,
        videos: videos,
        initialFilter: initialFilter,
      ),
      loading: () => _PlaylistPage(
        playlist: playlist,
        videos: playlist.videos,
        initialFilter: initialFilter,
      ),
      error: (_, _) => _PlaylistPage(
        playlist: playlist,
        videos: playlist.videos,
        initialFilter: initialFilter,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider — streams live DB updates
// ─────────────────────────────────────────────────────────────────────────────

final _videosProvider =
    StreamProvider.family<List<YouTubeVideo>, YouTubePlaylist>((ref, playlist) {
      final dao = ref.watch(youtubePlaylistDaoProvider);
      return ref
          .watch(youtubePlaylistsProvider)
          .when(
            data: (rows) {
              final row = rows
                  .where((r) => r.youtubePlaylistId == playlist.playlistId)
                  .firstOrNull;
              if (row == null) return Stream.value(playlist.videos);
              return dao
                  .watchVideos(row.id)
                  .map((items) => items.map(_toVideo).toList());
            },
            loading: () => Stream.value(playlist.videos),
            error: (_, _) => Stream.value(playlist.videos),
          );
    });

YouTubeVideo _toVideo(YoutubeVideo v) => YouTubeVideo(
  localId: v.id,
  videoId: v.youtubeVideoId,
  title: v.title,
  thumbnailUrl: v.thumbnailUrl,
  position: v.position,
  durationISO: v.durationIso,
  durationSeconds: v.durationSeconds,
  isCompleted: v.completed,
  watchedAt: v.watchedAt,
);

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class _PlaylistPage extends ConsumerStatefulWidget {
  const _PlaylistPage({
    required this.playlist,
    required this.videos,
    required this.initialFilter,
  });
  final YouTubePlaylist playlist;
  final List<YouTubeVideo> videos;
  final int initialFilter;

  @override
  ConsumerState<_PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends ConsumerState<_PlaylistPage> {
  // 0 = All, 1 = Watched, 2 = Unwatched
  int _filter = 0;

  // Frozen list for Watched/Unwatched tabs — rebuilt only on tab switch.
  late List<YouTubeVideo> _frozenList;

  // Explicitly-overridden completion states for videos the user has ticked
  // in the current tab session. Maps localId → desired completed state.
  // This survives DB stream updates so the visual state stays stable until
  // the user switches tabs.
  final Map<int, bool> _overrides = {};

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _frozenList = _buildFrozenList(widget.videos, _filter);
  }

  @override
  void didUpdateWidget(_PlaylistPage old) {
    super.didUpdateWidget(old);
    // "All" tab always shows live data; no frozen list needed.
    if (_filter == 0) {
      _frozenList = widget.videos;
    }
    // For Watched/Unwatched: once the DB echoes back a change we already
    // applied locally, remove the override so we're back in sync.
    if (_overrides.isNotEmpty) {
      final liveMap = {for (final v in widget.videos) v.localId: v};
      _overrides.removeWhere((id, desired) {
        final live = liveMap[id];
        return live != null && live.isCompleted == desired;
      });
    }
  }

  List<YouTubeVideo> _buildFrozenList(List<YouTubeVideo> source, int filter) {
    if (filter == 0) return List.of(source);
    if (filter == 1) return source.where((v) => v.isCompleted).toList();
    return source.where((v) => !v.isCompleted).toList();
  }

  void _switchTab(int newFilter) {
    if (newFilter == _filter) return;
    setState(() {
      _filter = newFilter;
      _overrides.clear();
      _frozenList = _buildFrozenList(widget.videos, newFilter);
    });
  }

  // Effective completion state: prefer local override, fall back to DB value.
  bool _effectiveState(YouTubeVideo video) {
    final id = video.localId;
    if (id != null && _overrides.containsKey(id)) return _overrides[id]!;
    return video.isCompleted;
  }

  Future<void> _toggle(YouTubeVideo video) async {
    if (video.localId == null) return;
    final id = video.localId!;
    final current = _effectiveState(video);
    final desired = !current;
    final confirmed = await _showPlaylistConfirmationSheet(
      context,
      title: desired ? 'Mark as watched?' : 'Mark as unwatched?',
      message: desired
          ? 'Mark "${video.title}" as watched?'
          : 'Mark "${video.title}" as unwatched?',
      confirmLabel: desired ? 'Mark as watched' : 'Mark as unwatched',
      destructive: !desired,
    );
    if (confirmed != true || !mounted) return;
    debugPrint(
      '[DIMI youtube completion] UI playlist tap '
      'localId=$id videoId=${video.videoId} current=$current desired=$desired',
    );
    // Set override immediately so UI reacts before DB round-trip.
    setState(() => _overrides[id] = desired);
    await ref.read(youtubePlaylistDaoProvider).setCompleted(id, desired);
  }

  // ── Derived counts (always reflect live DB data + local overrides) ──────────

  // Merge live DB state with pending overrides for accurate counts.
  bool _effectiveCompleted(YouTubeVideo v) {
    final id = v.localId;
    if (id != null && _overrides.containsKey(id)) return _overrides[id]!;
    return v.isCompleted;
  }

  int get _watchedCount =>
      widget.videos.where((v) => _effectiveCompleted(v)).length;
  int get _unwatchedCount => widget.videos.length - _watchedCount;
  int get _totalCount => widget.videos.isEmpty
      ? widget.playlist.totalVideos
      : widget.videos.length;
  double get _ratio => _totalCount == 0 ? 0.0 : _watchedCount / _totalCount;

  // The visible list merges frozen snapshot with live DB data so tick state
  // is always current, but items don't disappear from the list.
  List<YouTubeVideo> get _visibleList {
    if (_filter == 0) return widget.videos;
    // Map live videos by localId for fast lookup
    final liveMap = {for (final v in widget.videos) v.localId: v};
    return _frozenList.map((frozen) {
      final live = liveMap[frozen.localId];
      return live ?? frozen;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleVideos = _visibleList;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => context.pop(),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: _onMenuSelected,
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: Text('Remove playlist'),
                    ),
                  ],
                ),
              ],
            ),

            // ── Content ──────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Large header
                  _Header(playlist: widget.playlist),
                  const SizedBox(height: 12),

                  // 2. Progress card (ring + stats, no linear bar)
                  _ProgressCard(
                    watched: _watchedCount,
                    total: _totalCount,
                    ratio: _ratio,
                    videos: widget.videos,
                  ),
                  const SizedBox(height: 12),

                  // 3. Heatmap (unchanged)
                  _PlaylistHeatmap(videos: widget.videos),
                  const SizedBox(height: 12),

                  // 4. Reminders (just under heatmap)
                  _PlaylistReminderSection(playlist: widget.playlist),
                  const SizedBox(height: 14),

                  // 5. Three compact capsule tabs: All / Watched / Unwatched
                  _TabCapsules(
                    allCount: _totalCount,
                    watchedCount: _watchedCount,
                    unwatchedCount: _unwatchedCount,
                    selected: _filter,
                    onSelect: _switchTab,
                  ),
                  const SizedBox(height: 6),

                  // 6. Video list with deferred filtering
                  if (visibleVideos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          _filter == 1
                              ? 'No videos watched yet'
                              : _filter == 2
                              ? 'All videos are watched!'
                              : 'No videos',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
                  else
                    ...List.generate(visibleVideos.length, (i) {
                      final video = visibleVideos[i];
                      final isLast = i == visibleVideos.length - 1;
                      return _VideoRow(
                        video: video,
                        effectiveCompleted: _effectiveState(video),
                        showDivider: !isLast,
                        onToggle: () => _toggle(video),
                      );
                    }),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _onMenuSelected(String value) {
    if (value == 'remove') _removePlaylist();
  }

  Future<void> _removePlaylist() async {
    final confirmed = await _showPlaylistConfirmationSheet(
      context,
      title: 'Remove playlist?',
      message:
          'Remove "${widget.playlist.title}" and all of its local progress?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    final row = ref
        .read(youtubePlaylistsProvider)
        .valueOrNull
        ?.where((r) => r.youtubePlaylistId == widget.playlist.playlistId)
        .firstOrNull;
    if (row != null) {
      await ref.read(youtubePlaylistDaoProvider).deletePlaylist(row.id);
    }
    if (mounted) context.pop();
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmt(Duration d) => d.inHours > 0
    ? '${d.inHours}h ${d.inMinutes.remainder(60)}m'
    : '${d.inMinutes}m';

// ─────────────────────────────────────────────────────────────────────────────
// 1. Header  — full-width thumbnail, title + meta below, description hidden
// ─────────────────────────────────────────────────────────────────────────────

Future<bool?> _showPlaylistConfirmationSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 220),
      reverseDuration: Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    builder: (sheetContext) => SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withAlpha(20),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _PlaylistSheetButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(sheetContext, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PlaylistSheetButton(
                    label: confirmLabel,
                    primary: true,
                    destructive: destructive,
                    onPressed: () => Navigator.pop(sheetContext, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PlaylistSheetButton extends StatelessWidget {
  const _PlaylistSheetButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool destructive;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: destructive
          ? AppColors.danger
          : primary
          ? AppColors.accent
          : AppColors.accentSoft,
      foregroundColor: destructive || primary
          ? AppColors.surface
          : AppColors.textPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}

class _Header extends StatefulWidget {
  const _Header({required this.playlist});
  final YouTubePlaylist playlist;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.playlist;
    final hasDesc = p.description.trim().isNotEmpty;
    final totalDur = Duration(seconds: p.totalDurationSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Full-width thumbnail ────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PlaylistThumbnail(label: p.thumbnailUrl, large: true),
          ),
        ),
        const SizedBox(height: 14),

        // ── Title ───────────────────────────────────────────────────────────
        Text(
          p.title,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800, height: 1.25),
        ),
        const SizedBox(height: 8),

        // ── Channel row ─────────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 18,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 11,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              p.channelTitle,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Meta row: video count · duration · YouTube ──────────────────────
        Row(
          children: [
            _MetaBadge(
              icon: Icons.video_library_outlined,
              label: '${p.totalVideos} Videos',
            ),
            if (totalDur.inSeconds > 0) ...[
              const SizedBox(width: 8),
              _MetaBadge(
                icon: Icons.access_time_rounded,
                label: _fmt(totalDur),
              ),
            ],
            const SizedBox(width: 8),
            _MetaBadge(
              icon: Icons.play_circle_outline_rounded,
              label: 'YouTube',
            ),
          ],
        ),

        // ── Description (hidden by default) ─────────────────────────────────
        if (hasDesc) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _descExpanded ? 'Hide description' : 'Show description',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _descExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
          if (_descExpanded) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                p.description,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(height: 1.5),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Small pill badge used in the meta row.
class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Progress Card — matches reference exactly:
//    [ring+%] [7/10 watched] [▶badge 1h33m watched] [⏳badge 3h31m left]
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.watched,
    required this.total,
    required this.ratio,
    required this.videos,
  });

  final int watched;
  final int total;
  final double ratio;
  final List<YouTubeVideo> videos;

  @override
  Widget build(BuildContext context) {
    final watchedSecs = videos
        .where((v) => v.isCompleted)
        .fold(0, (s, v) => s + v.durationSeconds);
    final leftSecs = videos
        .where((v) => !v.isCompleted)
        .fold(0, (s, v) => s + v.durationSeconds);

    final watchedStr = watchedSecs > 0
        ? _fmt(Duration(seconds: watchedSecs))
        : '0m';
    final leftStr = leftSecs > 0 ? _fmt(Duration(seconds: leftSecs)) : '—';
    final pct = (ratio * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Ring gauge
          _ProgressRing(ratio: ratio, pct: pct),

          // 2. Videos watched count
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$watched',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' / $total',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'watched',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // 3. Watched duration — icon in soft circle
          _DurationBadge(
            iconData: Icons.play_arrow_rounded,
            value: watchedStr,
            label: 'watched',
            bgColor: const Color(0xFFFFF0D6),
            iconColor: AppColors.accent,
          ),

          // 4. Left duration — icon in soft circle
          _DurationBadge(
            iconData: Icons.hourglass_bottom_rounded,
            value: leftStr,
            label: 'left',
            bgColor: const Color(0xFFFFF0D6),
            iconColor: const Color(0xFFE8A030),
          ),
        ],
      ),
    );
  }
}

/// A stat item with an icon inside a soft circular badge, bold value, small label.
class _DurationBadge extends StatelessWidget {
  const _DurationBadge({
    required this.iconData,
    required this.value,
    required this.label,
    required this.bgColor,
    required this.iconColor,
  });

  final IconData iconData;
  final String value;
  final String label;
  final Color bgColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Soft circle icon badge
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(iconData, size: 18, color: iconColor),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.ratio, required this.pct});
  final double ratio;
  final int pct;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _RingPainter(ratio: ratio),
        child: Center(
          child: Text(
            '$pct%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.ratio});
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.accentSoft
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    if (ratio > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * ratio,
        false,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.ratio != ratio;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Playlist Heatmap  — identical style to DimiActivityHeatmap
// ─────────────────────────────────────────────────────────────────────────────

class _PlaylistHeatmap extends StatefulWidget {
  const _PlaylistHeatmap({required this.videos});
  final List<YouTubeVideo> videos;

  static const _cellSize = 12.0;
  static const _gap = 3.0;
  static const _monthGap = 12.0;
  static const _labelWidth = 30.0;
  static const _monthCount = 12;

  @override
  State<_PlaylistHeatmap> createState() => _PlaylistHeatmapState();
}

class _PlaylistHeatmapState extends State<_PlaylistHeatmap> {
  static const _screenPadding = 12.0;
  static const _tooltipGap = 8.0;
  static const _estimatedTooltipHeight = 190.0;

  final Map<DateTime, LayerLink> _cellLinks = {};
  _PlaylistHeatSelection? _selection;
  _PlaylistHeatPlacement? _placement;
  OverlayEntry? _overlayEntry;

  LayerLink _linkFor(DateTime date) =>
      _cellLinks.putIfAbsent(date, LayerLink.new);

  void _selectCell(BuildContext cellContext, DateTime date) {
    final box = cellContext.findRenderObject()! as RenderBox;
    final cellTopLeft = box.localToGlobal(Offset.zero);
    final cellRect = cellTopLeft & box.size;
    final videos = widget.videos
        .where(
          (video) =>
              video.isCompleted &&
              video.watchedAt != null &&
              _sameDay(video.watchedAt!, date),
        )
        .toList();
    final screen = MediaQuery.sizeOf(context);
    final dateStyle = AppTextStyles.caption(context).copyWith(fontSize: 12);
    final mainStyle = AppTextStyles.cardTitle(context)
        .copyWith(fontSize: 14, fontWeight: FontWeight.w700);
    final dateWidth = _measureText(
      DateFormat('EEE, MMM d').format(date),
      dateStyle,
    );
    final mainWidth = _measureText(
      '${videos.length} ${videos.length == 1 ? 'video' : 'videos'} completed',
      mainStyle,
    );
    final width = math.min(
      math.max(dateWidth + 24, mainWidth + 24).clamp(260.0, 340.0),
      screen.width - _screenPadding * 2,
    );
    final centerX = cellRect.center.dx;
    final left = (centerX - width / 2).clamp(
      _screenPadding,
      screen.width - _screenPadding - width,
    );
    final aboveFits =
        cellRect.top - _tooltipGap - _estimatedTooltipHeight >= _screenPadding;
    final vertical = aboveFits
        ? _PlaylistHeatVertical.above
        : _PlaylistHeatVertical.below;

    setState(() {
      _selection = _PlaylistHeatSelection(date, videos);
      _placement = _PlaylistHeatPlacement(
        vertical: vertical,
        width: width,
        offsetX: left - (centerX - width / 2),
        arrowX: centerX - left,
        cellHeight: cellRect.height,
      );
    });
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  double _measureText(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  void _dismissPopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _selection = null;
        _placement = null;
      });
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  Widget _buildOverlay() {
    final selection = _selection;
    final placement = _placement;
    if (selection == null || placement == null) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.loose,
        children: [
          CompositedTransformFollower(
            link: _linkFor(selection.date),
            showWhenUnlinked: false,
            targetAnchor: placement.targetAnchor,
            followerAnchor: placement.followerAnchor,
            offset: placement.offset,
            child: TapRegion(
              onTapOutside: (_) => _dismissPopup(),
              child: _PlaylistHeatTooltip(
                selection: selection,
                placement: placement,
                onDismiss: _dismissPopup,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counts = <DateTime, int>{};
    for (final v in widget.videos) {
      if (v.isCompleted && v.watchedAt != null) {
        final d = _day(v.watchedAt!);
        counts[d] = (counts[d] ?? 0) + 1;
      }
    }

    final today = _day(DateTime.now());
    final firstMonth = DateTime(
      today.year,
      today.month - (_PlaylistHeatmap._monthCount - 1),
      1,
    );
    final months = List.generate(
      _PlaylistHeatmap._monthCount,
      (i) => DateTime(firstMonth.year, firstMonth.month + i, 1),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Completion heatmap',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                'Activity over the last year',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height:
                7 * _PlaylistHeatmap._cellSize + 6 * _PlaylistHeatmap._gap + 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: _PlaylistHeatmap._labelWidth,
                  child: Column(
                    children: [
                      SizedBox(height: _PlaylistHeatmap._cellSize + 4),
                      _DayLabel('Sun'),
                      _DayLabel('Mon'),
                      _DayLabel('Tue'),
                      _DayLabel('Wed'),
                      _DayLabel('Thu'),
                      _DayLabel('Fri'),
                      _DayLabel('Sat', last: true),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final month in months) ...[
                          _HeatMonthGroup(
                            month: month,
                            today: today,
                            counts: counts,
                            linkFor: _linkFor,
                            onTap: (cellContext, day) =>
                                _selectCell(cellContext, day),
                          ),
                          const SizedBox(width: _PlaylistHeatmap._monthGap),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Less', style: _heatLegendStyle),
              const SizedBox(width: 5),
              ...List.generate(
                heatmapColors.length,
                (level) => Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: heatmapColors[level],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const SizedBox(width: 10, height: 10),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Text('More', style: _heatLegendStyle),
            ],
          ),
        ],
      ),
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _PlaylistHeatSelection {
  const _PlaylistHeatSelection(this.date, this.videos);

  final DateTime date;
  final List<YouTubeVideo> videos;
}

enum _PlaylistHeatVertical { above, below }

class _PlaylistHeatPlacement {
  const _PlaylistHeatPlacement({
    required this.vertical,
    required this.width,
    required this.offsetX,
    required this.arrowX,
    required this.cellHeight,
  });

  final _PlaylistHeatVertical vertical;
  final double width;
  final double offsetX;
  final double arrowX;
  final double cellHeight;

  Alignment get targetAnchor => vertical == _PlaylistHeatVertical.below
      ? Alignment.bottomCenter
      : Alignment.topCenter;

  Alignment get followerAnchor => vertical == _PlaylistHeatVertical.below
      ? Alignment.topCenter
      : Alignment.bottomCenter;

  Offset get offset => Offset(
    offsetX,
    vertical == _PlaylistHeatVertical.above ? cellHeight / 2 : -cellHeight / 2,
  );
}

class _PlaylistHeatTooltip extends StatefulWidget {
  const _PlaylistHeatTooltip({
    required this.selection,
    required this.placement,
    required this.onDismiss,
  });

  final _PlaylistHeatSelection selection;
  final _PlaylistHeatPlacement placement;
  final VoidCallback onDismiss;

  @override
  State<_PlaylistHeatTooltip> createState() => _PlaylistHeatTooltipState();
}

class _PlaylistHeatTooltipState extends State<_PlaylistHeatTooltip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _PlaylistHeatTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection.date != widget.selection.date) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .96, end: 1),
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    builder: (context, scale, child) => Opacity(
      opacity: (scale - .96) / .04,
      child: Transform.scale(scale: scale, child: child),
    ),
    child: CustomPaint(
      painter: _PlaylistHeatTooltipPainter(
        vertical: widget.placement.vertical,
        arrowX: widget.placement.arrowX,
      ),
      child: Container(
        width: widget.placement.width,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: Text(
                    DateFormat('EEE, MMM d').format(widget.selection.date),
                    style: AppTextStyles.caption(context).copyWith(
                      fontSize: 12,
                      height: 16 / 12,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.selection.videos.length} ${widget.selection.videos.length == 1 ? 'video' : 'videos'} completed',
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.cardTitle(context).copyWith(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 148),
                  child: ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbColor: WidgetStatePropertyAll(
                        AppColors.textSecondary.withAlpha(210),
                      ),
                      trackColor: WidgetStatePropertyAll(
                        AppColors.divider.withAlpha(150),
                      ),
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(4),
                      child: ListView.separated(
                        controller: _scrollController,
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(right: 7),
                        itemCount: widget.selection.videos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final video = widget.selection.videos[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft.withAlpha(150),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    video.title,
                                    style: AppTextStyles.body(context).copyWith(
                                      fontSize: 11,
                                      height: 1.2,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: -6,
              right: -8,
              child: IconButton(
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.close_rounded, size: 16),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PlaylistHeatTooltipPainter extends CustomPainter {
  const _PlaylistHeatTooltipPainter({
    required this.vertical,
    required this.arrowX,
  });

  final _PlaylistHeatVertical vertical;
  final double arrowX;

  @override
  void paint(Canvas canvas, Size size) {
    const arrowWidth = 12.0;
    const arrowHeight = 7.0;
    final top = vertical == _PlaylistHeatVertical.below ? arrowHeight : 0.0;
    final bottom = vertical == _PlaylistHeatVertical.above
        ? size.height - arrowHeight
        : size.height;
    final rect = Rect.fromLTRB(0, top, size.width, bottom);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
    final clampedArrow = arrowX.clamp(14.0, size.width - 14.0).toDouble();
    if (vertical == _PlaylistHeatVertical.below) {
      path.moveTo(clampedArrow - arrowWidth / 2, arrowHeight);
      path.lineTo(clampedArrow, 0);
      path.lineTo(clampedArrow + arrowWidth / 2, arrowHeight);
    } else {
      path.moveTo(clampedArrow - arrowWidth / 2, size.height - arrowHeight);
      path.lineTo(clampedArrow, size.height);
      path.lineTo(clampedArrow + arrowWidth / 2, size.height - arrowHeight);
    }
    canvas.drawShadow(path, const Color(0x40000000), 8, false);
    canvas.drawPath(path, Paint()..color = AppColors.surface);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _PlaylistHeatTooltipPainter old) =>
      old.vertical != vertical || old.arrowX != arrowX;
}

class _HeatMonthGroup extends StatelessWidget {
  const _HeatMonthGroup({
    required this.month,
    required this.today,
    required this.counts,
    required this.linkFor,
    required this.onTap,
  });

  final DateTime month;
  final DateTime today;
  final Map<DateTime, int> counts;
  final LayerLink Function(DateTime) linkFor;
  final void Function(BuildContext, DateTime) onTap;

  @override
  Widget build(BuildContext context) {
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final groupStart = month.subtract(Duration(days: month.weekday % 7));
    final groupEnd = monthEnd.add(Duration(days: 6 - (monthEnd.weekday % 7)));
    final weekCount = (groupEnd.difference(groupStart).inDays ~/ 7) + 1;
    final groupWidth =
        weekCount * (_PlaylistHeatmap._cellSize + _PlaylistHeatmap._gap) -
        _PlaylistHeatmap._gap;

    return SizedBox(
      width: groupWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: groupWidth,
            height: 16,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                DateFormat('MMM').format(month),
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weekCount, (week) {
              final weekStart = groupStart.add(Duration(days: week * 7));
              return Padding(
                padding: EdgeInsets.only(
                  right: week == weekCount - 1 ? 0 : _PlaylistHeatmap._gap,
                ),
                child: Column(
                  children: List.generate(7, (row) {
                    final day = weekStart.add(Duration(days: row));
                    final inMonth =
                        day.month == month.month && day.year == month.year;
                    if (!inMonth) {
                      return SizedBox(
                        width: _PlaylistHeatmap._cellSize,
                        height:
                            _PlaylistHeatmap._cellSize +
                            (row == 6 ? 0 : _PlaylistHeatmap._gap),
                      );
                    }
                    final count =
                        counts[DateTime(day.year, day.month, day.day)] ?? 0;
                    final color = day.isAfter(today)
                        ? heatmapColors[0]
                        : heatmapColors[count.clamp(0, 5)];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: row == 6 ? 0 : _PlaylistHeatmap._gap,
                      ),
                      child: Builder(
                        builder: (cellContext) => CompositedTransformTarget(
                          link: linkFor(day),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: count > 0
                                ? () => onTap(cellContext, day)
                                : null,
                            child: Semantics(
                              label:
                                  '${DateFormat('MMMM d, yyyy').format(day)}: $count videos',
                              button: count > 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: SizedBox(
                                  width: _PlaylistHeatmap._cellSize,
                                  height: _PlaylistHeatmap._cellSize,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel(this.label, {this.last = false});
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _PlaylistHeatmap._cellSize + (last ? 0 : _PlaylistHeatmap._gap),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: _heatDayLabelStyle),
    ),
  );
}

const _heatDayLabelStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 8,
  color: AppColors.textSecondary,
);

const _heatLegendStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 9,
  color: AppColors.textSecondary,
);

// ─────────────────────────────────────────────────────────────────────────────
// 4. Reminders (just under heatmap)
// ─────────────────────────────────────────────────────────────────────────────

class _PlaylistReminderSection extends ConsumerStatefulWidget {
  const _PlaylistReminderSection({required this.playlist});
  final YouTubePlaylist playlist;

  @override
  ConsumerState<_PlaylistReminderSection> createState() =>
      _PlaylistReminderSectionState();
}

class _PlaylistReminderSectionState
    extends ConsumerState<_PlaylistReminderSection> {
  bool _watchEnabled = false;
  bool _tickEnabled = false;
  TimeOfDay _watchTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _tickTime = const TimeOfDay(hour: 22, minute: 30);

  int? _watchReminderId;
  int? _tickReminderId;

  String get _watchKey => '__pl_watch_${widget.playlist.playlistId}';
  String get _tickKey => '__pl_tick_${widget.playlist.playlistId}';

  String get _watchTitle => 'Watch: ${widget.playlist.title}';
  String get _tickTitle => 'Tick off: ${widget.playlist.title}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Load the reminder rows from Drift. SharedPreferences only stores the
  /// row IDs for backwards compatibility; the persisted time is always
  /// read from Reminder.dueAt.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final dao = ref.read(databaseProvider).reminderDao;

    Future<Reminder?> findReminder({
      required String title,
      required String key,
    }) async {
      final storedId = prefs.getInt(key);
      final byId = storedId == null ? null : await dao.getById(storedId);
      if (byId != null) return byId;

      final current = await dao.getByTitle(title);
      if (current != null) return current;

      // Migrate rows created by the older title-key implementation.
      final legacy = await dao.getByTitle(key);
      if (legacy == null) return null;
      await dao.updateReminder(
        RemindersCompanion(
          id: Value(legacy.id),
          title: Value(title),
          dueAt: Value(legacy.dueAt),
          isEnabled: Value(legacy.isEnabled),
        ),
      );
      return await dao.getById(legacy.id);
    }

    final watch = await findReminder(title: _watchTitle, key: _watchKey);
    final tick = await findReminder(title: _tickTitle, key: _tickKey);
    if (!mounted) return;

    if (watch != null) {
      await prefs.setInt(_watchKey, watch.id);
      _watchReminderId = watch.id;
      _watchEnabled = watch.isEnabled;
      _watchTime = TimeOfDay(
        hour: watch.dueAt.hour,
        minute: watch.dueAt.minute,
      );
    }
    if (tick != null) {
      await prefs.setInt(_tickKey, tick.id);
      _tickReminderId = tick.id;
      _tickEnabled = tick.isEnabled;
      _tickTime = TimeOfDay(hour: tick.dueAt.hour, minute: tick.dueAt.minute);
    }
    setState(() {});
  }

  Future<void> _save({
    required String key,
    required String title,
    required bool enabled,
    required TimeOfDay time,
    required int? existingId,
    required void Function(int) onSaved,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final dao = ref.read(databaseProvider).reminderDao;
    final now = DateTime.now();
    var due = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (due.isBefore(now)) due = due.add(const Duration(days: 1));

    int? reminderId = existingId;
    final previous = existingId == null ? null : await dao.getById(existingId);
    if (previous != null) {
      await NotificationService.instance.cancelReminder(
        previous.notificationId,
      );
    }

    if (existingId != null) {
      await dao.updateReminder(
        RemindersCompanion(
          id: Value(existingId),
          title: Value(title),
          dueAt: Value(due),
          isEnabled: Value(enabled),
        ),
      );
    } else {
      final id = await dao.insertReminder(
        RemindersCompanion(
          title: Value(title),
          dueAt: Value(due),
          isEnabled: Value(enabled),
        ),
      );
      reminderId = id;
      await prefs.setInt(key, id);
      onSaved(id);
    }

    final reminder = reminderId == null ? null : await dao.getById(reminderId);
    if (reminder == null) return;
    if (!enabled) {
      await NotificationService.instance.cancelReminder(
        reminder.notificationId,
      );
      return;
    }

    await NotificationService.instance.setDailyReminderTime(
      reminder.id,
      hour: reminder.dueAt.hour,
      minute: reminder.dueAt.minute,
    );
    await NotificationService.instance.scheduleReminder(reminder);
  }

  Future<void> _toggleWatch(bool v) async {
    if (v) {
      final picked = await showTimePicker(
        context: context,
        initialTime: _watchTime,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _watchTime = picked;
        _watchEnabled = true;
      });
      await _save(
        key: _watchKey,
        title: _watchTitle,
        enabled: true,
        time: picked,
        existingId: _watchReminderId,
        onSaved: (id) => setState(() => _watchReminderId = id),
      );
      return;
    }

    setState(() => _watchEnabled = false);
    await _save(
      key: _watchKey,
      title: _watchTitle,
      enabled: false,
      time: _watchTime,
      existingId: _watchReminderId,
      onSaved: (id) => setState(() => _watchReminderId = id),
    );
  }

  Future<void> _toggleTick(bool v) async {
    if (v) {
      final picked = await showTimePicker(
        context: context,
        initialTime: _tickTime,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _tickTime = picked;
        _tickEnabled = true;
      });
      await _save(
        key: _tickKey,
        title: _tickTitle,
        enabled: true,
        time: picked,
        existingId: _tickReminderId,
        onSaved: (id) => setState(() => _tickReminderId = id),
      );
      return;
    }

    setState(() => _tickEnabled = false);
    await _save(
      key: _tickKey,
      title: _tickTitle,
      enabled: false,
      time: _tickTime,
      existingId: _tickReminderId,
      onSaved: (id) => setState(() => _tickReminderId = id),
    );
  }

  Future<void> _pickTime({
    required TimeOfDay current,
    required String key,
    required String title,
    required void Function(TimeOfDay) onPick,
    required bool isEnabled,
    required int? existingId,
    required void Function(int) onSaved,
  }) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !mounted) return;
    onPick(picked);
    if (isEnabled) {
      await _save(
        key: key,
        title: title,
        enabled: true,
        time: picked,
        existingId: existingId,
        onSaved: onSaved,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 15,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              const Text(
                'Reminders',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Daily watch reminder
          _ReminderRow(
            icon: Icons.play_circle_outline_rounded,
            title: 'Daily watch reminder',
            subtitle: 'Remind me to watch this playlist',
            enabled: _watchEnabled,
            time: _watchTime,
            onToggle: _toggleWatch,
            onTimeTap: () => _pickTime(
              current: _watchTime,
              key: _watchKey,
              title: _watchTitle,
              onPick: (t) => setState(() => _watchTime = t),
              isEnabled: _watchEnabled,
              existingId: _watchReminderId,
              onSaved: (id) => setState(() => _watchReminderId = id),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),

          // End of Day reminder
          _ReminderRow(
            icon: Icons.check_circle_outline_rounded,
            title: 'End of Day Reminder',
            subtitle: 'Remind me to tick videos I\'ve watched',
            enabled: _tickEnabled,
            time: _tickTime,
            onToggle: _toggleTick,
            onTimeTap: () => _pickTime(
              current: _tickTime,
              key: _tickKey,
              title: _tickTitle,
              onPick: (t) => setState(() => _tickTime = t),
              isEnabled: _tickEnabled,
              existingId: _tickReminderId,
              onSaved: (id) => setState(() => _tickReminderId = id),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onTimeTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 1),
              Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        if (enabled) ...[
          GestureDetector(
            onTap: onTimeTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                time.format(context),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Switch.adaptive(
          value: enabled,
          onChanged: onToggle,
          activeColor: AppColors.accent,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Tab capsules — segmented pill bar matching DIMI's Overview/Transactions
//    style: cream track, active tab = black rounded pill, inactive = plain text
// ─────────────────────────────────────────────────────────────────────────────

class _TabCapsules extends StatelessWidget {
  const _TabCapsules({
    required this.allCount,
    required this.watchedCount,
    required this.unwatchedCount,
    required this.selected,
    required this.onSelect,
  });

  final int allCount;
  final int watchedCount;
  final int unwatchedCount;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          _SegTab(
            label: 'All',
            count: allCount,
            active: selected == 0,
            onTap: () => onSelect(0),
          ),
          _SegTab(
            label: 'Watched',
            count: watchedCount,
            active: selected == 1,
            onTap: () => onSelect(1),
          ),
          _SegTab(
            label: 'Unwatched',
            count: unwatchedCount,
            active: selected == 2,
            onTap: () => onSelect(2),
          ),
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  const _SegTab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(
            '$label $count',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Video Row
//    • Default background: white card feel
//    • Watched: warm amber tint, dimmed thumbnail, amber check overlay
//    • Tap anywhere: instant feedback via onTapDown — no perceptible lag
// ─────────────────────────────────────────────────────────────────────────────

class _VideoRow extends StatefulWidget {
  const _VideoRow({
    required this.video,
    required this.effectiveCompleted,
    required this.showDivider,
    required this.onToggle,
  });

  final YouTubeVideo video;
  final bool effectiveCompleted;
  final bool showDivider;
  final VoidCallback onToggle;

  @override
  State<_VideoRow> createState() => _VideoRowState();
}

class _VideoRowState extends State<_VideoRow> {
  // Press-highlight — flips true on tapDown, false on tapUp/cancel
  bool _pressing = false;

  static const _watchedBg = Color(0xFFFFF3E0); // amber tint when watched
  static const _defaultBg = Color(0xFFFFFFFF); // clean white when unwatched
  static const _pressedBg = Color(0xFFF5EFE4); // subtle press feedback

  Color get _bgColor {
    if (_pressing) return _pressedBg;
    return widget.effectiveCompleted ? _watchedBg : _defaultBg;
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.effectiveCompleted;
    final video = widget.video;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onToggle,
        onHighlightChanged: (pressed) => setState(() => _pressing = pressed),
        splashColor: AppColors.accentSoft.withAlpha(90),
        highlightColor: AppColors.accentSoft.withAlpha(45),
        child: Ink(
          decoration: BoxDecoration(color: _bgColor),
          // onTapDown fires before onTap — gives instant visual response
          /* onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) {
        setState(() => _pressing = false);
        widget.onToggle();
      },
      onTapCancel: () => setState(() => _pressing = false), */
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 6,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Position number
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${video.position}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 96,
                          height: 60,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Slightly dim when watched
                              ColorFiltered(
                                colorFilter: completed
                                    ? const ColorFilter.matrix([
                                        0.72,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0.72,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0.72,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        1,
                                        0,
                                      ])
                                    : const ColorFilter.matrix([
                                        1,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        1,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        1,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        1,
                                        0,
                                      ]),
                                child: PlaylistThumbnail(
                                  label: video.thumbnailUrl,
                                ),
                              ),

                              // Amber overlay + centred amber check
                              if (completed)
                                Container(
                                  color: AppColors.accent.withAlpha(38),
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(55),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                  ),
                                ),

                              // Duration badge
                              Positioned(
                                right: 3,
                                bottom: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    formatDuration(video.duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title + sub-line
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: completed
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            // Watched date when done, duration when not
                            if (completed && video.watchedAt != null)
                              Text(
                                DateFormat('MMM d, yyyy')
                                    .format(video.watchedAt!),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.accent.withAlpha(200),
                                      fontWeight: FontWeight.w600,
                                    ),
                              )
                            else
                              Text(
                                formatDuration(video.duration),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tick circle — purely visual, GestureDetector owns the tap
                      IgnorePointer(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: completed
                                ? AppColors.accent
                                : Colors.transparent,
                            border: Border.all(
                              color: completed
                                  ? AppColors.accent
                                  : const Color(0xFFCCCCCC),
                              width: 2,
                            ),
                          ),
                          child: completed
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.showDivider)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: completed
                        ? AppColors.accent.withAlpha(55)
                        : AppColors.divider,
                    indent: 32,
                    endIndent: 0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
