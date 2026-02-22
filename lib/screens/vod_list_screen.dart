import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_category.dart';
import '../models/vod_item.dart';
import '../providers/auth_provider.dart';
import '../providers/vod_provider.dart';
import '../widgets/vod_tile.dart';
import 'player_screen.dart';

class VodListScreen extends StatefulWidget {
  final LiveCategory category;

  const VodListScreen({super.key, required this.category});

  @override
  State<VodListScreen> createState() => _VodListScreenState();
}

class _VodListScreenState extends State<VodListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.serverUrl == null || auth.username == null || auth.password == null) return;
    await context.read<VodProvider>().loadStreams(
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
                labelText: 'Search movies',
                hintText: 'Filter movies...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: Consumer<VodProvider>(
              builder: (context, prov, _) {
                if (prov.isLoading) return const Center(child: CircularProgressIndicator());
                if (prov.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(prov.errorMessage!, textAlign: TextAlign.center,
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
                  );
                }
                final filtered = _searchQuery.isEmpty
                    ? prov.items
                    : prov.items.where((i) => i.name.toLowerCase().contains(_searchQuery)).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(prov.items.isEmpty ? 'No movies in this category' : 'No movies match "$_searchQuery"'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                final auth = context.read<AuthProvider>();
                return VodTile(
                  item: item,
                  serverUrl: auth.serverUrl!,
                  username: auth.username!,
                  password: auth.password!,
                  onTap: () => _openPlayer(context, item),
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

  void _openPlayer(BuildContext context, VodItem item) {
    final auth = context.read<AuthProvider>();
    final url = item.buildStreamUrl(
      auth.serverUrl!,
      auth.username!,
      auth.password!,
    );
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PlayerScreen(
          streamUrl: url,
          channelName: item.name,
        ),
      ),
    );
  }
}
