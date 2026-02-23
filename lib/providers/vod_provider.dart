import 'package:flutter/foundation.dart';

import '../models/live_category.dart';
import '../models/vod_item.dart';
import '../services/api_service.dart';

class VodProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<LiveCategory> _categories = [];
  List<VodItem> _items = [];
  List<VodItem> _allItems = [];
  final Map<String, int> _categoryCounts = {};
  bool _isLoading = false;
  bool _countsLoading = false;
  String? _errorMessage;
  String? _currentCategoryId;

  List<LiveCategory> get categories => _categories;
  List<VodItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get countsLoading => _countsLoading;
  String? get errorMessage => _errorMessage;
  String? get currentCategoryId => _currentCategoryId;

  int getCategoryCount(String categoryId) =>
      _categoryCounts[categoryId.trim()] ?? _categoryCounts[categoryId] ?? 0;

  /// Load categories and counts once; reuse cache on later navigation unless [forceRefresh].
  Future<void> loadCategories({
    required String serverUrl,
    required String username,
    required String password,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _categories.isNotEmpty &&
        (_categoryCounts.isNotEmpty || _allItems.isNotEmpty) &&
        !_countsLoading) {
      _isLoading = false;
      _countsLoading = _categoryCounts.isEmpty;
      notifyListeners();
      return;
    }
    if (!forceRefresh && _categories.isNotEmpty && _countsLoading) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    if (forceRefresh) {
      _categories = [];
      _allItems = [];
      _categoryCounts.clear();
    }
    _isLoading = true;
    _errorMessage = null;
    _countsLoading = true;
    notifyListeners();
    try {
      _categories = await _api.getVodCategories(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _categories = [];
      _isLoading = false;
      _countsLoading = false;
      notifyListeners();
      return;
    }
    _loadCountsInBackground(serverUrl: serverUrl, username: username, password: password);
  }

  void _loadCountsInBackground({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    try {
      final all = await _api.getVodStreams(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: null,
      );
      _allItems = all;
      _categoryCounts.clear();
      for (final v in all) {
        for (final id in v.categoryIdsForCount) {
          if (id.isNotEmpty) {
            _categoryCounts[id] = (_categoryCounts[id] ?? 0) + 1;
          }
        }
      }
    } catch (_) {}
    finally {
      _countsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStreams({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  }) async {
    _errorMessage = null;
    _currentCategoryId = categoryId;
    final isAll = categoryId == null || categoryId.trim().isEmpty;
    if (_allItems.isNotEmpty) {
      if (isAll) {
        _items = List.from(_allItems);
      } else {
        final id = categoryId!.trim();
        _items = _allItems
            .where((v) =>
                v.categoryId.trim() == id || v.categoryIdsForCount.contains(id))
            .toList();
      }
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _api.getVodStreams(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: isAll ? null : categoryId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ensure all VOD items are loaded (for search). Idempotent.
  Future<void> ensureAllVodLoaded({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    if (_allItems.isNotEmpty) return;
    try {
      final all = await _api.getVodStreams(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: null,
      );
      _allItems = all;
      _categoryCounts.clear();
      for (final v in all) {
        for (final id in v.categoryIdsForCount) {
          if (id.isNotEmpty) _categoryCounts[id] = (_categoryCounts[id] ?? 0) + 1;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Find first VOD whose name matches [title] (case-insensitive contains or equals).
  VodItem? findVodByTitle(String title) {
    final q = title.trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final v in _allItems) {
      final n = v.name.trim().toLowerCase();
      if (n.contains(q) || q.contains(n)) return v;
    }
    return null;
  }
}
