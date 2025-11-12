import 'package:flutter/material.dart';

import 'package:movi/src/core/utils/app_assets.dart';

/// Favorite toggle button using asset images.
/// - Crossfades (opacity) between unfilled and filled stars in 300ms.
/// - Images are 36px, the tappable box is 35x35 to match spec.
/// - Triggers the provided [onPressed] callback when tapped.
class MoviFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  /// Optional custom asset paths. Defaults to AppAssets star icons.
  final String filledAsset;
  final String unfilledAsset;

  /// Size of the tappable area (width & height). Defaults to 35.
  final double size;

  const MoviFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.filledAsset = AppAssets.iconStarFilled,
    this.unfilledAsset = AppAssets.iconStarUnfilled,
    this.size = 35,
  });

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 300);

    return Semantics(
      button: true,
      toggled: isFavorite,
      label: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size / 2),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Unfilled star (visible when not favorite)
                AnimatedOpacity(
                  duration: duration,
                  curve: Curves.easeInOut,
                  opacity: isFavorite ? 0.0 : 1.0,
                  child: Image.asset(
                    unfilledAsset,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
                // Filled star (visible when favorite)
                AnimatedOpacity(
                  duration: duration,
                  curve: Curves.easeInOut,
                  opacity: isFavorite ? 1.0 : 0.0,
                  child: Image.asset(
                    filledAsset,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
