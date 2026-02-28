import 'package:flutter/foundation.dart';

import '../models/live_category.dart';
import '../models/vod_item.dart';
import '../services/api_service.dart';
import '../services/playlist_cache.dart';

class VodProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final PlaylistCache<List<LiveCategory>> _categoriesCache = PlaylistCache<List<LiveCategory>>(
    ttl: const Duration(minutes: 10),
  );
  final KeyedPlaylistCache<List<VodItem>> _itemsCache = KeyedPlaylistCache<List<VodItem>>(
    ttl: const Duration(minutes: 10),
  );

  static const String _allKey = '__all__';

  List<LiveCategory> _categories = [];
  List<VodItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentCategoryId;

  List<LiveCategory> get categories => _categories;
  List<VodItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get countsLoading => false;
  String? get errorMessage => _errorMessage;
  String? get currentCategoryId => _currentCategoryId;

  int getCategoryCount(String categoryId) {
    final id = categoryId.trim();
    final list = _itemsCache.get(id);
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
      _categories = await _api.getVodCategories(
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

  /// Load movies for the current page (one category or all). Uses cache when fresh.
  Future<void> loadStreams({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(categoryId);
    if (!forceRefresh && _itemsCache.isFresh(key)) {
      final cached = _itemsCache.get(key);
      if (cached != null) {
        _items = cached;
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
      _items = await _api.getVodStreams(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: (categoryId == null || categoryId.trim().isEmpty) ? null : categoryId,
      );
      _itemsCache.set(key, _items);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load full list only when needed (e.g. Check Availability). Uses cache when fresh.
  Future<void> ensureAllVodLoaded({
    required String serverUrl,
    required String username,
    required String password,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _itemsCache.isFresh(_allKey)) {
      final cached = _itemsCache.get(_allKey);
      if (cached != null) {
        notifyListeners();
        return;
      }
    }
    try {
      final all = await _api.getVodStreams(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: null,
      );
      _itemsCache.set(_allKey, all);
      notifyListeners();
    } catch (_) {}
  }

  VodItem? findVodByTitle(String title) {
    final q = title.trim().toLowerCase();
    if (q.isEmpty) return null;
    final all = _itemsCache.get(_allKey);
    if (all == null) return null;
    for (final v in all) {
      final n = v.name.trim().toLowerCase();
      if (n.contains(q) || q.contains(n)) return v;
    }
    return null;
  }
}
