import 'package:movi/src/core/responsive/domain/entities/breakpoints.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';

/// Service de résolution du type d'écran basé sur les dimensions.
///
/// Logique métier pure, testable sans dépendances Flutter.
/// Détermine le type d'écran (mobile, tablet, desktop, tv) en fonction
/// de la largeur, hauteur et ratio d'aspect.
class ScreenTypeResolver {
  ScreenTypeResolver._();

  static final ScreenTypeResolver instance = ScreenTypeResolver._();

  /// Résout le type d'écran à partir des dimensions fournies.
  ///
  /// [width] : Largeur de l'écran en pixels logiques
  /// [height] : Hauteur de l'écran en pixels logiques
  ///
  /// Retourne le [ScreenType] correspondant aux dimensions.
  ScreenType resolve(double width, double height) {
    // Calcul du ratio d'aspect
    final aspectRatio = width / height;

    // Détection TV : très large écran avec ratio >= 16/9
    if (width > Breakpoints.desktopMax && aspectRatio >= Breakpoints.tvAspectRatio) {
      return ScreenType.tv;
    }

    // Détection desktop : largeur > tabletMax et <= desktopMax
    if (width > Breakpoints.tabletMax && width <= Breakpoints.desktopMax) {
      return ScreenType.desktop;
    }

    // Détection tablet : largeur > mobileMax et <= tabletMax
    if (width > Breakpoints.mobileMax && width <= Breakpoints.tabletMax) {
      return ScreenType.tablet;
    }

    // Par défaut : mobile (largeur <= mobileMax)
    return ScreenType.mobile;
  }
}

