/// TMDB API configuration.
/// Get a free API key at https://www.themoviedb.org/settings/api
/// Set [apiKey] or use [TmdbConfig.fromEnvironment] (e.g. --dart-define=TMDB_API_KEY=xxx).
class TmdbConfig {
  const TmdbConfig({required this.apiKey});

  final String apiKey;

  bool get isConfigured => apiKey.isNotEmpty;

  /// From compile-time: flutter run --dart-define=TMDB_API_KEY=your_key
  factory TmdbConfig.fromEnvironment() {
    const key = String.fromEnvironment(
      'TMDB_API_KEY',
      defaultValue: '',
    );
    return TmdbConfig(apiKey: key);
  }
}
