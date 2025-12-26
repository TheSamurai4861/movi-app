import 'package:flutter/material.dart';
import 'package:movi/src/features/category_browser/presentation/models/category_args.dart';

/// Carte "Voir tout" alignée sur MoviMediaCard (largeur 150).
/// Affiche un motif 2x2 stylisé et le libellé "Voir tout".
class SeeAllCard extends StatelessWidget {
  const SeeAllCard({
    super.key,
    required this.title,
    required this.categoryKey,
    this.width = 150,
    this.posterHeight = 225,
    this.onTap,
    this.heroTag,
  });

  /// Titre lisible (catégorie sans alias serveur)
  final String title;

  /// Clé complète de catégorie: `<alias>/<categorie>`
  final String categoryKey;
  final double width;
  final double posterHeight;
  final ValueChanged<CategoryPageArgs>? onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = CategoryPageArgs(title: title, categoryKey: categoryKey);
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTap?.call(args),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Affiche un poster stylisé avec 4 blocs (2x2)
              _buildPoster(context),
              const SizedBox(height: 12),
              Semantics(
                label: 'Voir tout $title',
                button: true,
                child: Text(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context) {
    final container = Container(
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
    );

    if (heroTag == null) return container;
    return Hero(tag: heroTag!, child: container);
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
