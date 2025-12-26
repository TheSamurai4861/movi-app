import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/responsive/presentation/widgets/responsive_layout.dart';

/// Extension sur [BuildContext] pour faciliter l'accès aux informations responsive.
extension ResponsiveContext on BuildContext {
  /// Retourne le [ScreenType] actuel résolu par [ResponsiveLayout].
  ///
  /// Lance une exception si [ResponsiveLayout] n'est pas présent dans l'arbre.
  ScreenType get screenType => ResponsiveLayout.of(this);

  /// Retourne `true` si l'écran est de type mobile.
  bool get isMobile => screenType == ScreenType.mobile;

  /// Retourne `true` si l'écran est de type tablette.
  bool get isTablet => screenType == ScreenType.tablet;

  /// Retourne `true` si l'écran est de type desktop.
  bool get isDesktop => screenType == ScreenType.desktop;

  /// Retourne `true` si l'écran est de type TV.
  bool get isTv => screenType == ScreenType.tv;

  /// Sélectionne une valeur selon le type d'écran.
  ///
  /// Retourne la valeur correspondant au type d'écran actuel, ou `null`
  /// si aucune valeur n'est fournie pour ce type.
  ///
  /// Exemple :
  /// ```dart
  /// final padding = context.responsive<double>(
  ///   mobile: 16.0,
  ///   tablet: 24.0,
  ///   desktop: 32.0,
  /// );
  /// ```
  T? responsive<T>({
    T? mobile,
    T? tablet,
    T? desktop,
    T? tv,
  }) {
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
      case ScreenType.tv:
        return tv;
    }
  }
}

