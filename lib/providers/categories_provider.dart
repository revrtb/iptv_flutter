import 'package:flutter/foundation.dart';

import '../models/live_category.dart';
import '../models/live_stream.dart';
import '../services/api_service.dart';
import '../services/playlist_cache.dart';

class CategoriesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final PlaylistCache<List<LiveCategory>> _categoriesCache = PlaylistCache<List<LiveCategory>>(
    ttl: const Duration(minutes: 10),
  );
  final KeyedPlaylistCache<List<LiveStream>> _catchUpCache = KeyedPlaylistCache<List<LiveStream>>(
    ttl: const Duration(minutes: 10),
  );

  List<LiveCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LiveCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int getCategoryCount(String categoryId) => 0;

  int getCatchUpCount(String categoryId) {
    final id = categoryId.trim();
    final list = _catchUpCache.get(id);
    return list?.length ?? 0;
  }

  List<LiveStream> getCatchUpStreamsForCategory(String categoryId) {
    final id = categoryId.trim();
    return _catchUpCache.get(id) ?? [];
  }

  /// Load only categories. Uses cache when fresh.
  Future<void> loadCategories({
    required String serverUrl,
    required String username,
    required String password,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && !_categoriesCache.isStale && _categoriesCache.data != null) {
      _categories = _categoriesCache.data!;
      _isLoading = false;
      notifyListeners();
      return;
    }
    if (forceRefresh) _categoriesCache.clear();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _api.getLiveCategories(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      _categoriesCache.set(_categories);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load catch-up streams for one category (on demand). Fills cache for getCatchUpCount/getCatchUpStreamsForCategory.
  Future<void> loadCatchUpForCategory({
    required String serverUrl,
    required String username,
    required String password,
    required String categoryId,
    bool forceRefresh = false,
  }) async {
    final id = categoryId.trim();
    if (!forceRefresh && _catchUpCache.isFresh(id)) {
      notifyListeners();
      return;
    }

    try {
      final all = await _api.getLiveStreams(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: id,
      );
      final catchUp = all.where((s) => s.hasCatchUp).toList();
      _catchUpCache.set(id, catchUp);
    } catch (_) {
      _catchUpCache.set(id, []);
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
