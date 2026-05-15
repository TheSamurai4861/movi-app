import 'package:flutter/material.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';

/// Carte "Voir tout" alignée sur [MoviMediaCard] (largeur 150, poster 225).
/// Affiche un motif 2x2 stylisé et le libellé "Voir tout".
class SeeAllCard extends StatefulWidget {
  const SeeAllCard({
    super.key,
    required this.title,
    this.width = 150,
    this.posterHeight = 225,
    this.onTap,
    this.heroTag,
  });

  /// Titre utilisé pour les libellés d'accessibilité.
  final String title;
  final double width;
  final double posterHeight;
  final VoidCallback? onTap;
  final Object? heroTag;

  @override
  State<SeeAllCard> createState() => _SeeAllCardState();
}

class _SeeAllCardState extends State<SeeAllCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final uiScale = context.tvUiScale;
    final scaledWidth = widget.width * uiScale;
    final scaledPosterHeight = widget.posterHeight * uiScale;
    final focusRadius = 18.0 * uiScale;
    final cardTitleGap = 12.0 * uiScale;
    final focusBorderWidth = 2.0 * uiScale;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final seeAllLabel = l10n?.actionSeeAll ?? 'Voir tout';
    final textStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16 * uiScale,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.2,
        ) ??
        TextStyle(
          fontSize: 16 * uiScale,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.2,
        );

    return SizedBox(
      width: scaledWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(focusRadius),
          onTap: widget.onTap,
          onFocusChange: (focused) {
            if (_focused == focused) return;
            setState(() => _focused = focused);
          },
          child: AnimatedScale(
            scale: _focused ? 1.035 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.all(focusBorderWidth),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(focusRadius),
                    border: Border.all(
                      color: _focused
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: focusBorderWidth,
                    ),
                  ),
                  child: _buildPoster(
                    width: scaledWidth,
                    height: scaledPosterHeight,
                    uiScale: uiScale,
                  ),
                ),
                SizedBox(height: cardTitleGap),
                Semantics(
                  label: '$seeAllLabel ${widget.title}',
                  button: true,
                  child: Text(
                    seeAllLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster({
    required double width,
    required double height,
    required double uiScale,
  }) {
    final innerPadding = 12.0 * uiScale;
    final tileGap = 8.0 * uiScale;
    final tileRadius = 8.0 * uiScale;
    final container = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12 * uiScale),
        color: const Color(0xFF202020),
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPadding),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _miniTile(
                      Colors.white.withValues(alpha: 0.12),
                      tileRadius,
                    ),
                  ),
                  SizedBox(width: tileGap),
                  Expanded(
                    child: _miniTile(
                      Colors.white.withValues(alpha: 0.2),
                      tileRadius,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: tileGap),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _miniTile(
                      Colors.white.withValues(alpha: 0.16),
                      tileRadius,
                    ),
                  ),
                  SizedBox(width: tileGap),
                  Expanded(
                    child: _miniTile(
                      Colors.white.withValues(alpha: 0.08),
                      tileRadius,
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

  Widget _miniTile(Color color, double radius) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: color,
      ),
    );
  }
}
