import 'package:flutter/material.dart';

import '../../../../core/utils/utils.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bibliothèque')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Text(
              'Votre vidéothèque',
              style: context.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Retrouvez toutes vos listes et contenus enregistrés.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _LibrarySection(
              title: 'Reprendre la lecture',
              subtitle: 'Continuez vos contenus inachevés.',
              icon: Icons.play_arrow_rounded,
              items: MockData.continueWatching,
            ),
            const SizedBox(height: AppSpacing.sm),
            _LibrarySection(
              title: 'Favoris',
              subtitle: 'Vos films et séries préférés en un clin d’œil.',
              icon: Icons.favorite_rounded,
              items: MockData.featuredMovies,
            ),
            const SizedBox(height: AppSpacing.sm),
            _LibrarySection(
              title: 'Playlists et sagas',
              subtitle: 'Organisez vos univers MOVI.',
              icon: Icons.playlist_add_check_rounded,
              items: MockData.playlists,
            ),
          ],
        ),
      ),
    );
  }
}

class _LibrarySection extends StatelessWidget {
  const _LibrarySection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      color: context.colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(
                      subtitle,
                      style: context.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: items
                          .take(3)
                          .map(
                            (item) => Chip(
                              label: Text(item),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
