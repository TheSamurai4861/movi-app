import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:movi/src/core/utils/app_assets.dart';

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
  double get _fallbackIconSize =>
      (_effectiveWidth ?? _effectiveHeight ?? 24).toDouble();

  static final Map<String, Future<String>> _svgContentCache =
      <String, Future<String>>{};

  static bool isSvgAsset(String assetPath) =>
      assetPath.toLowerCase().endsWith('.svg');

  Future<String> _loadSvgContent() {
    return _svgContentCache.putIfAbsent(
      assetPath,
      () => rootBundle.loadString(assetPath),
    );
  }

  Widget _buildSvgFallback(BuildContext context) {
    if (assetPath == AppAssets.iconAppLogoSvg) {
      return Image.asset(
        AppAssets.iconAppIconPng,
        width: _effectiveWidth,
        height: _effectiveHeight,
        fit: fit,
        alignment: alignment,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        filterQuality: filterQuality,
        color: color,
        colorBlendMode: colorBlendMode,
        errorBuilder: (_, __, ___) => Icon(
          Icons.play_circle_fill_rounded,
          size: _fallbackIconSize,
          color: color,
        ),
      );
    }

    final iconData = switch (assetPath) {
      AppAssets.iconStarFilled => Icons.star_rounded,
      AppAssets.iconStar ||
      AppAssets.iconStarUnfilled => Icons.star_border_rounded,
      _ => Icons.broken_image_outlined,
    };

    final fallbackIcon = Icon(iconData, size: _fallbackIconSize, color: color);

    if (excludeFromSemantics ||
        semanticLabel == null ||
        semanticLabel!.trim().isEmpty) {
      return fallbackIcon;
    }

    return Semantics(label: semanticLabel, child: fallbackIcon);
  }

  @override
  Widget build(BuildContext context) {
    if (isSvgAsset(assetPath)) {
      return FutureBuilder<String>(
        future: _loadSvgContent(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SvgPicture.string(
              snapshot.data!,
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

          if (snapshot.hasError) {
            return _buildSvgFallback(context);
          }

          return SizedBox(width: _effectiveWidth, height: _effectiveHeight);
        },
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
