import 'package:flutter/material.dart';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';

/// Explicit tracking toggle for TV series episode alerts.
///
/// Uses local SVG assets registered in [AppAssets] so the visual language stays
/// aligned with the rest of the design system and avoids inline SVG strings.
class MoviTrackSeriesButton extends StatefulWidget {
  const MoviTrackSeriesButton({
    super.key,
    required this.isTracked,
    required this.onPressed,
    this.focusNode,
    this.size = 35,
    this.iconSize = 36,
    this.filledAsset = AppAssets.iconBellFilled,
    this.unfilledAsset = AppAssets.iconBellUnfilled,
    this.filledColor = Colors.white,
    this.unfilledColor = Colors.white,
    this.focusedBackgroundColor,
    this.focusPadding = const EdgeInsets.all(0),
    this.focusedBorderColor,
    this.unfocusedBorderColor,
    this.borderWidth = 0,
  });

  final bool isTracked;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final double size;
  final double iconSize;
  final String filledAsset;
  final String unfilledAsset;
  final Color filledColor;
  final Color unfilledColor;
  final Color? focusedBackgroundColor;
  final EdgeInsetsGeometry focusPadding;
  final Color? focusedBorderColor;
  final Color? unfocusedBorderColor;
  final double borderWidth;

  @override
  State<MoviTrackSeriesButton> createState() => _MoviTrackSeriesButtonState();
}

class _MoviTrackSeriesButtonState extends State<MoviTrackSeriesButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 300);
    final focusedBg =
        widget.focusedBackgroundColor ?? Colors.black.withValues(alpha: 0.45);
    final effectiveFocusedBorder =
        widget.focusedBorderColor ?? Colors.transparent;
    final effectiveUnfocusedBorder =
        widget.unfocusedBorderColor ?? Colors.transparent;
    final backgroundColor = _focused ? focusedBg : Colors.transparent;

    return Semantics(
      button: true,
      toggled: widget.isTracked,
      label: widget.isTracked
          ? 'Désactiver le suivi des nouveaux épisodes'
          : 'Activer le suivi des nouveaux épisodes',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            focusNode: widget.focusNode,
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
                padding: widget.focusPadding,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(widget.size / 2),
                  border: Border.all(
                    color: _focused
                        ? effectiveFocusedBorder
                        : effectiveUnfocusedBorder,
                    width: widget.borderWidth,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedOpacity(
                      duration: duration,
                      curve: Curves.easeInOut,
                      opacity: widget.isTracked ? 0.0 : 1.0,
                      child: MoviAssetIcon(
                        widget.unfilledAsset,
                        width: widget.iconSize,
                        height: widget.iconSize,
                        color: widget.unfilledColor,
                      ),
                    ),
                    AnimatedOpacity(
                      duration: duration,
                      curve: Curves.easeInOut,
                      opacity: widget.isTracked ? 1.0 : 0.0,
                      child: MoviAssetIcon(
                        widget.filledAsset,
                        width: widget.iconSize,
                        height: widget.iconSize,
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
