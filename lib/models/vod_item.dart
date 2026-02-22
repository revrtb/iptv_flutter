class VodItem {
  final String num;
  final String name;
  final String streamType;
  final String streamId;
  final String streamIcon;
  final String rating;
  final String rating5based;
  final String added;
  final String categoryId;
  final String containerExtension;
  final List<String> _categoryIdsForCount;

  const VodItem({
    required this.num,
    required this.name,
    required this.streamType,
    required this.streamId,
    required this.streamIcon,
    required this.rating,
    required this.rating5based,
    required this.added,
    required this.categoryId,
    required this.containerExtension,
    List<String>? categoryIdsForCount,
  }) : _categoryIdsForCount = categoryIdsForCount ?? const [];

  factory VodItem.fromJson(Map<String, dynamic> json) {
    // Some panels use "category_id", others "cat_id" or "category_ids" (array)
    final catId = _parseCategoryId(json);
    final ids = _parseCategoryIdsList(json);
    return VodItem(
      num: json['num']?.toString() ?? '0',
      name: json['name']?.toString() ?? 'Unknown',
      streamType: json['stream_type']?.toString() ?? 'movie',
      streamId: json['stream_id']?.toString() ?? '',
      streamIcon: json['stream_icon']?.toString() ?? '',
      rating: json['rating']?.toString() ?? '0',
      rating5based: json['rating_5based']?.toString() ?? '0',
      added: json['added']?.toString() ?? '',
      categoryId: catId,
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
      categoryIdsForCount: ids,
    );
  }

  static String _parseCategoryId(Map<String, dynamic> json) {
    final single = json['category_id']?.toString() ?? json['cat_id']?.toString() ?? '';
    if (single.trim().isNotEmpty) return single.trim();
    final ids = json['category_ids'];
    if (ids is List && ids.isNotEmpty) {
      final first = ids.first?.toString().trim() ?? '';
      if (first.isNotEmpty) return first;
    }
    return '';
  }

  static List<String> _parseCategoryIdsList(Map<String, dynamic> json) {
    final ids = json['category_ids'];
    if (ids is List) {
      final list = (ids as List)
          .map((e) => (e?.toString() ?? '').trim())
          .where((id) => id.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }
    final single = _parseCategoryId(json);
    return single.isEmpty ? [] : [single];
  }

  List<String> get categoryIdsForCount =>
      _categoryIdsForCount.isNotEmpty ? _categoryIdsForCount : (categoryId.trim().isNotEmpty ? [categoryId.trim()] : []);

  static List<VodItem> fromJsonList(List<dynamic>? list) {
    if (list == null) return [];
    return list
        .map((e) => VodItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  String buildStreamUrl(String serverBaseUrl, String username, String password) {
    final base = serverBaseUrl.endsWith('/')
        ? serverBaseUrl.substring(0, serverBaseUrl.length - 1)
        : serverBaseUrl;
    final ext = containerExtension.isEmpty ? 'mp4' : containerExtension;
    return '$base/movie/$username/$password/$streamId.$ext';
  }
}
