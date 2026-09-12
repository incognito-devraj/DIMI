import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override ConsumerState<AddYouTubePlaylistSheet> createState() => _AddYouTubePlaylistSheetState();
}

class _AddYouTubePlaylistSheetState extends ConsumerState<AddYouTubePlaylistSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  @override void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _add() async {
    setState(() { _loading = true; _error = null; });
    try {
      final playlist = await ref.read(youtubePlaylistRepositoryProvider).fetchPlaylist(_controller.text);
      if (playlist.videos.isEmpty) throw const YouTubePlaylistException('unavailable');
      final now = DateTime.now();
      final userId = AuthService.instance.currentUser?.id ?? 'local';
      final dao = ref.read(databaseProvider).youtubePlaylistDao;
      await dao.savePlaylist(playlist: playlistEntry(playlist, userId, now), videos: videoEntries(playlist, now));
      if (!mounted) return;
      context.pop();
      context.push(AppRoutes.playlistDetails, extra: playlist);
    } on YouTubePlaylistException catch (e) {
      if (mounted) setState(() { _loading = false; _error = switch (e.message) { 'invalid' => 'Please enter a valid YouTube playlist link.', 'unavailable' => "That playlist couldn't be loaded.", 'network' => "Couldn't connect. Check your internet connection and try again.", _ => 'Something went wrong. Please try again.' }; });
    } catch (_) { if (mounted) setState(() { _loading = false; _error = 'Something went wrong. Please try again.'; }); }
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 10, AppSpacing.screenHorizontal, MediaQuery.viewInsetsOf(context).bottom + 22),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(9))),
      Align(alignment: Alignment.centerRight, child: IconButton(onPressed: _loading ? null : () => context.pop(), icon: const Icon(Icons.close_rounded, color: AppColors.accent))),
      Container(width: 48, height: 36, decoration: BoxDecoration(color: const Color(0xFFFFE9E6), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF2727), size: 28)),
      const SizedBox(height: 12), Text('Add YouTube Playlist', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6), Text('Paste a YouTube playlist link to get started.\nTrack your learning progress with DIMI.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 22), TextField(controller: _controller, enabled: !_loading, keyboardType: TextInputType.url, decoration: const InputDecoration(prefixIcon: Icon(Icons.link_rounded, size: 20), hintText: 'https://www.youtube.com/playlist?list=...')),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
      const SizedBox(height: 14), PlaylistPrimaryButton(label: _loading ? 'Loading...' : 'Add Playlist', icon: _loading ? Icons.hourglass_top_rounded : Icons.add_rounded, onPressed: _loading ? () {} : _add),
      const SizedBox(height: 26), Align(alignment: Alignment.centerLeft, child: Text('Examples', style: Theme.of(context).textTheme.titleSmall)),
      const SizedBox(height: 8), ...['https://www.youtube.com/playlist?list=PL4c...', 'https://www.youtube.com/playlist?list=PL6n9...'].map((link) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(12)), child: Row(children: [Expanded(child: Text(link, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall)), const Icon(Icons.content_copy_rounded, size: 16, color: AppColors.accent)]))),
      const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.textSecondary), const SizedBox(width: 6), Text('Your data is private and stored securely.', style: Theme.of(context).textTheme.labelSmall)]),
    ])),
  ));
}
