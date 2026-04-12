import 'package:flutter/material.dart';

import 'package:movi/src/core/widgets/movi_hero_gradients.dart';

/// Shared hero overlays rendered above the background image.
class MoviHeroOverlays extends StatelessWidget {
  const MoviHeroOverlays({
    super.key,
    required this.imageHeight,
    required this.spec,
  });

  final double imageHeight;
  final MoviHeroOverlaySpec spec;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final topHeight = spec.topHeightFor(imageHeight);
    final bottomHeight = spec.bottomHeightFor(imageHeight);

    return IgnorePointer(
      ignoring: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (spec.showGlobalTint)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: spec.globalTintOpacity),
                ),
              ),
            ),
          if (spec.showTopFade && topHeight > 0)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SizedBox(
                height: topHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: MoviHeroGradients.topFade(surface, spec: spec),
                  ),
                ),
              ),
            ),
          if (spec.showBottomFade && bottomHeight > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              child: SizedBox(
                height: bottomHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: MoviHeroGradients.bottomFade(surface, spec: spec),
                  ),
                ),
              ),
            ),
          if (spec.sideFadeEnabled)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: MoviHeroGradients.leadingSideFade(surface),
                ),
              ),
            ),
          if (spec.sideFadeEnabled)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: MoviHeroGradients.trailingSideFade(surface),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
