// Reusable overlay splash widget matching Bootstrap design
// - Centered app logo
// - Bottom spinner with safe-area padding
// - Surface-colored background
// Use across Bootstrap and Home to ensure consistent UX.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

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
                  Semantics(
                    label: 'Chargement en cours',
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: (theme.platform == TargetPlatform.iOS ||
                              theme.platform == TargetPlatform.macOS)
                          ? const CupertinoActivityIndicator(radius: 12)
                          : const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  if (showProgressDetails) ...[
                    const SizedBox(height: 10),
                    _ElapsedLoadingText(
                      baseText: message?.trim().isNotEmpty == true
                          ? message!.trim()
                          : 'Chargement…',
                    ),
                  ],
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
      final locator = ref.read(slProvider);
      if (!locator.isRegistered<AccentColorPreferences>()) {
        return theme.colorScheme.primary;
      }
      return ref.watch(asp.currentAccentColorProvider);
    } catch (_) {
      return theme.colorScheme.primary;
    }
  }
}

class _ElapsedLoadingText extends StatefulWidget {
  const _ElapsedLoadingText({required this.baseText});

  final String baseText;

  @override
  State<_ElapsedLoadingText> createState() => _ElapsedLoadingTextState();
}

class _ElapsedLoadingTextState extends State<_ElapsedLoadingText> {
  late final Stopwatch _sw = Stopwatch()..start();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(seconds: 1), (i) => i),
      builder: (_, __) {
        final s = _sw.elapsed.inSeconds;
        final text = '${
            widget.baseText.isEmpty ? 'Chargement…' : widget.baseText
          } · ${s}s';
        return Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70) ??
              const TextStyle(color: Colors.white70, fontSize: 12),
        );
      },
    );
  }

  @override
  void dispose() {
    _sw.stop();
    super.dispose();
  }
}
