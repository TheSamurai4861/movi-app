import 'package:flutter/material.dart';

class TvDetailPage extends StatelessWidget {
  const TvDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Série TV')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 180,
                      width: 120,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(child: Icon(Icons.live_tv, size: 48)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Titre de la série',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '4 saisons • 48 épisodes',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            Chip(label: Text('Science-fiction')),
                            Chip(label: Text('Thriller')),
                            Chip(label: Text('En cours')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Pitch',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Présentation rapide de la série pour mettre en forme la page. Lorem ipsum '
                'dolor sit amet, consectetur adipiscing elit.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Episodes récents',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...List.generate(
                3,
                (index) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      child: Center(child: Text('S4E${index + 1}')),
                    ),
                    title: Text('Titre de l’épisode ${index + 1}'),
                    subtitle: const Text('Résumé rapide et date de diffusion'),
                    trailing: const Icon(Icons.play_arrow_rounded),
                    onTap: () {},
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Distribution',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(
                  6,
                  (index) => Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      child: Text('${index + 1}'),
                    ),
                    label: Text('Acteur ${index + 1}'),
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
