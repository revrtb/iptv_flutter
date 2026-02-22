import 'package:flutter/foundation.dart';

import '../models/live_category.dart';
import '../models/live_stream.dart';
import '../services/api_service.dart';

class CategoriesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<LiveCategory> _categories = [];
  List<LiveStream> _allStreams = [];
  final Map<String, int> _categoryCounts = {};
  final Map<String, int> _catchUpCountByCategoryId = {};
  final Map<String, List<LiveStream>> _catchUpStreamsByCategoryId = {};
  bool _isLoading = false;
  bool _countsLoading = false;
  String? _errorMessage;

  List<LiveCategory> get categories => _categories;
  List<LiveStream> get allLiveStreams => _allStreams;
  bool get isLoading => _isLoading;
  bool get countsLoading => _countsLoading;
  String? get errorMessage => _errorMessage;

  int getCategoryCount(String categoryId) =>
      _categoryCounts[categoryId.trim()] ?? _categoryCounts[categoryId] ?? 0;

  int getCatchUpCount(String categoryId) {
    final id = categoryId.trim();
    return _catchUpCountByCategoryId[id] ?? _catchUpCountByCategoryId[categoryId] ?? 0;
  }

  List<LiveStream> getCatchUpStreamsForCategory(String categoryId) {
    final id = categoryId.trim();
    return _catchUpStreamsByCategoryId[id] ?? _catchUpStreamsByCategoryId[categoryId] ?? [];
  }

  /// Load categories and counts once; reuse cache on later navigation unless [forceRefresh].
  Future<void> loadCategories({
    required String serverUrl,
    required String username,
    required String password,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _categories.isNotEmpty &&
        _categoryCounts.isNotEmpty &&
        !_countsLoading) {
      _isLoading = false;
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
      _allStreams = [];
      _categoryCounts.clear();
      _catchUpCountByCategoryId.clear();
      _catchUpStreamsByCategoryId.clear();
    }
    _isLoading = true;
    _errorMessage = null;
    _countsLoading = true;
    notifyListeners();
    try {
      _categories = await _api.getLiveCategories(
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
      final all = await _api.getLiveStreams(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: null,
      );
      _allStreams = all;
      _categoryCounts.clear();
      _catchUpCountByCategoryId.clear();
      _catchUpStreamsByCategoryId.clear();
      for (final s in all) {
        for (final id in s.categoryIdsForCount) {
          if (id.isNotEmpty) {
            _categoryCounts[id] = (_categoryCounts[id] ?? 0) + 1;
          }
        }
        if (s.hasCatchUp) {
          final ids = <String>{s.categoryId.trim()};
          for (final id in s.categoryIdsForCount) {
            if (id.isNotEmpty) ids.add(id);
          }
          for (final id in ids) {
            _catchUpCountByCategoryId[id] = (_catchUpCountByCategoryId[id] ?? 0) + 1;
            _catchUpStreamsByCategoryId.putIfAbsent(id, () => []).add(s);
          }
        }
      }
    } catch (_) {
      // Leave counts empty; categories are already shown
    } finally {
      _countsLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
