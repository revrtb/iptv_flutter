import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_category.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../widgets/streaming/content_tile.dart';
import '../widgets/streaming/search_field.dart';
import '../widgets/streaming/streaming_app_bar.dart';
import 'catch_up_channels_screen.dart';

class CatchUpScreen extends StatefulWidget {
  const CatchUpScreen({super.key});

  @override
  State<CatchUpScreen> createState() => _CatchUpScreenState();
}

class _CatchUpScreenState extends State<CatchUpScreen> {
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

  Future<void> _load({bool forceRefresh = false}) async {
    final auth = context.read<AuthProvider>();
    if (auth.serverUrl == null || auth.username == null || auth.password == null) return;
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
      appBar: const StreamingAppBar(title: 'Catch Up'),
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
              builder: (context, catProv, _) {
                if (catProv.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (catProv.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            catProv.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _load(forceRefresh: true),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final categoriesWithCount = catProv.categories.map((c) {
                  final count = catProv.getCatchUpCount(c.categoryId);
                  return MapEntry(c, count);
                }).toList();
                final filtered = _searchQuery.isEmpty
                    ? categoriesWithCount
                    : categoriesWithCount
                        .where((e) =>
                            e.key.categoryName.toLowerCase().contains(_searchQuery))
                        .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      catProv.categories.isEmpty
                          ? 'No categories found'
                          : 'No categories match "$_searchQuery"',
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => _load(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      final category = entry.key;
                      final count = entry.value;
                      final countLabel = count > 0 ? '$count programs' : 'Tap to view';
                      return ContentTile(
                        title: category.categoryName,
                        subtitle: countLabel,
                        fallbackIcon: Icons.folder_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => CatchUpChannelsScreen(category: category),
                          ),
                        ),
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
}
