// Reusable overlay splash widget matching Bootstrap design
// - Centered app logo
// - Bottom spinner with safe-area padding
// - Surface-colored background
// Use across Bootstrap and Home to ensure consistent UX.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

class OverlaySplash extends ConsumerWidget {
  const OverlaySplash({super.key, this.message, this.fadeInDuration});

  final String? message;

  /// Durée du fade-in interne (optionnel). Par défaut 300 ms.
  final Duration? fadeInDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accentColor = _resolveAccentColor(ref, theme);
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
              child: Semantics(
                label: 'MOVI splash logo',
                child: SvgPicture.asset(
                  AppAssets.iconAppLogoSvg,
                  height: 120,
                  colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
                ),
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
                  Semantics(
                    label: 'Chargement en cours',
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _resolveAccentColor(WidgetRef ref, ThemeData theme) {
    try {
      return ref.watch(asp.currentAccentColorProvider);
    } catch (_) {
      return theme.colorScheme.primary;
    }
  }
}
