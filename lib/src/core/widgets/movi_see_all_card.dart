import 'package:flutter/material.dart';
import 'package:movi/src/features/category_browser/presentation/models/category_args.dart';

/// Carte "Voir tout" alignée sur MoviMediaCard (largeur 150).
/// Affiche un motif 2x2 stylisé et le libellé "Voir tout".
class SeeAllCard extends StatefulWidget {
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
  State<SeeAllCard> createState() => _SeeAllCardState();
}

class _SeeAllCardState extends State<SeeAllCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = CategoryPageArgs(
      title: widget.title,
      categoryKey: widget.categoryKey,
    );
    return SizedBox(
      width: widget.width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onTap?.call(args),
          onFocusChange: (focused) {
            if (_focused == focused) return;
            setState(() => _focused = focused);
          },
          child: AnimatedScale(
            scale: _focused ? 1.03 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _focused
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: _buildPoster(context),
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'Voir tout ${widget.title}',
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
      ),
    );
  }

  Widget _buildPoster(BuildContext context) {
    final container = Container(
      height: widget.posterHeight,
      width: widget.width,
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

    if (widget.heroTag == null) return container;
    return Hero(tag: widget.heroTag!, child: container);
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
