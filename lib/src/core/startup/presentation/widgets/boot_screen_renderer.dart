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
  static const _fallbackRetryLabel = 'Reessayer';

  @override
  Widget build(BuildContext context) {
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
      return SingleChildScrollView(
        padding: recoveryPadding,
        child: recovery,
      );
    }

    final message = loadingMessageOverride ?? model.message;
    final child = switch (model.screenType) {
      BootScreenType.catalogLoading => BootCatalogLoadingScreen(
        message: message,
        secondaryMessage: catalogSecondaryMessage,
        showLogo: model.showLogo,
        showProgress: model.showProgress,
      ),
      BootScreenType.simpleLoading || BootScreenType.openingHome =>
        BootSimpleLoadingScreen.forBootModel(
          model,
          messageOverride: message,
        ),
      _ => BootSimpleLoadingScreen(
        message: message,
        showLogo: model.showLogo,
        showProgress: model.showProgress,
      ),
    };

    return Focus(focusNode: loadingFocusNode, child: child);
  }
}
