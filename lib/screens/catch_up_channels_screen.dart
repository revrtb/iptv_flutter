import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_category.dart';
import '../models/live_stream.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../utils/layout_utils.dart';
import '../widgets/channel_tile.dart';
import '../widgets/inline_player.dart';
import '../widgets/streaming/search_field.dart';
import '../widgets/streaming/streaming_app_bar.dart';
import 'player_screen.dart';

class CatchUpChannelsScreen extends StatefulWidget {
  final LiveCategory category;

  const CatchUpChannelsScreen({super.key, required this.category});

  @override
  State<CatchUpChannelsScreen> createState() => _CatchUpChannelsScreenState();
}

class _CatchUpChannelsScreenState extends State<CatchUpChannelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  LiveStream? _selectedStream;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text.trim().toLowerCase()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatchUp());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatchUp() async {
    final auth = context.read<AuthProvider>();
    if (auth.serverUrl == null || auth.username == null || auth.password == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    await context.read<CategoriesProvider>().loadCatchUpForCategory(
          serverUrl: auth.serverUrl!,
          username: auth.username!,
          password: auth.password!,
          categoryId: widget.category.categoryId,
        );
    if (mounted) setState(() => _loading = false);
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
            label: 'Search Channel',
            hint: 'Filter channels...',
            onChanged: (_) => setState(() {}),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Consumer<CategoriesProvider>(
                    builder: (context, catProv, _) {
                      final catchUpStreams = catProv.getCatchUpStreamsForCategory(widget.category.categoryId);
                      final filtered = _searchQuery.isEmpty
                          ? catchUpStreams
                          : catchUpStreams
                              .where((s) => s.name.toLowerCase().contains(_searchQuery))
                              .toList();
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            catchUpStreams.isEmpty
                                ? 'No catch-up channels in this category'
                                : 'No channels match "$_searchQuery"',
                          ),
                        );
                      }
                      return _buildCatchUpList(filtered, useSplit, auth);
                    },
                  ),
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
