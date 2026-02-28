import 'package:flutter/material.dart';

import '../models/vod_item.dart';

class VodTile extends StatelessWidget {
  final VodItem item;
  final String serverUrl;
  final String username;
  final String password;
  final VoidCallback onTap;

  const VodTile({
    super.key,
    required this.item,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.onTap,
  });

  String get _logoUrl {
    if (item.streamIcon.isEmpty) return '';
    if (item.streamIcon.startsWith('http')) return item.streamIcon;
    final base = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return item.streamIcon.startsWith('/')
        ? '$base${item.streamIcon}'
        : '$base/${item.streamIcon}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 48.0;
    const radius = 10.0;
    return ListTile(
      leading: _logoUrl.isEmpty
          ? Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Icon(Icons.movie, color: theme.colorScheme.primary),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.network(
                _logoUrl,
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
                  child: Icon(Icons.movie, color: theme.colorScheme.primary),
                ),
              ),
            ),
      title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.play_circle_filled),
      onTap: onTap,
    );
  }
}
