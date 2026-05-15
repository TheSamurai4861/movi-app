// Surface boot dédiée à la préparation catalogue (Phase 4 étape 4) : distincte
// du splash simple, toujours non interactive.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_form_tokens.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';

import 'package:movi/src/core/startup/presentation/widgets/boot_simple_loading_screen.dart'
    show BootLoadingElapsedLabel;

/// Chargement catalogue : logo centré, zone d’état en bas.
///
/// Aucune action (pas de « Changer de source » ni autre CTA) : attente normale
/// uniquement.
class BootCatalogLoadingScreen extends ConsumerWidget {
  const BootCatalogLoadingScreen({
    super.key,
    required this.message,
    this.secondaryMessage,
    this.showLogo = true,
    this.showProgress = true,
    this.showProgressDetails = true,
    this.fadeInDuration,
  });

  final String message;
  final String? secondaryMessage;
  final bool showLogo;
  final bool showProgress;
  final bool showProgressDetails;
  final Duration? fadeInDuration;

  static const double _logoSize = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final theme = Theme.of(context);
    final accentColor = _resolveAccentColor(ref, theme);
    final bottom = 24.0 + MediaQuery.of(context).padding.bottom;
    final duration = fadeInDuration ?? const Duration(milliseconds: 300);

    final baseText = message.trim().isEmpty
        ? (l10n?.bootLoadingDefault ?? 'Loading…')
        : message.trim();
    final secondary = secondaryMessage?.trim();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Stack(
          children: [
            if (showLogo)
              Center(
                child: Semantics(
                  label: l10n?.bootSemanticsSplashLogo ?? 'MOVI splash logo',
                  child: MoviAssetIcon(
                    AppAssets.iconAppLogoSvg,
                    width: _logoSize,
                    height: _logoSize,
                    color: accentColor,
                    excludeFromSemantics: false,
                    semanticLabel: l10n?.bootSemanticsSplashLogo ?? 'MOVI splash logo',
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottom,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: BootFormTokens.constrainTextField(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showProgress) ...[
                        Semantics(
                          label:
                              l10n?.bootSemanticsPreparingCatalog ??
                              'Preparing catalog',
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child:
                                (theme.platform == TargetPlatform.iOS ||
                                    theme.platform == TargetPlatform.macOS)
                                ? const CupertinoActivityIndicator(radius: 14)
                                : const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (showProgressDetails)
                        BootLoadingElapsedLabel(
                          baseText: baseText,
                          textStyle: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ) ??
                              TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                        )
                      else
                        Text(
                          baseText,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ) ??
                              TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                        ),
                      if (secondary != null && secondary.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          secondary,
                          textAlign: TextAlign.center,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ) ??
                              TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
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
