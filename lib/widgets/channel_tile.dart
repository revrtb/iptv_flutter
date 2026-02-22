import 'package:flutter/material.dart';

import '../models/live_stream.dart';

class ChannelTile extends StatelessWidget {
  final LiveStream stream;
  final String serverUrl;
  final String username;
  final String password;
  final VoidCallback onTap;

  const ChannelTile({
    super.key,
    required this.stream,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.onTap,
  });

  String get _logoUrl {
    if (stream.streamIcon.isEmpty) return '';
    if (stream.streamIcon.startsWith('http')) {
      return stream.streamIcon;
    }
    final base = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return stream.streamIcon.startsWith('/')
        ? '$base${stream.streamIcon}'
        : '$base/${stream.streamIcon}';
  }

  Widget _buildLeading(BuildContext context) {
    if (_logoUrl.isEmpty) {
      return CircleAvatar(
        child: Icon(
          Icons.live_tv,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }
    return CircleAvatar(
      child: ClipOval(
        child: Image.network(
          _logoUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.live_tv,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeading(context),
      title: Text(
        stream.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.play_circle_filled),
      onTap: onTap,
    );
  }
}
