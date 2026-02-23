import 'package:flutter/foundation.dart';

import '../services/tmdb_service.dart';

class TmdbProvider extends ChangeNotifier {
  TmdbProvider({TmdbService? service}) : _service = service ?? TmdbService();

  final TmdbService _service;

  bool get isConfigured => _service.isConfigured;

  List<Map<String, dynamic>> _trendingMovies = [];
  List<Map<String, dynamic>> _trendingSeries = [];
  bool _moviesLoading = false;
  bool _seriesLoading = false;

  List<Map<String, dynamic>> get trendingMovies => _trendingMovies;
  List<Map<String, dynamic>> get trendingSeries => _trendingSeries;
  bool get moviesLoading => _moviesLoading;
  bool get seriesLoading => _seriesLoading;

  Future<void> loadTrendingMovies() async {
    if (!_service.isConfigured) return;
    _moviesLoading = true;
    notifyListeners();
    try {
      _trendingMovies = await _service.getTrendingMovies();
    } catch (_) {
      _trendingMovies = [];
    } finally {
      _moviesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTrendingSeries() async {
    if (!_service.isConfigured) return;
    _seriesLoading = true;
    notifyListeners();
    try {
      _trendingSeries = await _service.getTrendingSeries();
    } catch (_) {
      _trendingSeries = [];
    } finally {
      _seriesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTrending() async {
    await Future.wait([loadTrendingMovies(), loadTrendingSeries()]);
  }

  Future<Map<String, dynamic>?> getMovieDetails(int movieId) =>
      _service.getMovieDetails(movieId);

  Future<Map<String, dynamic>?> getTvDetails(int tvId) =>
      _service.getTvDetails(tvId);

  Future<List<Map<String, dynamic>>> getMovieVideos(int movieId) =>
      _service.getMovieVideos(movieId);

  Future<List<Map<String, dynamic>>> getTvVideos(int tvId) =>
      _service.getTvVideos(tvId);

  Future<List<Map<String, dynamic>>> getMovieCredits(int movieId) =>
      _service.getMovieCredits(movieId);

  Future<List<Map<String, dynamic>>> getTvCredits(int tvId) =>
      _service.getTvCredits(tvId);
}
