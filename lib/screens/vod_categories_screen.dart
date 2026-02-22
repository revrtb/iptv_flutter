import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_category.dart';
import '../providers/auth_provider.dart';
import '../providers/vod_provider.dart';
import 'vod_list_screen.dart';

class VodCategoriesScreen extends StatefulWidget {
  const VodCategoriesScreen({super.key});

  @override
  State<VodCategoriesScreen> createState() => _VodCategoriesScreenState();
}

class _VodCategoriesScreenState extends State<VodCategoriesScreen> {
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
    if (auth.serverUrl == null || auth.username == null || auth.password == null) return;
    await context.read<VodProvider>().loadCategories(
          serverUrl: auth.serverUrl!,
          username: auth.username!,
          password: auth.password!,
          forceRefresh: forceRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movies')),
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
                    child: Text(prov.categories.isEmpty ? 'No categories found' : 'No categories match "$_searchQuery"'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => _loadCategories(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      final count = prov.countsLoading
                          ? null
                          : prov.getCategoryCount(category.categoryId);
                      final countLabel = count == null ? '...' : count.toString();
                      return ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.folder, color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  title: Text('${category.categoryName} ($countLabel)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => VodListScreen(category: category),
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
