import 'package:flutter/material.dart';

import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';

/// Favorite toggle button using asset images.
/// - Crossfades (opacity) between unfilled and filled stars in 300ms.
/// - Images are 36px, the tappable box is 35x35 to match spec.
/// - Triggers the provided [onPressed] callback when tapped.
class MoviFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  /// Optional custom asset paths. Defaults to AppAssets star icons.
  final String filledAsset;
  final String unfilledAsset;
  final Color filledColor;
  final Color unfilledColor;

  /// Size of the tappable area (width & height). Defaults to 35.
  final double size;
  final double iconSize;
  final Color? focusedBackgroundColor;
  final EdgeInsetsGeometry focusPadding;
  final Color? focusedBorderColor;
  final Color? unfocusedBorderColor;
  final double borderWidth;

  const MoviFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.filledAsset = AppAssets.iconStarFilled,
    this.unfilledAsset = AppAssets.iconStarUnfilled,
    this.filledColor = Colors.white,
    this.unfilledColor = Colors.white,
    this.size = 35,
    this.iconSize = 36,
    this.focusedBackgroundColor,
    this.focusPadding = const EdgeInsets.all(0),
    this.focusedBorderColor,
    this.unfocusedBorderColor,
    this.borderWidth = 0,
    this.focusNode,
  });

  @override
  State<MoviFavoriteButton> createState() => _MoviFavoriteButtonState();
}

class _MoviFavoriteButtonState extends State<MoviFavoriteButton> {
  bool _focused = false;

  EdgeInsetsGeometry _scaleInsets(EdgeInsetsGeometry insets, double scale) {
    if (insets is EdgeInsets) {
      return EdgeInsets.fromLTRB(
        insets.left * scale,
        insets.top * scale,
        insets.right * scale,
        insets.bottom * scale,
      );
    }
    if (insets is EdgeInsetsDirectional) {
      return EdgeInsetsDirectional.fromSTEB(
        insets.start * scale,
        insets.top * scale,
        insets.end * scale,
        insets.bottom * scale,
      );
    }
    return insets;
  }

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 300);
    final uiScale = context.tvUiScale;
    final scaledSize = widget.size * uiScale;
    final scaledIconSize = widget.iconSize * uiScale;
    final scaledPadding = _scaleInsets(widget.focusPadding, uiScale);
    final scaledBorderWidth = widget.borderWidth * uiScale;
    final focusedBg = widget.focusedBackgroundColor ?? const Color(0x80000000);
    final effectiveFocusedBorder =
        widget.focusedBorderColor ?? Colors.transparent;
    final effectiveUnfocusedBorder =
        widget.unfocusedBorderColor ?? Colors.transparent;
    final backgroundColor = _focused ? focusedBg : Colors.transparent;

    return Semantics(
      button: true,
      toggled: widget.isFavorite,
      label: widget.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      child: SizedBox(
        width: scaledSize,
        height: scaledSize,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            focusNode: widget.focusNode,
            onTap: widget.onPressed,
            onFocusChange: (focused) {
              if (_focused == focused) return;
              setState(() => _focused = focused);
            },
            borderRadius: BorderRadius.circular(scaledSize / 2),
            child: AnimatedScale(
              scale: _focused ? 1.05 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: scaledPadding,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(scaledSize / 2),
                  border: Border.all(
                    color: _focused
                        ? effectiveFocusedBorder
                        : effectiveUnfocusedBorder,
                    width: scaledBorderWidth,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedOpacity(
                      duration: duration,
                      curve: Curves.easeInOut,
                      opacity: widget.isFavorite ? 0.0 : 1.0,
                      child: MoviAssetIcon(
                        widget.unfilledAsset,
                        width: scaledIconSize,
                        height: scaledIconSize,
                        color: widget.unfilledColor,
                      ),
                    ),
                    AnimatedOpacity(
                      duration: duration,
                      curve: Curves.easeInOut,
                      opacity: widget.isFavorite ? 1.0 : 0.0,
                      child: MoviAssetIcon(
                        widget.filledAsset,
                        width: scaledIconSize,
                        height: scaledIconSize,
                        color: widget.filledColor,
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
