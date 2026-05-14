import 'package:flutter/material.dart';

import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_recovery_panel.dart';

class LaunchErrorPanel extends StatelessWidget {
  const LaunchErrorPanel({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.details,
    this.showDetails = false,
    this.retryFocusNode,
    this.retryAutofocus = false,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? details;
  final bool showDetails;
  final FocusNode? retryFocusNode;
  final bool retryAutofocus;

  @override
  Widget build(BuildContext context) {
    return BootRecoveryPanel(
      message: message,
      severity: BootScreenSeverity.error,
      primaryLabel: retryLabel,
      onPrimary: onRetry,
      primaryFocusNode: retryFocusNode,
      primaryAutofocus: retryAutofocus,
      details: details,
      showDetails: showDetails,
    );
  }
}
