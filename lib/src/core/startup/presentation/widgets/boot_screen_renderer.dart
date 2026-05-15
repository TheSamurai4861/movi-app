import 'package:flutter/material.dart';

import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_catalog_loading_screen.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_recovery_panel.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_simple_loading_screen.dart';

/// Renderer presentation-only pour le tunnel boot.
///
/// Ce widget ne lit aucun provider et n'orchestre aucune navigation.
/// Il consomme uniquement un [BootScreenModel] et remonte les intentions
/// utilisateur via [onAction].
class BootScreenRenderer extends StatelessWidget {
  const BootScreenRenderer({
    super.key,
    required this.model,
    required this.primaryActionFocusNode,
    this.forceRecovery = false,
    this.onAction,
    this.loadingMessageOverride,
    this.catalogSecondaryMessage,
    this.loadingFocusNode,
    this.secondaryActionFocusNode,
    this.recoveryPadding = const EdgeInsets.symmetric(vertical: 24),
  });

  final BootScreenModel model;

  /// Force le rendu recovery meme pour un [model] non interactif
  /// (utile si un état d'erreur runtime est présent).
  final bool forceRecovery;

  final ValueChanged<BootActionIntent>? onAction;
  final String? loadingMessageOverride;
  final String? catalogSecondaryMessage;
  final FocusNode? loadingFocusNode;
  final FocusNode primaryActionFocusNode;
  final FocusNode? secondaryActionFocusNode;
  final EdgeInsetsGeometry recoveryPadding;

  bool get _showRecovery => forceRecovery || model.isInteractive;
  static const _fallbackRetryLabel = 'Retry';
  static const _fadeDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final Widget surface;
    if (_showRecovery) {
      final recovery = model.isInteractive
          ? BootRecoveryPanel.fromBootModel(
              model: model,
              onAction: onAction ?? (_) {},
              primaryFocusNode: primaryActionFocusNode,
              secondaryFocusNode: model.secondaryAction != null
                  ? secondaryActionFocusNode
                  : null,
            )
          : BootRecoveryPanel(
              message: model.message,
              severity: model.severity,
              primaryLabel: _fallbackRetryLabel,
              onPrimary: () => onAction?.call(BootActionIntent.retry),
              primaryFocusNode: primaryActionFocusNode,
              primaryAutofocus: true,
            );
      surface = SingleChildScrollView(
        key: const ValueKey<String>('boot-surface-recovery'),
        padding: recoveryPadding,
        child: recovery,
      );
    } else {
      final message = loadingMessageOverride ?? model.message;
      final loadingChild = switch (model.screenType) {
        BootScreenType.catalogLoading => BootCatalogLoadingScreen(
          message: message,
          secondaryMessage: catalogSecondaryMessage,
          showLogo: model.showLogo,
          showProgress: model.showProgress,
        ),
        BootScreenType.simpleLoading || BootScreenType.openingHome =>
          BootSimpleLoadingScreen.forBootModel(model, messageOverride: message),
        _ => BootSimpleLoadingScreen(
          message: message,
          showLogo: model.showLogo,
          showProgress: model.showProgress,
        ),
      };

      surface = KeyedSubtree(
        key: const ValueKey<String>('boot-surface-loading'),
        child: Focus(
          focusNode: loadingFocusNode,
          child: AnimatedSwitcher(
            duration: _fadeDuration,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: _fadeTransition,
            child: KeyedSubtree(
              key: ValueKey<String>(_loadingTransitionKey),
              child: loadingChild,
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: _fadeDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: _fadeTransition,
      child: surface,
    );
  }

  String get _loadingTransitionKey {
    return switch (model.screenType) {
      BootScreenType.catalogLoading => 'boot-loading-catalog',
      BootScreenType.openingHome => 'boot-loading-opening-home',
      _ => 'boot-loading-simple',
    };
  }

  static Widget _fadeTransition(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }
}
