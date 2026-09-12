import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// DIMI YouTube Playlist learning card.
/// Replaces the dark stats card. Placeholder data; ready for real backend.
class YoutubePlaylistCard extends StatelessWidget {
  const YoutubePlaylistCard({super.key});

  static const _playlist = 'Flutter Development';
  static const _course = 'Complete Course 2024';
  static const _author = 'CodeWithHarry';
  static const _watched = 12;
  static const _total = 32;
  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final progress = _watched / _total;
    // Thumbnail width is a fraction of screen width — never overflows
    final screenW = MediaQuery.sizeOf(context).width;
    final thumbW = (screenW * 0.30).clamp(100.0, 130.0);

    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCF5EC),
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: const Color(0xFFEADFCE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F1C1C1E),
              blurRadius: 16,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── LEFT: all text content ──────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // YouTube badge row
                        Row(
                          children: [
                            _YtBadge(),
                            const SizedBox(width: 6),
                            const Text(
                              'YOUTUBE PLAYLIST',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Main title
                        const Text(
                          _playlist,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),

                        // Course · author
                        const Text(
                          '$_course  ·  $_author',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),

                        // Progress bar + percent (all on one line, % stays in left panel)
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE5D9C8),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFF5A623),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF5A623),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Watched label
                        const Text(
                          '$_watched of $_total videos watched',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Bottom stats — single row, compact
                        const _BottomStats(),
                      ],
                    ),
                  ),
                ),

                // ── RIGHT: thumbnail — fixed fraction of screen width ───
                SizedBox(
                  width: thumbW,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Warm gradient background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF0DBBF), Color(0xFFF8ECD7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                      // Left-edge blend into card colour
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xFFFCF5EC),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.30],
                            ),
                          ),
                        ),
                      ),

                      // Laptop placeholder
                      const Center(
                        child: Icon(
                          Icons.laptop_mac_rounded,
                          size: 36,
                          color: Color(0xFFD4A87A),
                        ),
                      ),

                      // Italic motivational text — top right
                      const Positioned(
                        top: 14,
                        right: 10,
                        child: Text(
                          'Better\nSkills\nBrighter\nYou',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontStyle: FontStyle.italic,
                            fontSize: 9,
                            color: Color(0xFFB8845A),
                            height: 1.5,
                          ),
                        ),
                      ),

                      // Chevron — overlaps italic text area
                      Positioned(
                        top: 10,
                        right: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(210),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                      // Play button — bottom right
                      Positioned(
                        bottom: 12,
                        right: 10,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(235),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 20,
                            color: Color(0xFFF5A623),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom stats row ──────────────────────────────────────────────────────────

class _BottomStats extends StatelessWidget {
  const _BottomStats();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _Stat(icon: Icons.access_time_rounded, value: '14h 20m', label: 'left'),
        _Gap(),
        _Stat(
          icon: Icons.play_circle_outline_rounded,
          value: '20',
          label: 'left',
        ),
        _Gap(),
        _Stat(
          icon: Icons.format_list_bulleted_rounded,
          value: '32',
          label: 'total',
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E6D6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: const Color(0xFFB8845A)),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                color: AppColors.textSecondary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 8),
        Container(width: 1, height: 18, color: const Color(0xFFDDD3C3)),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ── YouTube badge ─────────────────────────────────────────────────────────────

class _YtBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 13,
      decoration: BoxDecoration(
        color: const Color(0xFFFF0000),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Center(
        child: Icon(Icons.play_arrow_rounded, size: 10, color: Colors.white),
      ),
    );
  }
}
