import 'package:flutter/material.dart';

import 'package:movi/src/core/widgets/movi_hero_gradients.dart';
import 'package:movi/src/core/widgets/movi_hero_overlays.dart';

/// Shared hero scene that guarantees a stable render order:
/// background -> overlays -> content.
class MoviHeroScene extends StatelessWidget {
  const MoviHeroScene({
    super.key,
    required this.background,
    required this.imageHeight,
    required this.overlaySpec,
    this.children = const <Widget>[],
  });

  final Widget background;
  final double imageHeight;
  final MoviHeroOverlaySpec overlaySpec;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: background),
        Positioned.fill(
          child: MoviHeroOverlays(
            imageHeight: imageHeight,
            spec: overlaySpec,
          ),
        ),
        ...children,
      ],
    );
  }
}
