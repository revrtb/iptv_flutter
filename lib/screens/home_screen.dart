import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'categories_screen.dart';
import 'vod_categories_screen.dart';
import 'series_categories_screen.dart';
import 'catch_up_screen.dart';

enum MenuItemType { liveTv, movies, series, catchUp }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IPTV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Do you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                context.read<AuthProvider>().logout();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          _MenuTile(
            title: 'LIVE TV',
            subtitle: 'Watch live channels',
            icon: Icons.live_tv,
            onTap: () => _navigate(context, MenuItemType.liveTv),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            title: 'MOVIES',
            subtitle: 'Video on demand',
            icon: Icons.movie,
            onTap: () => _navigate(context, MenuItemType.movies),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            title: 'SERIES',
            subtitle: 'TV series',
            icon: Icons.tv,
            onTap: () => _navigate(context, MenuItemType.series),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            title: 'CATCH UP',
            subtitle: 'Replay past broadcasts',
            icon: Icons.replay,
            onTap: () => _navigate(context, MenuItemType.catchUp),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, MenuItemType type) {
    switch (type) {
      case MenuItemType.liveTv:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const CategoriesScreen(),
          ),
        );
        break;
      case MenuItemType.movies:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const VodCategoriesScreen(),
          ),
        );
        break;
      case MenuItemType.series:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const SeriesCategoriesScreen(),
          ),
        );
        break;
      case MenuItemType.catchUp:
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const CatchUpScreen(),
          ),
        );
        break;
    }
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
