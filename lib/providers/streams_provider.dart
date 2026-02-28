import 'package:flutter/foundation.dart';

import '../models/live_stream.dart';
import '../services/api_service.dart';
import '../services/playlist_cache.dart';

class StreamsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final KeyedPlaylistCache<List<LiveStream>> _cache = KeyedPlaylistCache<List<LiveStream>>(
    ttl: const Duration(minutes: 10),
  );

  List<LiveStream> _streams = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentCategoryId;

  List<LiveStream> get streams => _streams;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentCategoryId => _currentCategoryId;

  static String _cacheKey(String? categoryId) =>
      (categoryId == null || categoryId.trim().isEmpty) ? '__all__' : categoryId.trim();

  /// Load streams for the current page (one category). Uses cache when fresh.
  Future<void> loadStreams({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(categoryId);
    if (!forceRefresh && _cache.isFresh(key)) {
      final cached = _cache.get(key);
      if (cached != null) {
        _streams = cached;
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
      final list = await _api.getLiveStreams(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: (categoryId == null || categoryId.trim().isEmpty) ? null : categoryId,
      );
      _streams = list;
      _cache.set(key, list);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _streams = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
