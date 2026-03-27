import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a local asset icon from either an SVG or a raster file.
///
/// The widget selects the appropriate underlying renderer from the asset
/// extension and exposes a single API for shared UI icons.
class MoviAssetIcon extends StatelessWidget {
  const MoviAssetIcon(
    this.assetPath, {
    super.key,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode = BlendMode.srcIn,
    this.semanticLabel,
    this.excludeFromSemantics = true,
    this.filterQuality = FilterQuality.medium,
  });

  final String assetPath;
  final double? size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final Color? color;
  final BlendMode colorBlendMode;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final FilterQuality filterQuality;

  double? get _effectiveWidth => width ?? size;
  double? get _effectiveHeight => height ?? size;

  static bool isSvgAsset(String assetPath) =>
      assetPath.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (isSvgAsset(assetPath)) {
      return SvgPicture.asset(
        assetPath,
        width: _effectiveWidth,
        height: _effectiveHeight,
        fit: fit,
        alignment: alignment,
        semanticsLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color!, colorBlendMode),
      );
    }

    return Image.asset(
      assetPath,
      width: _effectiveWidth,
      height: _effectiveHeight,
      fit: fit,
      alignment: alignment,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      filterQuality: filterQuality,
      color: color,
      colorBlendMode: colorBlendMode,
    );
  }
}
