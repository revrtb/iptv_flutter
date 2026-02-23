import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/tmdb_provider.dart';
import '../services/tmdb_service.dart';
import 'categories_screen.dart';
import 'vod_categories_screen.dart';
import 'series_categories_screen.dart';
import 'catch_up_screen.dart';
import 'tmdb_media_detail_screen.dart';

enum MenuItemType { liveTv, movies, series, catchUp }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      appBar: AppBar(
        title: const Text('IPTV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Do you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                context.read<AuthProvider>().logout();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Consumer<TmdbProvider>(
            builder: (context, tmdb, _) {
              if (!tmdb.isConfigured) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '20 Trending Movies Today',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: tmdb.moviesLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: tmdb.trendingMovies.length,
                            itemBuilder: (context, index) {
                              final m = tmdb.trendingMovies[index];
                              return _TmdbPoster(
                                title: m['title']?.toString() ?? '',
                                posterPath: m['poster_path']?.toString(),
                                backdropPath: m['backdrop_path']?.toString(),
                                onTap: () => _openDetail(
                                  context,
                                  isMovie: true,
                                  id: m['id'] is int ? m['id'] as int : int.tryParse(m['id']?.toString() ?? '') ?? 0,
                                  title: m['title']?.toString() ?? '',
                                  posterPath: m['poster_path']?.toString(),
                                  backdropPath: m['backdrop_path']?.toString(),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '20 Trending Series Today',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: tmdb.seriesLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: tmdb.trendingSeries.length,
                            itemBuilder: (context, index) {
                              final s = tmdb.trendingSeries[index];
                              return _TmdbPoster(
                                title: s['name']?.toString() ?? '',
                                posterPath: s['poster_path']?.toString(),
                                backdropPath: s['backdrop_path']?.toString(),
                                onTap: () => _openDetail(
                                  context,
                                  isMovie: false,
                                  id: s['id'] is int ? s['id'] as int : int.tryParse(s['id']?.toString() ?? '') ?? 0,
                                  title: s['name']?.toString() ?? '',
                                  posterPath: s['poster_path']?.toString(),
                                  backdropPath: s['backdrop_path']?.toString(),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
          _MenuTile(
            title: 'LIVE TV',
            subtitle: 'Watch live channels',
            icon: Icons.live_tv,
            onTap: () => _navigate(context, MenuItemType.liveTv),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            title: 'MOVIES',
            subtitle: 'Video on demand',
            icon: Icons.movie,
            onTap: () => _navigate(context, MenuItemType.movies),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            title: 'SERIES',
            subtitle: 'TV series',
            icon: Icons.tv,
            onTap: () => _navigate(context, MenuItemType.series),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            title: 'CATCH UP',
            subtitle: 'Replay past broadcasts',
            icon: Icons.replay,
            onTap: () => _navigate(context, MenuItemType.catchUp),
          ),
        ],
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

  void _navigate(BuildContext context, MenuItemType type) {
    switch (type) {
      case MenuItemType.liveTv:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const CategoriesScreen(),
          ),
        );
        break;
      case MenuItemType.movies:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const VodCategoriesScreen(),
          ),
        );
        break;
      case MenuItemType.series:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const SeriesCategoriesScreen(),
          ),
        );
        break;
      case MenuItemType.catchUp:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const CatchUpScreen(),
          ),
        );
        break;
    }
  }
}

class _TmdbPoster extends StatelessWidget {
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final VoidCallback onTap;

  const _TmdbPoster({
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final posterUrl = TmdbService.posterUrl(posterPath);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 110,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: posterUrl.isNotEmpty
                      ? Image.network(
                          posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.movie, size: 48),
                          ),
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.movie, size: 48),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
