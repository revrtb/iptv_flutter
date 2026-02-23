import 'package:tmdb_api/tmdb_api.dart';

import 'tmdb_config.dart';

const _imageBaseUrl = 'https://image.tmdb.org/t/p/';
const _backdropSize = 'w780';
const _posterSize = 'w342';
const _profileSize = 'w185';

class TmdbService {
  TmdbService({TmdbConfig? config}) : _config = config ?? TmdbConfig.fromEnvironment() {
    if (_config.isConfigured) {
      _tmdb = TMDB(
        ApiKeys(_config.apiKey, _config.apiKey),
        logConfig: ConfigLogger.showNone(),
      );
    }
  }

  final TmdbConfig _config;
  late final TMDB? _tmdb;

  bool get isConfigured => _config.isConfigured;

  static String backdropUrl(String? path) =>
      path != null && path.isNotEmpty ? '$_imageBaseUrl$_backdropSize$path' : '';
  static String posterUrl(String? path) =>
      path != null && path.isNotEmpty ? '$_imageBaseUrl$_posterSize$path' : '';
  static String profileUrl(String? path) =>
      path != null && path.isNotEmpty ? '$_imageBaseUrl$_profileSize$path' : '';

  /// Trending movies today (up to 20).
  Future<List<Map<String, dynamic>>> getTrendingMovies() async {
    if (!_config.isConfigured) return [];
    try {
      final result = await _tmdb!.v3.trending.getTrending(
        mediaType: MediaType.movie,
        timeWindow: TimeWindow.day,
        page: 1,
      );
      final list = result['results'] as List<dynamic>? ?? [];
      return list.take(20).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Trending TV series today (up to 20).
  Future<List<Map<String, dynamic>>> getTrendingSeries() async {
    if (!_config.isConfigured) return [];
    try {
      final result = await _tmdb!.v3.trending.getTrending(
        mediaType: MediaType.tv,
        timeWindow: TimeWindow.day,
        page: 1,
      );
      final list = result['results'] as List<dynamic>? ?? [];
      return list.take(20).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Movie details by id.
  Future<Map<String, dynamic>?> getMovieDetails(int movieId) async {
    if (!_config.isConfigured) return null;
    try {
      final result = await _tmdb!.v3.movies.getDetails(movieId);
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return null;
    }
  }

  /// TV details by id.
  Future<Map<String, dynamic>?> getTvDetails(int tvId) async {
    if (!_config.isConfigured) return null;
    try {
      final result = await _tmdb!.v3.tv.getDetails(tvId);
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return null;
    }
  }

  /// Movie videos (trailers, etc.).
  Future<List<Map<String, dynamic>>> getMovieVideos(int movieId) async {
    if (!_config.isConfigured) return [];
    try {
      final result = await _tmdb!.v3.movies.getVideos(movieId);
      final list = result['results'] as List<dynamic>? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// TV videos (trailers, etc.).
  Future<List<Map<String, dynamic>>> getTvVideos(int tvId) async {
    if (!_config.isConfigured) return [];
    try {
      final result = await _tmdb!.v3.tv.getVideos(tvId.toString());
      final list = result['results'] as List<dynamic>? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Movie cast.
  Future<List<Map<String, dynamic>>> getMovieCredits(int movieId) async {
    if (!_config.isConfigured) return [];
    try {
      final result = await _tmdb!.v3.movies.getCredits(movieId);
      final list = result['cast'] as List<dynamic>? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// TV cast (from credits).
  Future<List<Map<String, dynamic>>> getTvCredits(int tvId) async {
    if (!_config.isConfigured) return [];
    try {
      final result = await _tmdb!.v3.tv.getCredits(tvId);
      final list = result['cast'] as List<dynamic>? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }
}
