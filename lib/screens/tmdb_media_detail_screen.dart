import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/live_category.dart';
import '../providers/auth_provider.dart';
import '../providers/series_provider.dart';
import '../providers/tmdb_provider.dart';
import '../providers/vod_provider.dart';
import '../services/tmdb_service.dart';
import '../widgets/streaming/streaming_app_bar.dart';
import 'series_list_screen.dart';
import 'vod_list_screen.dart';

class TmdbMediaDetailScreen extends StatefulWidget {
  final bool isMovie;
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;

  const TmdbMediaDetailScreen({
    super.key,
    required this.isMovie,
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
  });

  @override
  State<TmdbMediaDetailScreen> createState() => _TmdbMediaDetailScreenState();
}

class _TmdbMediaDetailScreenState extends State<TmdbMediaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _details;
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _cast = [];
  bool _loading = true;
  bool _checkingAvailability = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    // Preload playlist in background so "Check Availability" is fast
    WidgetsBinding.instance.addPostFrameCallback((_) => _preloadPlaylist());
  }

  void _preloadPlaylist() {
    final auth = context.read<AuthProvider>();
    if (auth.serverUrl == null || auth.username == null || auth.password == null) return;
    // Preload both so either Movies or Series "Check Availability" is fast
    context.read<VodProvider>().ensureAllVodLoaded(
      serverUrl: auth.serverUrl!,
      username: auth.username!,
      password: auth.password!,
    );
    context.read<SeriesProvider>().ensureAllSeriesLoaded(
      serverUrl: auth.serverUrl!,
      username: auth.username!,
      password: auth.password!,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final tmdb = context.read<TmdbProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.isMovie) {
        _details = await tmdb.getMovieDetails(widget.id);
        _videos = await tmdb.getMovieVideos(widget.id);
        _cast = await tmdb.getMovieCredits(widget.id);
      } else {
        _details = await tmdb.getTvDetails(widget.id);
        _videos = await tmdb.getTvVideos(widget.id);
        _cast = await tmdb.getTvCredits(widget.id);
      }
      if (mounted) setState(() { _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String get _name {
    if (_details == null) return widget.title;
    return (widget.isMovie
            ? _details!['title']?.toString()
            : _details!['name']?.toString()) ??
        widget.title;
  }

  String get _year {
    final d = _details;
    if (d == null) return '';
    final date = (widget.isMovie ? d['release_date'] : d['first_air_date'])?.toString();
    if (date == null || date.length < 4) return '';
    return date.substring(0, 4);
  }

  String get _genres {
    final list = _details?['genres'] as List<dynamic>?;
    if (list == null || list.isEmpty) return '';
    return list
        .map((e) => (e is Map ? e['name']?.toString() : null) ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  String get _duration {
    if (widget.isMovie) {
      final m = _details?['runtime'];
      if (m == null) return '';
      final min = m is int ? m : int.tryParse(m.toString());
      if (min == null || min <= 0) return '';
      if (min < 60) return '${min}m';
      return '${min ~/ 60}h ${min % 60}m';
    }
    final list = _details?['episode_run_time'] as List<dynamic>?;
    if (list == null || list.isEmpty) return '';
    final first = list.isNotEmpty ? list.first : null;
    final min = first is int ? first : int.tryParse(first?.toString() ?? '');
    if (min == null || min <= 0) return '';
    return '${min}min';
  }

  double get _rating {
    final v = _details?['vote_average'];
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String get _overview => _details?['overview']?.toString() ?? '';

  String get _backdropPath =>
      _details?['backdrop_path']?.toString() ?? widget.backdropPath ?? '';

  List<Map<String, dynamic>> get _trailerVideos {
    return _videos
        .where((v) =>
            (v['site']?.toString() == 'YouTube') &&
            ((v['type']?.toString().toLowerCase() == 'trailer') ||
                (v['type']?.toString().toLowerCase() == 'teaser') ||
                (v['type']?.toString().toLowerCase() == 'clip')))
        .toList();
  }

  Future<void> _checkAvailability() async {
    final auth = context.read<AuthProvider>();
    if (auth.serverUrl == null || auth.username == null || auth.password == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }
    if (_checkingAvailability) return;
    setState(() => _checkingAvailability = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading catalog...'), duration: Duration(seconds: 2)),
      );
    }
    try {
      if (widget.isMovie) {
        await context.read<VodProvider>().ensureAllVodLoaded(
          serverUrl: auth.serverUrl!,
          username: auth.username!,
          password: auth.password!,
        );
      } else {
        await context.read<SeriesProvider>().ensureAllSeriesLoaded(
          serverUrl: auth.serverUrl!,
          username: auth.username!,
          password: auth.password!,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load catalog. Pull to refresh on the next screen.')),
        );
      }
    }
    if (!mounted) return;
    setState(() => _checkingAvailability = false);
    final searchTitle = _name;
    if (widget.isMovie) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => VodListScreen(
            category: const LiveCategory(categoryId: '', categoryName: 'All Movies'),
            initialSearchQuery: searchTitle,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => SeriesListScreen(
            category: const LiveCategory(categoryId: '', categoryName: 'All Series'),
            initialSearchQuery: searchTitle,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: StreamingAppBar(title: widget.title),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: StreamingAppBar(title: widget.title),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final backdropUrl = TmdbService.backdropUrl(_backdropPath);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: backdropUrl.isNotEmpty
                  ? Image.network(
                      backdropUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest),
                    )
                  : Container(color: theme.colorScheme.surfaceContainerHighest),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (_year.isNotEmpty) _Chip(text: _year),
                      if (_genres.isNotEmpty) _Chip(text: _genres),
                      if (_duration.isNotEmpty) _Chip(text: _duration),
                      _Chip(text: '★ ${_rating.toStringAsFixed(1)}'),
                    ],
                  ),
                  if (_overview.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _overview,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _checkingAvailability ? null : _checkAvailability,
                      icon: _checkingAvailability
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(_checkingAvailability ? 'Loading catalog...' : 'Check Availability'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'TRAILERS'),
                      Tab(text: 'CAST'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TrailersTab(videos: _trailerVideos),
                _CastTab(cast: _cast),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(text, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TrailersTab extends StatelessWidget {
  const _TrailersTab({required this.videos});

  final List<Map<String, dynamic>> videos;

  static String _youtubeThumbnail(String videoKey) =>
      'https://img.youtube.com/vi/$videoKey/mqdefault.jpg';

  static Future<bool> _openYoutube(BuildContext context, String key) async {
    if (key.isEmpty) return false;
    final webUri = Uri.parse('https://www.youtube.com/watch?v=$key');
    // 1. Try YouTube app scheme first (don't use canLaunchUrl - it often returns false on Android 11+)
    final appUri = Uri.parse('vnd.youtube://watch?v=$key');
    try {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return true;
    } catch (_) {}
    // 2. On Android: intent URL to force YouTube app (package=com.google.android.youtube)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final intentUri = Uri.parse(
          'intent://www.youtube.com/watch?v=$key#Intent;'
          'package=com.google.android.youtube;'
          'scheme=https;'
          'end',
        );
        await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        return true;
      } catch (_) {}
    }
    // 3. Fallback: open in external app (browser or YouTube if system prefers it)
    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return true;
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t open trailer. Install YouTube app or try in a browser.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const Center(child: Text('No trailers available'));
    }
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final v = videos[index];
        final key = v['key']?.toString() ?? '';
        final name = v['name']?.toString() ?? 'Trailer';
        final thumbUrl = key.isNotEmpty ? _youtubeThumbnail(key) : null;
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: key.isNotEmpty ? () => _openYoutube(context, key) : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 90,
                  child: thumbUrl != null
                      ? Image.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.play_circle_outline,
                                color: theme.colorScheme.primary, size: 48),
                          ),
                        )
                      : ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.play_circle_outline,
                              color: theme.colorScheme.primary, size: 48),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_filled, color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CastTab extends StatelessWidget {
  final List<Map<String, dynamic>> cast;

  const _CastTab({required this.cast});

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) {
      return const Center(child: Text('No cast information'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cast.length,
      itemBuilder: (context, index) {
        final c = cast[index];
        final name = c['name']?.toString() ?? '';
        final character = c['character']?.toString();
        final path = c['profile_path']?.toString();
        final imgUrl = TmdbService.profileUrl(path);
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: imgUrl.isNotEmpty
                    ? Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 48),
                      )
                    : const Center(child: Icon(Icons.person, size: 48)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (character != null && character.isNotEmpty)
                      Text(
                        character,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
