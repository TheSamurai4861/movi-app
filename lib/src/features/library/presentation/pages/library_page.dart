import 'package:flutter/material.dart';

import '../../../../core/utils/utils.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bibliothèque')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Votre vidéothèque', style: context.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Les données seront affichées lorsque la couche data/domain sera implémentée.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Center(
                  child: Text(
                    'Aucun contenu disponible pour le moment.',
                    style: context.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
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
