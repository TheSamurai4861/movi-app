import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/features/category_browser/presentation/models/category_args.dart';
import 'package:movi/src/core/router/router.dart';

/// Carte "Voir tout" alignée sur MoviMediaCard (largeur 150).
/// Affiche un motif 2x2 stylisé et le libellé "Voir tout".
class SeeAllCard extends StatelessWidget {
  const SeeAllCard({
    super.key,
    required this.title,
    required this.categoryKey,
    this.width = 150,
    this.posterHeight = 225,
  });

  /// Titre lisible (catégorie sans alias serveur)
  final String title;

  /// Clé complète de catégorie: `<alias>/<categorie>`
  final String categoryKey;
  final double width;
  final double posterHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final args = CategoryPageArgs(title: title, categoryKey: categoryKey);
          context.push(AppRouteNames.category, extra: args);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affiche un poster stylisé avec 4 blocs (2x2)
            Container(
              height: posterHeight,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF202020),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _miniTile(
                              context,
                              Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _miniTile(
                              context,
                              Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _miniTile(
                              context,
                              Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _miniTile(
                              context,
                              Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Voir tout',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ) ??
                  const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTile(BuildContext context, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color,
      ),
    );
  }
}
