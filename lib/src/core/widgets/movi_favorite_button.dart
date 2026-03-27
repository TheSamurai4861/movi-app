import 'package:flutter/material.dart';

import 'package:movi/src/core/utils/app_assets.dart';

/// Favorite toggle button using asset images.
/// - Crossfades (opacity) between unfilled and filled stars in 300ms.
/// - Images are 36px, the tappable box is 35x35 to match spec.
/// - Triggers the provided [onPressed] callback when tapped.
class MoviFavoriteButton extends StatefulWidget {
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
  State<MoviFavoriteButton> createState() => _MoviFavoriteButtonState();
}

class _MoviFavoriteButtonState extends State<MoviFavoriteButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 300);
    final backgroundColor = _focused
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.transparent;

    return Semantics(
      button: true,
      toggled: widget.isFavorite,
      label: widget.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onPressed,
            onFocusChange: (focused) {
              if (_focused == focused) return;
              setState(() => _focused = focused);
            },
            borderRadius: BorderRadius.circular(widget.size / 2),
            child: AnimatedScale(
              scale: _focused ? 1.05 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(widget.size / 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedOpacity(
                      duration: duration,
                      curve: Curves.easeInOut,
                      opacity: widget.isFavorite ? 0.0 : 1.0,
                      child: Image.asset(
                        widget.unfilledAsset,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                    AnimatedOpacity(
                      duration: duration,
                      curve: Curves.easeInOut,
                      opacity: widget.isFavorite ? 1.0 : 0.0,
                      child: Image.asset(
                        widget.filledAsset,
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
        ),
      ),
    );
  }
}
