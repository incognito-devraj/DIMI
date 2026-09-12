import '../models/youtube_playlist.dart';

// Compatibility export for old route imports. Production reads Drift.
const mockYouTubePlaylist = YouTubePlaylist(
  playlistId: 'legacy',
  title: 'Playlist',
  channelTitle: '',
  description: '',
  thumbnailUrl: '',
  totalVideos: 0,
  totalDurationSeconds: 0,
  videos: [],
);
