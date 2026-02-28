import 'package:flutter/foundation.dart';

import '../models/live_category.dart';
import '../models/series_item.dart';
import '../services/api_service.dart';
import '../services/playlist_cache.dart';

class SeriesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final PlaylistCache<List<LiveCategory>> _categoriesCache = PlaylistCache<List<LiveCategory>>(
    ttl: const Duration(minutes: 10),
  );
  final KeyedPlaylistCache<List<SeriesItem>> _seriesCache = KeyedPlaylistCache<List<SeriesItem>>(
    ttl: const Duration(minutes: 10),
  );

  static const String _allKey = '__all__';

  List<LiveCategory> _categories = [];
  List<SeriesItem> _series = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentCategoryId;

  List<LiveCategory> get categories => _categories;
  List<SeriesItem> get series => _series;
  bool get isLoading => _isLoading;
  bool get countsLoading => false;
  String? get errorMessage => _errorMessage;
  String? get currentCategoryId => _currentCategoryId;

  int getCategoryCount(String categoryId) {
    final id = categoryId.trim();
    final list = _seriesCache.get(id);
    return list?.length ?? 0;
  }

  static String _cacheKey(String? categoryId) =>
      (categoryId == null || categoryId.trim().isEmpty) ? _allKey : categoryId.trim();

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
      _categories = await _api.getSeriesCategories(
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

  /// Load series for the current page (one category or all). Uses cache when fresh.
  Future<void> loadSeries({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(categoryId);
    if (!forceRefresh && _seriesCache.isFresh(key)) {
      final cached = _seriesCache.get(key);
      if (cached != null) {
        _series = cached;
        _currentCategoryId = categoryId;
        _errorMessage = null;
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    _currentCategoryId = categoryId;
    notifyListeners();

    try {
      _series = await _api.getSeries(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: (categoryId == null || categoryId.trim().isEmpty) ? null : categoryId,
      );
      _seriesCache.set(key, _series);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _series = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load full list only when needed (e.g. Check Availability). Uses cache when fresh.
  Future<void> ensureAllSeriesLoaded({
    required String serverUrl,
    required String username,
    required String password,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _seriesCache.isFresh(_allKey)) {
      final cached = _seriesCache.get(_allKey);
      if (cached != null) {
        notifyListeners();
        return;
      }
    }
    try {
      final all = await _api.getSeries(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: null,
      );
      _seriesCache.set(_allKey, all);
      notifyListeners();
    } catch (_) {}
  }

  SeriesItem? findSeriesByTitle(String title) {
    final q = title.trim().toLowerCase();
    if (q.isEmpty) return null;
    final all = _seriesCache.get(_allKey);
    if (all == null) return null;
    for (final s in all) {
      final n = s.name.trim().toLowerCase();
      if (n.contains(q) || q.contains(n)) return s;
    }
    return null;
  }
}
