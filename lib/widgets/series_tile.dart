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
    return ListTile(
      leading: _coverUrl.isEmpty
          ? CircleAvatar(
              child: Icon(Icons.tv, color: Theme.of(context).colorScheme.onPrimary),
            )
          : CircleAvatar(
              child: ClipOval(
                child: Image.network(
                  _coverUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.tv,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
      title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
