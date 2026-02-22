import 'package:flutter/foundation.dart';

import '../models/live_stream.dart';
import '../services/api_service.dart';

class StreamsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<LiveStream> _streams = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentCategoryId;

  List<LiveStream> get streams => _streams;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentCategoryId => _currentCategoryId;

  Future<void> loadStreams({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _currentCategoryId = categoryId;
    notifyListeners();
    try {
      _streams = await _api.getLiveStreams(
        serverUrl: serverUrl,
        username: username,
        password: password,
        categoryId: categoryId,
      );
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
