import 'package:flutter/material.dart';

import '../models/series_item.dart';

class SeriesTile extends StatelessWidget {
  final SeriesItem item;
  final String serverUrl;
  final VoidCallback onTap;

  const SeriesTile({
    super.key,
    required this.item,
    required this.serverUrl,
    required this.onTap,
  });

  String get _coverUrl {
    if (item.cover.isEmpty) return '';
    if (item.cover.startsWith('http')) return item.cover;
    final base = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return item.cover.startsWith('/') ? '$base${item.cover}' : '$base/${item.cover}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 48.0;
    const radius = 10.0;
    return ListTile(
      leading: _coverUrl.isEmpty
          ? Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Icon(Icons.tv, color: theme.colorScheme.primary),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.network(
                _coverUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: Icon(Icons.tv, color: theme.colorScheme.primary),
                ),
              ),
            ),
      title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
