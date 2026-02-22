import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_category.dart';
import '../models/live_stream.dart';
import '../providers/auth_provider.dart';
import '../utils/layout_utils.dart';
import '../widgets/channel_tile.dart';
import '../widgets/inline_player.dart';
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
  LiveStream? _selectedStream;

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
    final auth = context.read<AuthProvider>();
    final useSplit = isMobilePortrait(context);
    final playerUrl = _selectedStream != null && auth.serverUrl != null && auth.username != null && auth.password != null
        ? _selectedStream!.buildStreamUrl(auth.serverUrl!, auth.username!, auth.password!)
        : null;
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
                : _buildCatchUpList(filtered, useSplit, auth),
          ),
        ],
      ),
    );
  }

  Widget _buildCatchUpList(List<LiveStream> filtered, bool useSplit, AuthProvider auth) {
    if (useSplit && _selectedStream == null && filtered.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedStream == null) {
          setState(() => _selectedStream = filtered.first);
        }
      });
    }
    return ListView.builder(
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
