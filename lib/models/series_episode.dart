class SeriesEpisode {
  final String id;
  final String episodeNum;
  final String title;
  final String containerExtension;
  final String seasonNumber;

  const SeriesEpisode({
    required this.id,
    required this.episodeNum,
    required this.title,
    required this.containerExtension,
    required this.seasonNumber,
  });

  factory SeriesEpisode.fromJson(Map<String, dynamic> json, String seasonNumber) {
    return SeriesEpisode(
      id: json['id']?.toString() ?? '',
      episodeNum: json['episode_num']?.toString() ?? '0',
      title: json['title']?.toString() ?? 'Episode ${json['episode_num']}',
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
      seasonNumber: seasonNumber,
    );
  }

  String buildStreamUrl(String serverBaseUrl, String username, String password) {
    final base = serverBaseUrl.endsWith('/')
        ? serverBaseUrl.substring(0, serverBaseUrl.length - 1)
        : serverBaseUrl;
    final ext = containerExtension.isEmpty ? 'mp4' : containerExtension;
    return '$base/series/$username/$password/$id.$ext';
  }

  /// Alternative URL with .m3u8; some panels serve the same episode as HLS.
  String buildStreamUrlM3u8(String serverBaseUrl, String username, String password) {
    final base = serverBaseUrl.endsWith('/')
        ? serverBaseUrl.substring(0, serverBaseUrl.length - 1)
        : serverBaseUrl;
    return '$base/series/$username/$password/$id.m3u8';
  }
}
