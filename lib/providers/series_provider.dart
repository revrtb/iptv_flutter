import 'package:flutter/foundation.dart';

import '../models/live_category.dart';
import '../models/series_item.dart';
import '../services/api_service.dart';

class SeriesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<LiveCategory> _categories = [];
  List<SeriesItem> _series = [];
  List<SeriesItem> _allSeries = [];
  final Map<String, int> _categoryCounts = {};
  bool _isLoading = false;
  bool _countsLoading = false;
  String? _errorMessage;
  String? _currentCategoryId;

  List<LiveCategory> get categories => _categories;
  List<SeriesItem> get series => _series;
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
        (_categoryCounts.isNotEmpty || _allSeries.isNotEmpty) &&
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
      _allSeries = [];
      _categoryCounts.clear();
    }
    _isLoading = true;
    _errorMessage = null;
    _countsLoading = true;
    notifyListeners();
    try {
      _categories = await _api.getSeriesCategories(
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
      final all = await _api.getSeries(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: null,
      );
      _allSeries = all;
      _categoryCounts.clear();
      for (final s in all) {
        for (final id in s.categoryIdsForCount) {
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

  Future<void> loadSeries({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  }) async {
    _errorMessage = null;
    _currentCategoryId = categoryId;
    final isAll = categoryId == null || categoryId.trim().isEmpty;
    if (_allSeries.isNotEmpty) {
      if (isAll) {
        _series = List.from(_allSeries);
      } else {
        final id = categoryId!.trim();
        _series = _allSeries
            .where((s) =>
                s.categoryId.trim() == id || s.categoryIdsForCount.contains(id))
            .toList();
      }
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _series = await _api.getSeries(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: isAll ? null : categoryId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _series = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ensure all series are loaded (for search). Idempotent.
  Future<void> ensureAllSeriesLoaded({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    if (_allSeries.isNotEmpty) return;
    try {
      final all = await _api.getSeries(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: null,
      );
      _allSeries = all;
      _categoryCounts.clear();
      for (final s in all) {
        for (final id in s.categoryIdsForCount) {
          if (id.isNotEmpty) _categoryCounts[id] = (_categoryCounts[id] ?? 0) + 1;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Find first series whose name matches [title] (case-insensitive contains or equals).
  SeriesItem? findSeriesByTitle(String title) {
    final q = title.trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final s in _allSeries) {
      final n = s.name.trim().toLowerCase();
      if (n.contains(q) || q.contains(n)) return s;
    }
    return null;
  }
}
