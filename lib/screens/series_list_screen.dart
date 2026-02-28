import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_category.dart';
import '../models/series_item.dart';
import '../providers/auth_provider.dart';
import '../providers/series_provider.dart';
import '../widgets/streaming/search_field.dart';
import '../widgets/streaming/streaming_app_bar.dart';
import '../widgets/series_tile.dart';
import 'series_detail_screen.dart';

class SeriesListScreen extends StatefulWidget {
  final LiveCategory category;
  /// Pre-fill search field (e.g. from "Check Availability").
  final String? initialSearchQuery;

  const SeriesListScreen({
    super.key,
    required this.category,
    this.initialSearchQuery,
  });

  @override
  State<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends State<SeriesListScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery ?? '');
    _searchQuery = (widget.initialSearchQuery ?? '').trim().toLowerCase();
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
    final categoryId = widget.category.categoryId.trim().isEmpty
        ? null
        : widget.category.categoryId;
    await context.read<SeriesProvider>().loadSeries(
          serverUrl: auth.serverUrl!,
          username: auth.username!,
          password: auth.password!,
          categoryId: categoryId,
          forceRefresh: forceRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StreamingAppBar(
        title: widget.category.categoryName,
        showBackButton: true,
      ),
      body: Column(
        children: [
          StreamingSearchField(
            controller: _searchController,
            label: 'Search series',
            hint: 'Filter series...',
            onChanged: (_) => setState(() {}),
          ),
          Expanded(
            child: Consumer<SeriesProvider>(
              builder: (context, prov, _) {
                if (prov.isLoading) {
                  final isAll = widget.category.categoryId.trim().isEmpty;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        if (isAll) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Loading your playlist…',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
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
                    ? prov.series
                    : prov.series.where((s) => s.name.toLowerCase().contains(_searchQuery)).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(prov.series.isEmpty ? 'No series in this category' : 'No series match "$_searchQuery"'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => _load(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return SeriesTile(
                  item: item,
                  serverUrl: context.read<AuthProvider>().serverUrl!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => SeriesDetailScreen(series: item),
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
