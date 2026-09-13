import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_router.dart';
import '../../../theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../providers/database_provider.dart';
import '../data/youtube_playlist_mapper.dart';
import '../data/youtube_playlist_repository.dart';
import '../providers.dart';
import '../widgets/youtube_playlist_widgets.dart';

class AddYouTubePlaylistSheet extends ConsumerStatefulWidget {
  const AddYouTubePlaylistSheet({super.key});
  @override
  ConsumerState<AddYouTubePlaylistSheet> createState() =>
      _AddYouTubePlaylistSheetState();
}

class _AddYouTubePlaylistSheetState
    extends ConsumerState<AddYouTubePlaylistSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _requestInFlight = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final playlist = await ref
          .read(youtubePlaylistRepositoryProvider)
          .fetchPlaylist(_controller.text);
      if (playlist.videos.isEmpty)
        throw const YouTubePlaylistException('empty');
      final now = DateTime.now();
      final userId = AuthService.instance.currentUser?.id ?? 'local';
      final dao = ref.read(databaseProvider).youtubePlaylistDao;
      await dao.savePlaylist(
        playlist: playlistEntry(playlist, userId, now),
        videos: videoEntries(playlist, now),
      );
      if (!mounted) return;
      context.pop();
      context.push(AppRoutes.playlistDetails, extra: playlist);
    } on YouTubePlaylistException catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = switch (e.message) {
            'invalid' => 'Please enter a valid YouTube playlist link.',
            'unavailable' => "That playlist couldn't be loaded.",
            'empty' => 'That playlist is empty.',
            'timeout' => 'The request took too long. Please try again.',
            'invalid_response' => 'The playlist service returned invalid data.',
            'no_supabase' => 'Adding new playlists requires a Google account.\nSign in with Google to use this feature.',
            'network' =>
              "Couldn't connect. Check your internet connection and try again.",
            _ => 'Something went wrong. Please try again.',
          };
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Something went wrong. Please try again.';
        });
    } finally {
      _requestInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          8,
          18,
          bottomInset + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _loading ? null : () => context.pop(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textPrimary,
                ),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ),
            Container(
              width: 92,
              height: 78,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EC),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 58,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add YouTube Playlist',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Paste a YouTube playlist link to get started.\n'
              'Track your learning progress with DIMI.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              enabled: !_loading,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                hintText: 'https://www.youtube.com/playlist?list=...',
                suffixIcon: IconButton(
                  tooltip: 'Paste',
                  onPressed: _loading
                      ? null
                      : () async {
                          final data = await Clipboard.getData(
                            Clipboard.kTextPlain,
                          );
                          if (data?.text != null) {
                            _controller.text = data!.text!;
                            _controller.selection = TextSelection.collapsed(
                              offset: _controller.text.length,
                            );
                          }
                        },
                  icon: const Icon(Icons.content_paste_rounded),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            const SizedBox(height: 14),
            PlaylistPrimaryButton(
              label: _loading ? 'Loading...' : 'Add Playlist',
              icon: _loading ? Icons.hourglass_top_rounded : Icons.add_rounded,
              onPressed: _loading ? () {} : _add,
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Your data is private and stored securely.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
