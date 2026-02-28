import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tmdb_provider.dart';
import '../services/tmdb_service.dart';
import '../widgets/streaming/poster_card.dart';
import '../widgets/streaming/section_header.dart';
import '../widgets/streaming/streaming_app_bar.dart';
import 'login_screen.dart';
import 'tmdb_media_detail_screen.dart';

/// First screen when user is not logged in: TMDB trending + "IPTV Login" button.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TmdbProvider>().loadTrending();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StreamingAppBar(title: 'IPTV'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Consumer<TmdbProvider>(
            builder: (context, tmdb, _) {
              if (!tmdb.isConfigured) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'TMDB is not configured. Add API key to see trending content.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Trending Movies Today'),
                  SizedBox(
                    height: 200,
                    child: tmdb.moviesLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: tmdb.trendingMovies.length,
                            itemBuilder: (context, index) {
                              final m = tmdb.trendingMovies[index];
                              final title = m['title']?.toString() ?? '';
                              final posterPath = m['poster_path']?.toString();
                              final posterUrl = TmdbService.posterUrl(posterPath);
                              return PosterCard(
                                title: title,
                                imageUrl: posterUrl.isNotEmpty ? posterUrl : null,
                                rank: index + 1,
                                onTap: () => _openDetail(
                                  context,
                                  isMovie: true,
                                  id: m['id'] is int
                                      ? m['id'] as int
                                      : int.tryParse(m['id']?.toString() ?? '') ?? 0,
                                  title: title,
                                  posterPath: posterPath,
                                  backdropPath: m['backdrop_path']?.toString(),
                                ),
                              );
                            },
                          ),
                  ),
                  const SectionHeader(title: 'Trending Series Today'),
                  SizedBox(
                    height: 200,
                    child: tmdb.seriesLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: tmdb.trendingSeries.length,
                            itemBuilder: (context, index) {
                              final s = tmdb.trendingSeries[index];
                              final title = s['name']?.toString() ?? '';
                              final posterPath = s['poster_path']?.toString();
                              final posterUrl = TmdbService.posterUrl(posterPath);
                              return PosterCard(
                                title: title,
                                imageUrl: posterUrl.isNotEmpty ? posterUrl : null,
                                rank: index + 1,
                                onTap: () => _openDetail(
                                  context,
                                  isMovie: false,
                                  id: s['id'] is int
                                      ? s['id'] as int
                                      : int.tryParse(s['id']?.toString() ?? '') ?? 0,
                                  title: title,
                                  posterPath: posterPath,
                                  backdropPath: s['backdrop_path']?.toString(),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton.icon(
              onPressed: _goToLogin,
              icon: const Icon(Icons.login),
              label: const Text('IPTV Login'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToLogin() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _openDetail(
    BuildContext context, {
    required bool isMovie,
    required int id,
    required String title,
    String? posterPath,
    String? backdropPath,
  }) {
    if (id <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TmdbMediaDetailScreen(
          isMovie: isMovie,
          id: id,
          title: title,
          posterPath: posterPath,
          backdropPath: backdropPath,
        ),
      ),
    );
  }
}
