import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/series_episode.dart';
import '../models/series_item.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'player_screen.dart';

class SeriesDetailScreen extends StatefulWidget {
  final SeriesItem series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, List<SeriesEpisode>> _episodesBySeason = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.serverUrl == null || auth.username == null || auth.password == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final map = await _api.getSeriesInfo(
        serverUrl: auth.serverUrl!,
        username: auth.username!,
        password: auth.password!,
        seriesId: widget.series.seriesId,
      );
      if (mounted) setState(() {
        _episodesBySeason = map;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.series.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _episodesBySeason.isEmpty
                  ? const Center(child: Text('No episodes found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: _episodesBySeason.entries
                            .map((e) => _SeasonSection(
                                  seasonNumber: e.key,
                                  episodes: e.value,
                                  onPlay: (ep) => _playEpisode(context, ep),
                                ))
                            .toList(),
                      ),
                    ),
    );
  }

  void _playEpisode(BuildContext context, SeriesEpisode episode) {
    final auth = context.read<AuthProvider>();
    final url = episode.buildStreamUrl(
      auth.serverUrl!,
      auth.username!,
      auth.password!,
    );
    final useM3u8Fallback = !episode.containerExtension.toLowerCase().endsWith('.m3u8');
    final fallbackUrl = useM3u8Fallback
        ? episode.buildStreamUrlM3u8(auth.serverUrl!, auth.username!, auth.password!)
        : null;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PlayerScreen(
          streamUrl: url,
          channelName: '${widget.series.name} - S${episode.seasonNumber}E${episode.episodeNum}',
          fallbackStreamUrl: fallbackUrl,
        ),
      ),
    );
  }
}

class _SeasonSection extends StatelessWidget {
  final String seasonNumber;
  final List<SeriesEpisode> episodes;
  final void Function(SeriesEpisode) onPlay;

  const _SeasonSection({
    required this.seasonNumber,
    required this.episodes,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Season $seasonNumber',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...episodes.map((ep) => ListTile(
              title: Text('E${ep.episodeNum} ${ep.title}'),
              trailing: const Icon(Icons.play_circle_filled),
              onTap: () => onPlay(ep),
            )),
      ],
    );
  }
}
