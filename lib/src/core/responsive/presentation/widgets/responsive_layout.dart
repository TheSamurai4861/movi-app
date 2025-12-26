import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';

/// Widget qui fournit le type d'écran résolu dans l'arbre de widgets.
///
/// Utilise [LayoutBuilder] pour obtenir les dimensions et [ScreenTypeResolver]
/// pour déterminer le type d'écran. Expose le [ScreenType] via [ResponsiveLayout.of].
///
/// Permet également de fournir des builders spécifiques par type d'écran.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
    this.tv,
  });

  /// Widget enfant par défaut (utilisé si aucun builder spécifique n'est fourni).
  final Widget child;

  /// Builder optionnel pour les écrans mobiles.
  final WidgetBuilder? mobile;

  /// Builder optionnel pour les tablettes.
  final WidgetBuilder? tablet;

  /// Builder optionnel pour les écrans desktop.
  final WidgetBuilder? desktop;

  /// Builder optionnel pour les écrans TV.
  final WidgetBuilder? tv;

  /// Récupère le [ScreenType] depuis le contexte.
  ///
  /// Lance une exception si [ResponsiveLayout] n'est pas présent dans l'arbre.
  static ScreenType of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_ResponsiveLayoutData>();
    assert(inherited != null, 'ResponsiveLayout.of() called with a context that does not contain a ResponsiveLayout');
    return inherited!.screenType;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final screenType = ScreenTypeResolver.instance.resolve(width, height);

        Widget content;
        switch (screenType) {
          case ScreenType.mobile:
            content = mobile?.call(context) ?? child;
            break;
          case ScreenType.tablet:
            content = tablet?.call(context) ?? child;
            break;
          case ScreenType.desktop:
            content = desktop?.call(context) ?? child;
            break;
          case ScreenType.tv:
            content = tv?.call(context) ?? child;
            break;
        }

        return _ResponsiveLayoutData(
          screenType: screenType,
          child: content,
        );
      },
    );
  }
}

/// [InheritedWidget] qui expose le [ScreenType] dans l'arbre de widgets.
class _ResponsiveLayoutData extends InheritedWidget {
  const _ResponsiveLayoutData({
    required this.screenType,
    required super.child,
  });

  final ScreenType screenType;

  @override
  bool updateShouldNotify(_ResponsiveLayoutData oldWidget) {
    return screenType != oldWidget.screenType;
  }
}

