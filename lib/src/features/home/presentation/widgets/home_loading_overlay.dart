import 'package:flutter/material.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';

/// Overlay de chargement affiché pendant le chargement initial de la page.
class HomeLoadingOverlay extends StatelessWidget {
  const HomeLoadingOverlay({super.key, required this.show});

  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: const OverlaySplash(),
    );
  }
}
