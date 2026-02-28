import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_category.dart';
import '../models/live_stream.dart';
import '../providers/auth_provider.dart';
import '../providers/streams_provider.dart';
import '../utils/layout_utils.dart';
import '../widgets/channel_tile.dart';
import '../widgets/inline_player.dart';
import '../widgets/streaming/search_field.dart';
import '../widgets/streaming/streaming_app_bar.dart';
import 'player_screen.dart';

class StreamsScreen extends StatefulWidget {
  final LiveCategory category;

  const StreamsScreen({super.key, required this.category});

  @override
  State<StreamsScreen> createState() => _StreamsScreenState();
}

class _StreamsScreenState extends State<StreamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  LiveStream? _selectedStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStreams());
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStreams({bool forceRefresh = false}) async {
    final auth = context.read<AuthProvider>();
    if (auth.serverUrl == null || auth.username == null || auth.password == null) {
      return;
    }
    await context.read<StreamsProvider>().loadStreams(
          serverUrl: auth.serverUrl!,
          username: auth.username!,
          password: auth.password!,
          categoryId: widget.category.categoryId,
          forceRefresh: forceRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final useSplit = isMobilePortrait(context);
    final playerUrl = _selectedStream != null && auth.serverUrl != null && auth.username != null && auth.password != null
        ? _selectedStream!.buildStreamUrl(auth.serverUrl!, auth.username!, auth.password!)
        : null;

    return Scaffold(
      appBar: StreamingAppBar(
        title: widget.category.categoryName,
        showBackButton: true,
      ),
      body: Column(
        children: [
          if (useSplit)
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.30,
              child: ColoredBox(
                color: Colors.black,
                child: InlinePlayerWidget(
                  streamUrl: playerUrl,
                  title: _selectedStream?.name ?? widget.category.categoryName,
                ),
              ),
            ),
          StreamingSearchField(
            controller: _searchController,
            label: 'Search channels',
            hint: 'Filter channels...',
            onChanged: (_) => setState(() {}),
          ),
          Expanded(
            child: Consumer<StreamsProvider>(
              builder: (context, prov, _) {
                if (prov.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (prov.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            prov.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _loadStreams,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final filtered = _searchQuery.isEmpty
                    ? prov.streams
                    : prov.streams.where((s) => s.name.toLowerCase().contains(_searchQuery)).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      prov.streams.isEmpty ? 'No channels in this category' : 'No channels match "$_searchQuery"',
                    ),
                  );
                }
                if (useSplit && _selectedStream == null && filtered.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _selectedStream == null) {
                      setState(() => _selectedStream = filtered.first);
                    }
                  });
                }
                return RefreshIndicator(
                  onRefresh: () => _loadStreams(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final stream = filtered[index];
                      return ChannelTile(
                        stream: stream,
                        serverUrl: auth.serverUrl!,
                        username: auth.username!,
                        password: auth.password!,
                        onTap: () => useSplit
                            ? setState(() => _selectedStream = stream)
                            : _openPlayer(context, stream),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openPlayer(BuildContext context, LiveStream stream) {
    final auth = context.read<AuthProvider>();
    final url = stream.buildStreamUrl(
      auth.serverUrl!,
      auth.username!,
      auth.password!,
    );
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PlayerScreen(
          streamUrl: url,
          channelName: stream.name,
        ),
      ),
    );
  }
}
