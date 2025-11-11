// Reusable overlay splash widget matching Bootstrap design
// - Centered app logo
// - Bottom spinner with safe-area padding
// - Surface-colored background
// Use across Bootstrap and Home to ensure consistent UX.

import 'package:flutter/material.dart';

class OverlaySplash extends StatelessWidget {
  const OverlaySplash({super.key, this.message, this.fadeInDuration});

  final String? message;
  /// Durée du fade-in interne (optionnel). Par défaut 300 ms.
  final Duration? fadeInDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = 30.0 + MediaQuery.of(context).padding.bottom;

    final duration = fadeInDuration ?? const Duration(milliseconds: 300);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Container(
        color: theme.colorScheme.surface,
        child: Stack(
          children: [
            Center(
              child: Image.asset(
                'assets/icons/app_logo.png',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message != null && message!.isNotEmpty) ...[
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}