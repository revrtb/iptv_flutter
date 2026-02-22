class SeriesItem {
  final String seriesId;
  final String name;
  final String cover;
  final String plot;
  final String cast;
  final String director;
  final String genre;
  final String releaseDate;
  final String rating;
  final String rating5based;
  final String categoryId;
  final String youtubeTrailer;
  final List<String> _categoryIdsForCount;

  const SeriesItem({
    required this.seriesId,
    required this.name,
    required this.cover,
    required this.plot,
    required this.cast,
    required this.director,
    required this.genre,
    required this.releaseDate,
    required this.rating,
    required this.rating5based,
    required this.categoryId,
    required this.youtubeTrailer,
    List<String>? categoryIdsForCount,
  }) : _categoryIdsForCount = categoryIdsForCount ?? const [];

  factory SeriesItem.fromJson(Map<String, dynamic> json) {
    // Some panels use "category_id", others "cat_id" or "category_ids" (array)
    final catId = _parseCategoryId(json);
    final ids = _parseCategoryIdsList(json);
    return SeriesItem(
      seriesId: json['series_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      cover: json['cover']?.toString() ?? '',
      plot: json['plot']?.toString() ?? '',
      cast: json['cast']?.toString() ?? '',
      director: json['director']?.toString() ?? '',
      genre: json['genre']?.toString() ?? '',
      releaseDate: json['releaseDate']?.toString() ?? '',
      rating: json['rating']?.toString() ?? '0',
      rating5based: json['rating_5based']?.toString() ?? '0',
      categoryId: catId,
      youtubeTrailer: json['youtube_trailer']?.toString() ?? '',
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

  static List<SeriesItem> fromJsonList(List<dynamic>? list) {
    if (list == null) return [];
    return list
        .map((e) => SeriesItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
