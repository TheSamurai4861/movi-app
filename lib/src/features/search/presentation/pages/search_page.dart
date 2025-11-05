import 'package:flutter/material.dart';

import '../../../../core/utils/utils.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Film, série, artiste…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                children: const [
                  _SearchFilterChip(label: 'Films'),
                  _SearchFilterChip(label: 'Séries'),
                  _SearchFilterChip(label: 'Personnes'),
                  _SearchFilterChip(label: 'Playlists'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: MockData.featuredMovies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.colorScheme.surfaceContainerHighest,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(MockData.featuredMovies[index]),
                    subtitle: const Text('Résultat mock – contenu réel à venir'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchFilterChip extends StatelessWidget {
  const _SearchFilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      onSelected: (_) {},
    );
  }
}
