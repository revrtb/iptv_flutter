import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user_info.dart';
import '../models/live_category.dart';
import '../models/live_stream.dart';
import '../models/vod_item.dart';
import '../models/series_item.dart';
import '../models/series_episode.dart';

class ApiService {
  String _normalizeServerUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  String _playerApiUrl(String serverUrl, String username, String password, [Map<String, String>? query]) {
    final base = _normalizeServerUrl(serverUrl);
    final path = '${base}player_api.php';
    final params = <String, String>{
      'username': username,
      'password': password,
      ...?query,
    };
    final uri = Uri.parse(path).replace(queryParameters: params);
    return uri.toString();
  }

  static const _defaultTimeout = Duration(seconds: 15);
  /// Bulk "get all" requests (no category) can be very slow; 90s covers ~42s observed + variance.
  static const _bulkTimeout = Duration(seconds: 90);
  static const _retryDelay = Duration(seconds: 2);

  /// Redact password in URL for safe logging (query param password=xxx).
  static String _redactPasswordInUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final q = Map<String, String>.from(uri.queryParameters);
      if (q.containsKey('password')) q['password'] = '***';
      return uri.replace(queryParameters: q).toString();
    } catch (_) {
      return url.replaceAll(RegExp(r'password=[^&]+'), 'password=***');
    }
  }

  static bool _isConnectionError(Object e, [StackTrace? st]) {
    final msg = e.toString().toLowerCase();
    return msg.contains('connection') ||
        msg.contains('closed before full header') ||
        msg.contains('socket') ||
        msg.contains('connection reset') ||
        msg.contains('connection timeout');
  }

  /// Returns decoded JSON (Map or List). [timeout] for bulk lists (e.g. all streams) can be longer.
  /// [retries] for bulk requests: retry on connection closed / timeout (server may drop large responses).
  Future<dynamic> _getJson(String url, {Duration? timeout, int retries = 0}) async {
    final t = timeout ?? _defaultTimeout;
    int attempt = 0;
    while (true) {
      try {
        // Log playlist/API request (redact password in log)
        final safeUrl = _redactPasswordInUrl(url);
        debugPrint('AAAA REQUEST GET $safeUrl');
        final response = await http.get(Uri.parse(url)).timeout(
          t,
          onTimeout: () => throw Exception('Connection timeout'),
        );
        if (response.statusCode != 200) {
          throw Exception('Server error: ${response.statusCode}');
        }
        debugPrint('AAAA RESPONSE ${response.statusCode} ${_redactPasswordInUrl(url)}');
        final decoded = json.decode(response.body);
        if (decoded is! Map && decoded is! List) {
          throw Exception('Invalid API response');
        }
        return decoded;
      } catch (e, st) {
        final canRetry = retries > 0 && attempt < retries && _isConnectionError(e, st);
        if (!canRetry) rethrow;
        attempt++;
        await Future<void>.delayed(_retryDelay);
      }
    }
  }

  /// Extract a List from API response (Map or List). Tries known keys then first list value.
  static List<dynamic>? _extractList(dynamic data, List<String> keys) {
    if (data is List) return data;
    if (data is! Map) return null;
    final m = data as Map;
    for (final k in keys) {
      final v = m[k];
      if (v is List) return v;
    }
    for (final v in m.values) {
      if (v is List && v.isNotEmpty && v.first is Map) return v;
    }
    return null;
  }

  Future<UserInfo> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final url = _playerApiUrl(serverUrl, username, password);
    final data = await _getJson(url);
    if (data is! Map) {
      throw Exception('Invalid login response');
    }
    final map = Map<String, dynamic>.from(data);
    // Some panels nest under "user_info", others put user fields at root
    Map<String, dynamic> userInfoJson = map['user_info'] is Map
        ? Map<String, dynamic>.from(map['user_info'] as Map)
        : map;
    final userInfo = UserInfo.fromJson(userInfoJson);
    if (!userInfo.isActive) {
      throw Exception(userInfo.message.isNotEmpty ? userInfo.message : 'Account not active');
    }
    return userInfo;
  }

  Future<List<LiveCategory>> getLiveCategories({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final url = _playerApiUrl(serverUrl, username, password, {
      'action': 'get_live_categories',
    });
    final data = await _getJson(url);
    final list = _extractList(data, ['categories', 'live_categories']) ?? (data is List ? data : null);
    return LiveCategory.fromJsonList(list);
  }

  Future<List<LiveStream>> getLiveStreams({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  }) async {
    final query = <String, String>{'action': 'get_live_streams'};
    if (categoryId != null && categoryId.isNotEmpty) {
      query['category_id'] = categoryId;
    }
    final url = _playerApiUrl(serverUrl, username, password, query);
    final isBulk = categoryId == null || categoryId.isEmpty;
    final data = await _getJson(
      url,
      timeout: isBulk ? _bulkTimeout : null,
      retries: isBulk ? 2 : 0,
    );
    final list = _extractList(data, ['streams', 'live_streams', 'livestreams', 'live', 'channels']);
    if (list != null) return LiveStream.fromJsonList(list);
    return [];
  }

  Future<List<LiveCategory>> getVodCategories({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final url = _playerApiUrl(serverUrl, username, password, {
      'action': 'get_vod_categories',
    });
    final data = await _getJson(url);
    final list = _extractList(data, ['categories', 'vod_categories']) ?? (data is List ? data : null);
    return LiveCategory.fromJsonList(list);
  }

  Future<List<VodItem>> getVodStreams({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  }) async {
    final query = <String, String>{'action': 'get_vod_streams'};
    if (categoryId != null && categoryId.isNotEmpty) {
      query['category_id'] = categoryId;
    }
    final url = _playerApiUrl(serverUrl, username, password, query);
    final isBulk = categoryId == null || categoryId.isEmpty;
    final data = await _getJson(
      url,
      timeout: isBulk ? _bulkTimeout : null,
      retries: isBulk ? 2 : 0,
    );
    final list = _extractList(data, ['streams', 'movies', 'vod_streams', 'movie_list']);
    if (list != null) return VodItem.fromJsonList(list);
    return [];
  }

  Future<List<LiveCategory>> getSeriesCategories({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final url = _playerApiUrl(serverUrl, username, password, {
      'action': 'get_series_categories',
    });
    final data = await _getJson(url);
    final list = _extractList(data, ['categories', 'series_categories']) ?? (data is List ? data : null);
    return LiveCategory.fromJsonList(list);
  }

  Future<List<SeriesItem>> getSeries({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  }) async {
    final query = <String, String>{'action': 'get_series'};
    if (categoryId != null && categoryId.isNotEmpty) {
      query['category_id'] = categoryId;
    }
    final url = _playerApiUrl(serverUrl, username, password, query);
    final isBulk = categoryId == null || categoryId.isEmpty;
    final data = await _getJson(
      url,
      timeout: isBulk ? _bulkTimeout : null,
      retries: isBulk ? 2 : 0,
    );
    final list = _extractList(data, ['series', 'series_list']);
    if (list != null) return SeriesItem.fromJsonList(list);
    return [];
  }

  /// Returns list of episodes grouped by season. Keys are season numbers.
  Future<Map<String, List<SeriesEpisode>>> getSeriesInfo({
    required String serverUrl,
    required String username,
    required String password,
    required String seriesId,
  }) async {
    final url = _playerApiUrl(serverUrl, username, password, {
      'action': 'get_series_info',
      'series_id': seriesId,
    });
    final data = await _getJson(url);
    if (data is! Map) return {};
    final episodesData = (data as Map)['episodes'];
    if (episodesData is! Map) return {};
    final result = <String, List<SeriesEpisode>>{};
    for (final entry in episodesData.entries) {
      final seasonNum = entry.key.toString();
      final list = entry.value;
      if (list is List) {
        result[seasonNum] = list
            .map((e) => SeriesEpisode.fromJson(
                  Map<String, dynamic>.from(e as Map),
                  seasonNum,
                ))
            .toList();
      }
    }
    return result;
  }
}
