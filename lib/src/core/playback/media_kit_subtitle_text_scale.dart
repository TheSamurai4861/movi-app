import 'dart:math' as math;

/// Facteur d’échelle linéaire des sous-titres aligné sur [SubtitleView] de
/// `media_kit_video` (référence projet : `media_kit_video: ^2.0.0` dans
/// pubspec). Lors d’un upgrade majeur du package, comparer avec
/// `lib/src/subtitle/subtitle_view.dart` (constantes 1920×1080 et usage de
/// `sqrt((nr/dr).clamp(0, 1))`).
///
/// Centralisé ici pour tests déterministes sans dépendre du SDK lecteur dans
/// la couche UI.
class MediaKitSubtitleTextScale {
  MediaKitSubtitleTextScale._();

  /// Même référence que `SubtitleViewState.kTextScaleFactorReferenceWidth`.
  static const double kMediaKitSubtitleReferenceWidth = 1920.0;

  /// Même référence que `SubtitleViewState.kTextScaleFactorReferenceHeight`.
  static const double kMediaKitSubtitleReferenceHeight = 1080.0;

  static double _referenceArea() =>
      kMediaKitSubtitleReferenceWidth * kMediaKitSubtitleReferenceHeight;

  /// Retourne le facteur passé à `TextScaler.linear` côté media_kit pour une
  /// zone sous-titres de [layoutWidth] × [layoutHeight] (pixels logiques).
  ///
  /// Aire nulle ou négative : `0.0` (pas de texte utile ; évite NaN sur sqrt).
  static double linearFactor({
    required double layoutWidth,
    required double layoutHeight,
  }) {
    final nr = layoutWidth * layoutHeight;
    if (nr <= 0) return 0.0;
    final ratio = (nr / _referenceArea()).clamp(0.0, 1.0);
    return math.sqrt(ratio);
  }
}
