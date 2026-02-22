import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const _keyServerUrl = 'iptv_server_url';
  static const _keyUsername = 'iptv_username';
  static const _keyPassword = 'iptv_password';

  Future<void> saveCredentials({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, serverUrl);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
  }

  Future<({String serverUrl, String username, String password})?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString(_keyServerUrl);
    final username = prefs.getString(_keyUsername);
    final password = prefs.getString(_keyPassword);
    if (serverUrl == null || username == null || password == null) {
      return null;
    }
    return (serverUrl: serverUrl, username: username, password: password);
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServerUrl);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
  }
}
