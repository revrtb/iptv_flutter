import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_category.dart';
import '../models/live_stream.dart';
import '../providers/auth_provider.dart';
import '../widgets/channel_tile.dart';
import 'player_screen.dart';

class CatchUpChannelsScreen extends StatefulWidget {
  final LiveCategory category;
  final List<LiveStream> catchUpStreams;

  const CatchUpChannelsScreen({
    super.key,
    required this.category,
    required this.catchUpStreams,
  });

  @override
  State<CatchUpChannelsScreen> createState() => _CatchUpChannelsScreenState();
}

class _CatchUpChannelsScreenState extends State<CatchUpChannelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? widget.catchUpStreams
        : widget.catchUpStreams
            .where((s) => s.name.toLowerCase().contains(_searchQuery))
            .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.categoryName} (${widget.catchUpStreams.length})'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Channel',
                hintText: 'Filter channels...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      widget.catchUpStreams.isEmpty
                          ? 'No catch-up channels in this category'
                          : 'No channels match "$_searchQuery"',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final stream = filtered[index];
                      final auth = context.read<AuthProvider>();
                      return ChannelTile(
                        stream: stream,
                        serverUrl: auth.serverUrl!,
                        username: auth.username!,
                        password: auth.password!,
                        onTap: () => _openPlayer(context, stream),
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
