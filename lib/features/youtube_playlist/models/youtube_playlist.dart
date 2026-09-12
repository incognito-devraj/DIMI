import 'youtube_video.dart';

class YouTubePlaylist {
  const YouTubePlaylist({
    required this.playlistId,
    required this.title,
    required this.channelTitle,
    required this.description,
    required this.thumbnailUrl,
    required this.totalVideos,
    required this.totalDurationSeconds,
    required this.videos,
  });

  final String playlistId;
  final String title;
  final String channelTitle;
  final String description;
  final String thumbnailUrl;
  final int totalVideos;
  final int totalDurationSeconds;
  final List<YouTubeVideo> videos;

  String get id => playlistId;
  String get channelName => channelTitle;
  String get thumbnailLabel => thumbnailUrl;
  Duration get totalDuration => Duration(seconds: totalDurationSeconds);

  int get watchedCount => videos.where((video) => video.isCompleted).length;
  int get remainingCount => videos.length - watchedCount;
  double get progress => totalVideos == 0 ? 0 : watchedCount / totalVideos;
  Duration get remainingDuration => videos
      .where((video) => !video.isCompleted)
      .fold(Duration.zero, (sum, video) => sum + video.duration);
  YouTubeVideo get currentVideo => videos.firstWhere(
    (video) => !video.isCompleted,
    orElse: () => videos.isEmpty ? const YouTubeVideo.empty() : videos.last,
  );

  factory YouTubePlaylist.fromJson(Map<String, dynamic> json) {
    final raw = json['playlist'];
    if (raw is! Map) throw const FormatException('Missing playlist data');
    final list = json['videos'];
    if (list is! List) throw const FormatException('Missing video data');
    return YouTubePlaylist(
      playlistId: _string(raw['playlistId']), title: _string(raw['title']),
      description: _string(raw['description']), channelTitle: _string(raw['channelTitle']),
      thumbnailUrl: _string(raw['thumbnail']), totalVideos: _int(raw['totalVideos']),
      totalDurationSeconds: _int(raw['totalDurationSeconds']),
      videos: list.whereType<Map>().map((v) => YouTubeVideo.fromJson(Map<String, dynamic>.from(v))).toList(),
    );
  }
}

String _string(Object? value) => value?.toString() ?? '';
int _int(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
