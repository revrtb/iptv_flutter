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
    return ListTile(
      leading: _logoUrl.isEmpty
          ? CircleAvatar(
              child: Icon(Icons.movie, color: Theme.of(context).colorScheme.onPrimary),
            )
          : CircleAvatar(
              child: ClipOval(
                child: Image.network(
                  _logoUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.movie,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
      title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.play_circle_filled),
      onTap: onTap,
    );
  }
}
