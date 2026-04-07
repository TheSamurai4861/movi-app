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
    this.size = 35,
    this.filledAsset = AppAssets.iconBellFilled,
    this.unfilledAsset = AppAssets.iconBellUnfilled,
    this.filledColor = Colors.white,
    this.unfilledColor = Colors.white,
  });

  final bool isTracked;
  final VoidCallback onPressed;
  final double size;
  final String filledAsset;
  final String unfilledAsset;
  final Color filledColor;
  final Color unfilledColor;

  @override
  State<MoviTrackSeriesButton> createState() => _MoviTrackSeriesButtonState();
}

class _MoviTrackSeriesButtonState extends State<MoviTrackSeriesButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 300);
    final backgroundColor = _focused
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.transparent;

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
                      opacity: widget.isTracked ? 0.0 : 1.0,
                      child: MoviAssetIcon(
                        widget.unfilledAsset,
                        width: 36,
                        height: 36,
                        color: widget.unfilledColor,
                      ),
                    ),
                    AnimatedOpacity(
                      duration: duration,
                      curve: Curves.easeInOut,
                      opacity: widget.isTracked ? 1.0 : 0.0,
                      child: MoviAssetIcon(
                        widget.filledAsset,
                        width: 36,
                        height: 36,
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
