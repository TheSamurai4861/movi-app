// Reusable overlay splash widget matching Bootstrap design
// - Centered app logo
// - Bottom spinner with safe-area padding
// - Surface-colored background
// Use across Bootstrap and Home to ensure consistent UX.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/startup/presentation/widgets/boot_simple_loading_screen.dart';

class OverlaySplash extends ConsumerWidget {
  const OverlaySplash({
    super.key,
    this.message,
    this.fadeInDuration,
    this.showProgressDetails = true,
  });

  final String? message;

  /// Durée du fade-in interne (optionnel). Par défaut 300 ms.
  final Duration? fadeInDuration;

  /// Affiche des infos d'avancement sous le spinner (temps écoulé).
  final bool showProgressDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BootSimpleLoadingScreen(
      message: message ?? '',
      showLogo: true,
      showProgress: true,
      showProgressDetails: showProgressDetails,
      fadeInDuration: fadeInDuration,
    );
  }
}
