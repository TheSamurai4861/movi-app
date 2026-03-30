import 'package:flutter/material.dart';

@immutable
class MoviHeroOverlaySpec {
  const MoviHeroOverlaySpec({
    required this.topHeightRatio,
    required this.bottomHeightRatio,
    required this.globalTintOpacity,
    required this.topStops,
    required this.topOpacities,
    required this.bottomStops,
    required this.bottomOpacities,
    this.showGlobalTint = true,
    this.showTopFade = true,
    this.showBottomFade = true,
    this.sideFadeEnabled = false,
  }) : assert(topHeightRatio >= 0),
       assert(bottomHeightRatio >= 0),
       assert(globalTintOpacity >= 0 && globalTintOpacity <= 1);

  static const double _homeWideTopRatio = 150 / 628;
  static const double _homeWideBottomRatio = 278 / 628;
  static const double _detailWideTopRatio = 120 / 520;
  static const double _detailWideBottomRatio = 240 / 520;

  static const MoviHeroOverlaySpec homeMobile = MoviHeroOverlaySpec(
    topHeightRatio: 1 / 3,
    bottomHeightRatio: 1 / 3,
    globalTintOpacity: 26 / 255,
    topStops: [0.0, 0.22, 0.5, 0.78, 1.0],
    topOpacities: [1.0, 0.92, 0.58, 0.18, 0.0],
    bottomStops: [0.0, 0.16, 0.34, 0.56, 0.78, 1.0],
    bottomOpacities: [0.10, 0.18, 0.30, 0.48, 0.72, 1.0],
  );

  static const MoviHeroOverlaySpec homeWide = MoviHeroOverlaySpec(
    topHeightRatio: _homeWideTopRatio,
    bottomHeightRatio: _homeWideBottomRatio,
    globalTintOpacity: 26 / 255,
    topStops: [0.0, 1.0],
    topOpacities: [1.0, 0.0],
    bottomStops: [0.0, 0.22, 0.46, 0.68, 0.84, 1.0],
    bottomOpacities: [0.0, 0.04, 0.12, 0.28, 0.58, 1.0],
    sideFadeEnabled: true,
  );

  static const MoviHeroOverlaySpec homeMobileBottomOnly = MoviHeroOverlaySpec(
    topHeightRatio: 1 / 3,
    bottomHeightRatio: 1 / 3,
    globalTintOpacity: 26 / 255,
    topStops: [0.0, 0.22, 0.5, 0.78, 1.0],
    topOpacities: [1.0, 0.92, 0.58, 0.18, 0.0],
    bottomStops: [0.0, 0.16, 0.34, 0.56, 0.78, 1.0],
    bottomOpacities: [0.10, 0.18, 0.30, 0.48, 0.72, 1.0],
    showGlobalTint: false,
    showTopFade: false,
    sideFadeEnabled: false,
  );

  static const MoviHeroOverlaySpec homeWideBottomOnly = MoviHeroOverlaySpec(
    topHeightRatio: _homeWideTopRatio,
    bottomHeightRatio: _homeWideBottomRatio,
    globalTintOpacity: 26 / 255,
    topStops: [0.0, 1.0],
    topOpacities: [1.0, 0.0],
    bottomStops: [0.0, 0.22, 0.46, 0.68, 0.84, 1.0],
    bottomOpacities: [0.0, 0.04, 0.12, 0.28, 0.58, 1.0],
    showGlobalTint: false,
    showTopFade: false,
    sideFadeEnabled: false,
  );

  static const MoviHeroOverlaySpec mobileDense = homeMobile;
  static const MoviHeroOverlaySpec wide = homeWide;

  static const MoviHeroOverlaySpec detailMobile = MoviHeroOverlaySpec(
    topHeightRatio: 100 / 400,
    bottomHeightRatio: 200 / 400,
    globalTintOpacity: 0,
    topStops: [0.0, 1.0],
    topOpacities: [1.0, 0.0],
    bottomStops: [0.0, 0.22, 0.46, 0.68, 0.84, 1.0],
    bottomOpacities: [0.0, 0.04, 0.12, 0.28, 0.58, 1.0],
    showGlobalTint: false,
  );

  static const MoviHeroOverlaySpec detailWide = MoviHeroOverlaySpec(
    topHeightRatio: _detailWideTopRatio,
    bottomHeightRatio: _detailWideBottomRatio,
    globalTintOpacity: 0,
    topStops: [0.0, 1.0],
    topOpacities: [1.0, 0.0],
    bottomStops: [0.0, 0.22, 0.46, 0.68, 0.84, 1.0],
    bottomOpacities: [0.0, 0.04, 0.12, 0.28, 0.58, 1.0],
    showGlobalTint: false,
    sideFadeEnabled: true,
  );

  final double topHeightRatio;
  final double bottomHeightRatio;
  final double globalTintOpacity;
  final List<double> topStops;
  final List<double> topOpacities;
  final List<double> bottomStops;
  final List<double> bottomOpacities;
  final bool showGlobalTint;
  final bool showTopFade;
  final bool showBottomFade;
  final bool sideFadeEnabled;

  static MoviHeroOverlaySpec home({required bool isWideLayout}) {
    return isWideLayout ? homeWide : homeMobile;
  }

  static MoviHeroOverlaySpec homeBottomOnly({required bool isWideLayout}) {
    return isWideLayout ? homeWideBottomOnly : homeMobileBottomOnly;
  }

  static MoviHeroOverlaySpec detail({required bool isWideLayout}) {
    return isWideLayout ? detailWide : detailMobile;
  }

  double topHeightFor(double imageHeight) => imageHeight * topHeightRatio;

  double bottomHeightFor(double imageHeight) => imageHeight * bottomHeightRatio;

  MoviHeroOverlaySpec copyWith({
    double? topHeightRatio,
    double? bottomHeightRatio,
    double? globalTintOpacity,
    List<double>? topStops,
    List<double>? topOpacities,
    List<double>? bottomStops,
    List<double>? bottomOpacities,
    bool? showGlobalTint,
    bool? showTopFade,
    bool? showBottomFade,
    bool? sideFadeEnabled,
  }) {
    return MoviHeroOverlaySpec(
      topHeightRatio: topHeightRatio ?? this.topHeightRatio,
      bottomHeightRatio: bottomHeightRatio ?? this.bottomHeightRatio,
      globalTintOpacity: globalTintOpacity ?? this.globalTintOpacity,
      topStops: topStops ?? this.topStops,
      topOpacities: topOpacities ?? this.topOpacities,
      bottomStops: bottomStops ?? this.bottomStops,
      bottomOpacities: bottomOpacities ?? this.bottomOpacities,
      showGlobalTint: showGlobalTint ?? this.showGlobalTint,
      showTopFade: showTopFade ?? this.showTopFade,
      showBottomFade: showBottomFade ?? this.showBottomFade,
      sideFadeEnabled: sideFadeEnabled ?? this.sideFadeEnabled,
    );
  }
}

/// Shared gradients for hero overlays.
///
/// The bottom fade uses multiple stops so the image stays readable longer
/// before merging into the page background near the lower edge.
class MoviHeroGradients {
  const MoviHeroGradients._();

  static LinearGradient topFade(
    Color color, {
    required MoviHeroOverlaySpec spec,
  }) {
    return _verticalFade(
      color,
      stops: spec.topStops,
      opacities: spec.topOpacities,
    );
  }

  static LinearGradient bottomFade(Color color, {MoviHeroOverlaySpec? spec}) {
    final effective = spec ?? MoviHeroOverlaySpec.wide;
    return _verticalFade(
      color,
      stops: effective.bottomStops,
      opacities: effective.bottomOpacities,
    );
  }

  static LinearGradient leadingSideFade(Color color) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: const [0.0, 0.42, 0.82],
      colors: [
        color,
        color.withValues(alpha: 0.72),
        color.withValues(alpha: 0.0),
      ],
    );
  }

  static LinearGradient trailingSideFade(Color color) {
    return LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      stops: const [0.0, 0.16, 0.34],
      colors: [
        color.withValues(alpha: 0.28),
        color.withValues(alpha: 0.12),
        color.withValues(alpha: 0.0),
      ],
    );
  }

  static LinearGradient _verticalFade(
    Color color, {
    required List<double> stops,
    required List<double> opacities,
  }) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: stops,
      colors: [for (final alpha in opacities) color.withValues(alpha: alpha)],
    );
  }
}
