class LiveCategory {
  final String categoryId;
  final String categoryName;

  const LiveCategory({
    required this.categoryId,
    required this.categoryName,
  });

  factory LiveCategory.fromJson(Map<String, dynamic> json) {
    // Some panels use "category_id", others "id" for the category id
    final id = json['category_id']?.toString() ?? json['id']?.toString() ?? '';
    final name = json['category_name']?.toString() ?? json['name']?.toString() ?? 'Unnamed';
    return LiveCategory(
      categoryId: id.trim(),
      categoryName: name,
    );
  }

  static List<LiveCategory> fromJsonList(List<dynamic>? list) {
    if (list == null) return [];
    return list
        .map((e) => LiveCategory.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
