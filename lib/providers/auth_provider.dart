import 'package:flutter/foundation.dart';

import '../models/user_info.dart';
import '../services/api_service.dart';
import '../services/auth_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final AuthStorageService _storage = AuthStorageService();

  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _errorMessage;

  String? _serverUrl;
  String? _username;
  String? _password;
  UserInfo? _userInfo;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  String? get serverUrl => _serverUrl;
  String? get username => _username;
  String? get password => _password;
  UserInfo? get userInfo => _userInfo;

  Future<void> loadSavedCredentials() async {
    _isLoading = true;
    notifyListeners();
    try {
      final creds = await _storage.getCredentials();
      if (creds != null) {
        await login(
          serverUrl: creds.serverUrl,
          username: creds.username,
          password: creds.password,
        );
      } else {
        _isLoggedIn = false;
      }
    } catch (_) {
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final userInfo = await _api.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      _serverUrl = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
      _username = username;
      _password = password;
      _userInfo = userInfo;
      _isLoggedIn = true;
      await _storage.saveCredentials(
        serverUrl: _serverUrl!,
        username: username,
        password: password,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.clearCredentials();
    _serverUrl = null;
    _username = null;
    _password = null;
    _userInfo = null;
    _isLoggedIn = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
