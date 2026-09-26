import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/database.dart' show YoutubePlaylist, YoutubeVideo;
import '../features/youtube_playlist/models/youtube_playlist.dart'
    as model
    show YouTubePlaylist;
import '../features/youtube_playlist/models/youtube_video.dart'
    as model
    show YouTubeVideo;
import '../features/youtube_playlist/providers.dart';
import '../features/youtube_playlist/screens/add_youtube_playlist_sheet.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// YouTube Playlist Card
// ─────────────────────────────────────────────────────────────────────────────

class YoutubePlaylistCard extends ConsumerStatefulWidget {
  const YoutubePlaylistCard({super.key});

  @override
  ConsumerState<YoutubePlaylistCard> createState() =>
      _YoutubePlaylistCardState();
}

class _YoutubePlaylistCardState
    extends ConsumerState<YoutubePlaylistCard> {
  final _pageController = PageController();

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showAddPlaylist() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => const AddYouTubePlaylistSheet(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build complete playlist model
  // ─────────────────────────────────────────────────────────────────────────

  Future<model.YouTubePlaylist> _buildModel(
    YoutubePlaylist row,
  ) async {
    final dao = ref.read(youtubePlaylistDaoProvider);

    final videos = await dao.getVideos(row.id);

    return model.YouTubePlaylist(
      localId: row.id,
      playlistId: row.youtubePlaylistId,
      title: row.title,
      channelTitle: row.channelTitle,
      description: row.description,
      thumbnailUrl: row.thumbnailUrl,
      totalVideos: row.totalVideos,
      totalDurationSeconds: row.totalDurationSeconds,
      videos: videos
          .map(
            (v) => model.YouTubeVideo(
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
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync =
        ref.watch(youtubePlaylistsProvider);

    return playlistsAsync.when(
      // ───────────────────────────────────────────────────────────────────────
      // Loading
      // ───────────────────────────────────────────────────────────────────────

      loading: () => const _CardShell(
        child: _LoadingState(),
      ),

      // ───────────────────────────────────────────────────────────────────────
      // Error
      // ───────────────────────────────────────────────────────────────────────

      error: (err, stack) => _CardShell(
        child: _EmptyState(
          onAddTap: _showAddPlaylist,
        ),
      ),

      // ───────────────────────────────────────────────────────────────────────
      // Data
      // ───────────────────────────────────────────────────────────────────────

      data: (rows) {
        if (rows.isEmpty) {
          return _CardShell(
            child: _EmptyState(
              onAddTap: _showAddPlaylist,
            ),
          );
        }

        // Keep current page valid if a playlist was deleted.
        if (_currentPage >= rows.length) {
          _currentPage = rows.length - 1;
        }

        return _CardShell(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

              // ─────────────────────────────────────────────────────────────
              // IMPORTANT:
              // Keep the playlist content inside a compact but safe viewport.
              //
              // Thumbnail + text + plus button are all INSIDE this PageView.
              // Therefore they scroll together.
              // ─────────────────────────────────────────────────────────────

              SizedBox(
                height: 154,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: rows.length,

                  // Prevent anything from escaping the card.
                  clipBehavior: Clip.hardEdge,

                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },

                  itemBuilder: (_, index) {
                    final row = rows[index];

                    return _PlaylistPageItem(
                      key: ValueKey(row.id),
                      row: row,
                      buildModel: _buildModel,
                      onAddTap: _showAddPlaylist,

                      onTap: () async {
                        final full =
                            await _buildModel(row);

                        if (context.mounted) {
                          context.push(
                            AppRoutes.playlistDetails,
                            extra: full,
                          );
                        }
                      },
                    );
                  },
                ),
              ),

              // ─────────────────────────────────────────────────────────────
              // Pagination dots
              // ─────────────────────────────────────────────────────────────

              if (rows.length > 1) ...[
                const SizedBox(height: 7),
                _DotIndicator(
                  count: rows.length,
                  current: _currentPage,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Card Shell
// ─────────────────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFCF5EC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEADFCE),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1C1C1E),
            blurRadius: 16,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — empty state only
// ─────────────────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.onAddTap,
  });

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Container(
          width: 28,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000),
            borderRadius:
                BorderRadius.circular(5),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),

        const SizedBox(width: 8),

        const Expanded(
          child: Text(
            'YOUTUBE PLAYLIST',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
        ),

      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onAddTap,
  });

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [

        _CardHeader(
          onAddTap: onAddTap,
        ),

        const SizedBox(height: 8),

        GestureDetector(
          onTap: onAddTap,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color:
                  AppColors.surface.withAlpha(180),
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.surface, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Add a playlist to start learning',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading State
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 132,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Playlist Page
//
// THIS is the important part.
//
// The thumbnail is a BACKGROUND of the page.
// It is NOT a separate thumbnail widget beside the card.
//
// PageView
//    ↓
// _PlaylistPageItem
//    ↓
// Stack
//    ├── thumbnail background
//    ├── cream fade
//    ├── playlist information
//    └── floating +
// ─────────────────────────────────────────────────────────────────────────────

class _PlaylistPageItem extends ConsumerStatefulWidget {
  const _PlaylistPageItem({
    super.key,
    required this.row,
    required this.buildModel,
    required this.onAddTap,
    required this.onTap,
  });

  final YoutubePlaylist row;

  final Future<model.YouTubePlaylist> Function(
    YoutubePlaylist,
  ) buildModel;

  final VoidCallback onAddTap;

  final VoidCallback onTap;

  @override
  ConsumerState<_PlaylistPageItem> createState() =>
      _PlaylistPageItemState();
}

class _PlaylistPageItemState
    extends ConsumerState<_PlaylistPageItem> {

  List<YoutubeVideo>? _videos;
  StreamSubscription<List<YoutubeVideo>>? _videoSubscription;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _videoSubscription = ref
        .read(youtubePlaylistDaoProvider)
        .watchVideos(widget.row.id)
        .listen((videos) {
          if (mounted) setState(() => _videos = videos);
        });
  }

  @override
  void dispose() {
    _videoSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(
    _PlaylistPageItem oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.row.id != widget.row.id ||
        oldWidget.row.updatedAt !=
            widget.row.updatedAt) {
      _loadVideos();
      _videoSubscription?.cancel();
      _videoSubscription = ref
          .read(youtubePlaylistDaoProvider)
          .watchVideos(widget.row.id)
          .listen((videos) {
            if (mounted) setState(() => _videos = videos);
          });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load videos
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadVideos() async {
    final full =
        await widget.buildModel(widget.row);

    if (!mounted) return;

    setState(() {
      _videos = full.videos
          .map(
            (v) => YoutubeVideo(
              id: v.localId ?? 0,
              playlistLocalId: widget.row.id,
              youtubeVideoId: v.videoId,
              title: v.title,
              thumbnailUrl: v.thumbnailUrl,
              position: v.position,
              durationSeconds:
                  v.durationSeconds,
              durationIso: v.durationISO,
              completed: v.isCompleted,
              watchedAt: null,
              lastPositionSeconds: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .toList();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Format duration
  // ─────────────────────────────────────────────────────────────────────────

  static String _fmtDuration(
    Duration d,
  ) {
    if (d.inSeconds == 0) {
      return '';
    }

    final h = d.inHours;
    final m = d.inMinutes.remainder(60);

    if (h > 0) {
      return '${h}h ${m}m';
    }

    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;

    final videos = _videos;

    // ─────────────────────────────────────────────────────────────────────────
    // Progress calculations
    // ─────────────────────────────────────────────────────────────────────────

    final totalVideos = row.totalVideos;

    final watched =
        videos?.where(
              (v) => v.completed,
            ).length ??
            0;

    final progress =
        totalVideos > 0
            ? watched / totalVideos
            : 0.0;

    final pct =
        (progress * 100).round();

    final left =
        totalVideos - watched;

    final remainingSecs = videos != null
        ? videos
            .where(
              (v) => !v.completed,
            )
            .fold(
              0,
              (sum, v) =>
                  sum + v.durationSeconds,
            )
        : row.totalDurationSeconds;

    final remainingStr =
        _fmtDuration(
      Duration(
        seconds: remainingSecs,
      ),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // WHOLE PAGE
    // ─────────────────────────────────────────────────────────────────────────

    return GestureDetector(
      onTap: widget.onTap,

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(14),

        child: Stack(
          fit: StackFit.expand,

          children: [

            // ═════════════════════════════════════════════════════════════════
            // 1. THUMBNAIL — FULL CARD BACKGROUND
            //
            // This fills the entire playlist page.
            //
            // There is NO separate right-side thumbnail box.
            // ═════════════════════════════════════════════════════════════════

            if (row.thumbnailUrl.startsWith('http'))
              Positioned.fill(
                child: Image.network(
                  row.thumbnailUrl,

                  // Cover the complete page.
                  //
                  // Because the original YouTube thumbnail is 16:9 and
                  // this card is much wider, some vertical cropping occurs,
                  // but the complete horizontal artwork is retained.
                  fit: BoxFit.cover,

                  // Keep the important artwork toward the right.
                  alignment:
                      Alignment.centerRight,

                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const SizedBox.shrink();
                  },
                ),
              ),

            // ═════════════════════════════════════════════════════════════════
            // 2. CREAM FADE
            //
            // The left side becomes completely cream.
            // The right side reveals the thumbnail.
            //
            // This is what removes the visible rectangular image boundary.
            // ═════════════════════════════════════════════════════════════════

            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:
                          Alignment.centerLeft,
                      end:
                          Alignment.centerRight,

                      stops: [
                        0.00,
                        0.30,
                        0.44,
                        0.57,
                        0.70,
                        0.84,
                        1.00,
                      ],

                      colors: [
                        Color(0xFFFCF5EC),
                        Color(0xFFFCF5EC),
                        Color(0xFFFCF5EC),
                        Color(0xF2FCF5EC),
                        Color(0xD5FCF5EC),
                        Color(0x70FCF5EC),
                        Color(0x00FCF5EC),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ═════════════════════════════════════════════════════════════════
            // 3. PLAYLIST CONTENT
            // ═════════════════════════════════════════════════════════════════

            Padding(
              padding:
                  const EdgeInsets.all(14),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                mainAxisSize:
                    MainAxisSize.min,

                children: [

                  // ───────────────────────────────────────────────────────────
                  // YouTube logo + playlist title
                  // ───────────────────────────────────────────────────────────

                  Row(
                    children: [

                      Container(
                        width: 28,
                        height: 20,

                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFFF0000,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(5),
                        ),

                        child: const Icon(
                          Icons
                              .play_arrow_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            right: 48,
                          ),

                          child: Text(
                            row.title,

                            maxLines: 1,

                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style:
                                const TextStyle(
                              fontFamily:
                                  'Inter',
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  AppColors
                                      .textPrimary,
                              height: 1.18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // ───────────────────────────────────────────────────────────
                  // Channel
                  // ───────────────────────────────────────────────────────────

                  Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      right: 48,
                    ),

                    child: Text(
                      row.channelTitle,

                      maxLines: 1,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          const TextStyle(
                        fontFamily:
                            'Inter',
                        fontSize: 11,
                        color:
                            AppColors
                                .textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ───────────────────────────────────────────────────────────
                  // Progress bar + percentage
                  // ───────────────────────────────────────────────────────────

                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          SizedBox(
                            width: constraints.maxWidth * 0.48,
                            child: ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(6),

                          child:
                              LinearProgressIndicator(
                            value:
                                progress,

                            minHeight: 8,

                            backgroundColor:
                                AppColors
                                    .accentSoft,

                            valueColor:
                                const AlwaysStoppedAnimation<
                                    Color>(
                              AppColors
                                  .accent,
                            ),
                            ),
                          ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            '$pct%',

                        style:
                            const TextStyle(
                          fontFamily:
                              'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 5),

                  // ───────────────────────────────────────────────────────────
                  // Watched
                  // ───────────────────────────────────────────────────────────

                  Text(
                    '$watched of $totalVideos videos watched',

                    maxLines: 1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                    fontFamily:
                        'Inter',
                      fontSize: 10,
                      color:
                          AppColors
                              .textSecondary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // ───────────────────────────────────────────────────────────
                  // Remaining
                  // ───────────────────────────────────────────────────────────

                  Text(
                    '$left ${left == 1 ? 'video' : 'videos'} left'
                    '${remainingStr.isNotEmpty ? ' · $remainingStr remaining' : ''}',

                    maxLines: 1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                    fontFamily:
                        'Inter',
                      fontSize: 10,
                      color:
                          AppColors
                              .textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ═════════════════════════════════════════════════════════════════
            // 4. FLOATING PLUS BUTTON
            //
            // It is positioned independently so it never changes the
            // title's layout.
            // ═════════════════════════════════════════════════════════════════

            Positioned(
              top: 8,
              right: 8,

              child: GestureDetector(
                onTap:
                    widget.onAddTap,

                child: Container(
                  width: 34,
                  height: 34,

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.textPrimary,

                    shape:
                        BoxShape.circle,

                  ),

                  child: const Icon(
                    Icons.add_rounded,
                    color:
                        Colors.white,
                    size: 22,
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

// ─────────────────────────────────────────────────────────────────────────────
// Thumbnail fallback widget
// ─────────────────────────────────────────────────────────────────────────────

class _ThumbnailImage extends StatelessWidget {
  const _ThumbnailImage({
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        alignment: Alignment.centerRight,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _placeholder();
        },
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF1E3F6A),

      child: const Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          color: Colors.white54,
          size: 28,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination dots
// ─────────────────────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({
    required this.count,
    required this.current,
  });

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,

      children: List.generate(
        count,
        (i) {
          final active =
              i == current;

          return AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 200,
            ),

            curve:
                Curves.easeInOut,

            margin:
                const EdgeInsets
                    .symmetric(
              horizontal: 3,
            ),

            width:
                active ? 18 : 6,

            height: 6,

            decoration:
                BoxDecoration(
              color: active
                  ? AppColors.accent
                  : AppColors
                      .accentSoft,

              borderRadius:
                  BorderRadius
                      .circular(3),
            ),
          );
        },
      ),
    );
  }
}
