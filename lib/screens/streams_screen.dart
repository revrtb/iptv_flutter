import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_category.dart';
import '../models/live_stream.dart';
import '../providers/auth_provider.dart';
import '../providers/streams_provider.dart';
import '../widgets/channel_tile.dart';
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

  Future<void> _loadStreams() async {
    final auth = context.read<AuthProvider>();
    if (auth.serverUrl == null || auth.username == null || auth.password == null) {
      return;
    }
    await context.read<StreamsProvider>().loadStreams(
          serverUrl: auth.serverUrl!,
          username: auth.username!,
          password: auth.password!,
          categoryId: widget.category.categoryId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.categoryName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search channels',
                hintText: 'Filter channels...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
            ),
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
                return RefreshIndicator(
                  onRefresh: _loadStreams,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final stream = filtered[index];
                      return ChannelTile(
                  stream: stream,
                  serverUrl: context.read<AuthProvider>().serverUrl!,
                  username: context.read<AuthProvider>().username!,
                  password: context.read<AuthProvider>().password!,
                        onTap: () => _openPlayer(context, stream),
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
