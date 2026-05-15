import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_form_tokens.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';

/// Panneau boot actionnable : titre, message, sous-message optionnel, jusqu’à
/// deux actions. Aucun [reasonCode] ne doit être affiché en clair.
class BootRecoveryPanel extends StatelessWidget {
  BootRecoveryPanel({
    super.key,
    this.title,
    required this.message,
    this.secondaryMessage,
    required this.severity,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryFocusNode,
    this.secondaryFocusNode,
    this.primaryAutofocus = true,
    this.details,
    this.showDetails = false,
  }) : assert(primaryLabel.trim().isNotEmpty),
       assert(
         secondaryLabel == null ||
             (secondaryLabel.trim().isNotEmpty && onSecondary != null),
       );

  factory BootRecoveryPanel.fromBootModel({
    required BootScreenModel model,
    required void Function(BootActionIntent intent) onAction,
    required FocusNode primaryFocusNode,
    FocusNode? secondaryFocusNode,
  }) {
    assert(model.isInteractive, 'BootRecoveryPanel.fromBootModel: non interactif');
    assert(
      model.primaryAction != null && model.primaryActionLabel != null,
      'BootRecoveryPanel.fromBootModel: action principale manquante',
    );
    return BootRecoveryPanel(
      title: model.title,
      message: model.message,
      secondaryMessage: model.secondaryMessage,
      severity: model.severity,
      primaryLabel: model.primaryActionLabel!,
      onPrimary: () => onAction(model.primaryAction!),
      secondaryLabel: model.secondaryActionLabel,
      onSecondary: model.secondaryAction == null
          ? null
          : () => onAction(model.secondaryAction!),
      primaryFocusNode: primaryFocusNode,
      secondaryFocusNode: secondaryFocusNode,
      primaryAutofocus: model.initialFocus == BootFocusTarget.primaryAction,
    );
  }

  final String? title;
  final String message;
  final String? secondaryMessage;
  final BootScreenSeverity severity;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final FocusNode? primaryFocusNode;
  final FocusNode? secondaryFocusNode;
  final bool primaryAutofocus;
  final String? details;
  final bool showDetails;

  static const int _detailsMaxChars = 300;
  static const int _detailsMaxLines = 4;
  static const double _maxActionWidth = BootFormTokens.primaryActionMaxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detailsText = _truncateDetails(details);
    final showDetailsText = showDetails && detailsText != null;
    final titleText = title?.trim();
    final hasTitle = titleText != null && titleText.isNotEmpty;
    final secondary = secondaryMessage?.trim();

    final Color? accent = switch (severity) {
      BootScreenSeverity.error => scheme.error,
      BootScreenSeverity.warning => scheme.tertiary,
      BootScreenSeverity.info => null,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxOuterWidth = !constraints.maxWidth.isFinite
            ? BootFormTokens.textFieldMaxWidth
            : math.min(BootFormTokens.textFieldMaxWidth, constraints.maxWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxOuterWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (accent != null) ...[
                      Icon(
                        severity == BootScreenSeverity.error
                            ? Icons.error_outline
                            : Icons.warning_amber_rounded,
                        color: accent,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (hasTitle)
                      Text(
                        titleText,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (hasTitle) const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      maxLines: 12,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    if (secondary != null && secondary.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        secondary,
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (showDetailsText) ...[
                      const SizedBox(height: 12),
                      Text(
                        detailsText,
                        textAlign: TextAlign.center,
                        maxLines: _detailsMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(1),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _maxActionWidth,
                        ),
                        child: MoviPrimaryButton(
                          label: primaryLabel,
                          onPressed: onPrimary,
                          focusNode: primaryFocusNode,
                          autofocus: primaryAutofocus,
                          buttonStyle:
                              BootFormTokens.bootPrimaryButtonStyle(theme),
                        ),
                      ),
                    ),
                    if (secondaryLabel != null && onSecondary != null) ...[
                      const SizedBox(height: 12),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(2),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxActionWidth,
                          ),
                          child: TextButton(
                            focusNode: secondaryFocusNode,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(
                                48,
                                BootFormTokens.primaryActionHeight,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  BootFormTokens.borderRadius,
                                ),
                              ),
                            ),
                            onPressed: onSecondary,
                            child: Text(
                              secondaryLabel!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _truncateDetails(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= _detailsMaxChars) return trimmed;
    return '${trimmed.substring(0, _detailsMaxChars)}...';
  }
}
