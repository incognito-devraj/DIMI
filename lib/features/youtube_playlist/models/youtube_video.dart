class YouTubeVideo {
  const YouTubeVideo({
    required this.videoId,
    required this.position,
    required this.title,
    required this.thumbnailUrl,
    required this.durationISO,
    required this.durationSeconds,
    this.isCompleted = false,
    this.localId,
  });
  const YouTubeVideo.empty() : videoId = '', position = 0, title = '', thumbnailUrl = '', durationISO = '', durationSeconds = 0, isCompleted = false, localId = null;

  final int? localId;
  final String videoId;
  final int position;
  final String title;
  final String thumbnailUrl;
  final String durationISO;
  final int durationSeconds;
  final bool isCompleted;
  String get id => videoId;
  String get subtitle => '';
  String get thumbnailLabel => thumbnailUrl;
  Duration get duration => Duration(seconds: durationSeconds);

  Duration get remaining => isCompleted ? Duration.zero : duration;
  double get completion => isCompleted ? 1 : 0;

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) => YouTubeVideo(
    videoId: json['videoId']?.toString() ?? '', title: json['title']?.toString() ?? '',
    thumbnailUrl: json['thumbnail']?.toString() ?? '', position: (json['position'] as num?)?.toInt() ?? 0,
    durationISO: json['durationISO']?.toString() ?? '', durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
  );
}
