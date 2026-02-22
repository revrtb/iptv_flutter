import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_category.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
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
      appBar: AppBar(title: const Text('Catch Up')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search category',
                hintText: 'Filter categories...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
            ),
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
                final streamsReady = !catProv.countsLoading;
                final categoriesWithCount = catProv.categories.map((c) {
                  final count = streamsReady
                      ? catProv.getCatchUpCount(c.categoryId)
                      : null;
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
                      final countLabel = count == null ? '...' : count.toString();
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            Icons.folder,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        title: Text('${category.categoryName} ($countLabel)'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => CatchUpChannelsScreen(
                              category: category,
                              catchUpStreams: catProv.getCatchUpStreamsForCategory(category.categoryId),
                            ),
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
