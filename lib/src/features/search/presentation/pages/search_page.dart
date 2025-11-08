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
              const Expanded(child: _EmptyResultsPlaceholder()),
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

class _EmptyResultsPlaceholder extends StatelessWidget {
  const _EmptyResultsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'La recherche sera connectée aux données réelles prochainement.',
          style: context.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
