class LiveStream {
  final String num;
  final String name;
  final String streamType;
  final String streamId;
  final String streamIcon;
  final String epgChannelId;
  final String added;
  final String categoryId;
  final String tvArchive;
  final String directSource;
  final String tvArchiveDuration;
  final List<String> _categoryIdsForCount;

  const LiveStream({
    required this.num,
    required this.name,
    required this.streamType,
    required this.streamId,
    required this.streamIcon,
    required this.epgChannelId,
    required this.added,
    required this.categoryId,
    required this.tvArchive,
    required this.directSource,
    required this.tvArchiveDuration,
    List<String>? categoryIdsForCount,
  }) : _categoryIdsForCount = categoryIdsForCount ?? const [];

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    final single = (json['category_id']?.toString() ?? '').trim();
    List<String> ids = [];
    if (json['category_ids'] is List) {
      ids = (json['category_ids'] as List)
          .map((e) => (e?.toString() ?? '').trim())
          .where((id) => id.isNotEmpty)
          .toList();
    }
    if (ids.isEmpty && single.isNotEmpty) ids = [single];
    return LiveStream(
      num: json['num']?.toString() ?? '0',
      name: json['name']?.toString() ?? 'Unknown',
      streamType: json['stream_type']?.toString() ?? 'live',
      streamId: json['stream_id']?.toString() ?? '',
      streamIcon: json['stream_icon']?.toString() ?? '',
      epgChannelId: json['epg_channel_id']?.toString() ?? '',
      added: json['added']?.toString() ?? '',
      categoryId: single,
      tvArchive: _parseTvArchive(json),
      directSource: json['direct_source']?.toString() ?? '',
      tvArchiveDuration: json['tv_archive_duration']?.toString() ?? '0',
      categoryIdsForCount: ids,
    );
  }

  List<String> get categoryIdsForCount =>
      _categoryIdsForCount.isNotEmpty ? _categoryIdsForCount : (categoryId.trim().isNotEmpty ? [categoryId.trim()] : []);

  static String _parseTvArchive(Map<String, dynamic> json) {
    final v = json['tv_archive'] ?? json['catchup'] ?? json['allow_catchup'] ?? json['tv_archive_enabled'];
    if (v == null) return '0';
    if (v is bool) return v ? '1' : '0';
    return v.toString().trim();
  }

  /// True if this stream supports catch-up (panels use tv_archive: 1, "1", "true", or tv_archive_duration > 0).
  bool get hasCatchUp {
    final v = tvArchive.toString().trim().toLowerCase();
    if (v == '1' || v == 'true' || v == 'yes') return true;
    if (tvArchiveDuration.isNotEmpty) {
      final d = int.tryParse(tvArchiveDuration);
      if (d != null && d > 0) return true;
    }
    return false;
  }

  static List<LiveStream> fromJsonList(List<dynamic>? list) {
    if (list == null) return [];
    return list
        .map((e) => LiveStream.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  String buildStreamUrl(String serverBaseUrl, String username, String password) {
    final base = serverBaseUrl.endsWith('/')
        ? serverBaseUrl.substring(0, serverBaseUrl.length - 1)
        : serverBaseUrl;
    return '$base/live/$username/$password/$streamId.m3u8';
  }
}
