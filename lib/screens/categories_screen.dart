import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_category.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../widgets/streaming/content_tile.dart';
import '../widgets/streaming/search_field.dart';
import '../widgets/streaming/streaming_app_bar.dart';
import 'streams_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    final auth = context.read<AuthProvider>();
    if (auth.serverUrl == null || auth.username == null || auth.password == null) {
      return;
    }
    await context.read<CategoriesProvider>().loadCategories(
          serverUrl: auth.serverUrl!,
          username: auth.username!,
          password: auth.password!,
          forceRefresh: forceRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StreamingAppBar(
        title: 'Live TV',
        showBackButton: true,
      ),
      body: Column(
        children: [
          StreamingSearchField(
            controller: _searchController,
            label: 'Search category',
            hint: 'Filter categories...',
            onChanged: (_) => setState(() {}),
          ),
          Expanded(
            child: Consumer<CategoriesProvider>(
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
                            onPressed: () => _loadCategories(forceRefresh: true),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final filtered = _searchQuery.isEmpty
                    ? prov.categories
                    : prov.categories.where((c) => c.categoryName.toLowerCase().contains(_searchQuery)).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      prov.categories.isEmpty ? 'No categories found' : 'No categories match "$_searchQuery"',
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => _loadCategories(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      final count = prov.getCategoryCount(category.categoryId);
                      final countLabel = count > 0 ? '$count channels' : null;
                      return ContentTile(
                        title: category.categoryName,
                        subtitle: countLabel,
                        fallbackIcon: Icons.live_tv,
                        onTap: () => _openStreams(context, category),
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

  void _openStreams(BuildContext context, LiveCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => StreamsScreen(category: category),
      ),
    );
  }
}
