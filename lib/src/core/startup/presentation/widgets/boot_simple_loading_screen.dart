// Chargement boot non interactif : logo centre (Stack), texte en bandeau bas
// (Positioned), hors flux vertical du logo — conforme Phase 4 étape 3.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_form_tokens.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';

/// Écran de chargement simple boot : logo centré, texte et indicateur en bas.
///
/// Aucune action utilisateur : ne pas y placer de boutons.
class BootSimpleLoadingScreen extends ConsumerWidget {
  const BootSimpleLoadingScreen({
    super.key,
    required this.message,
    this.secondaryMessage,
    this.showLogo = true,
    this.showProgress = true,
    this.showProgressDetails = true,
    this.fadeInDuration,
  });

  /// Variante alignée sur un [BootScreenModel] non interactif (chargement
  /// simple ou ouverture Home). Le chargement catalogue utilise
  /// [BootCatalogLoadingScreen].
  factory BootSimpleLoadingScreen.forBootModel(
    BootScreenModel model, {
    Key? key,
    String? messageOverride,
    String? secondaryMessageOverride,
    bool? showProgressDetails,
  }) {
    assert(
      !model.isInteractive,
      'BootSimpleLoadingScreen.forBootModel: état interactif',
    );
    assert(
      model.screenType == BootScreenType.simpleLoading ||
          model.screenType == BootScreenType.openingHome,
      'BootSimpleLoadingScreen.forBootModel: type ${model.screenType}',
    );
    return BootSimpleLoadingScreen(
      key: key,
      message: messageOverride ?? model.message,
      secondaryMessage: secondaryMessageOverride ?? model.secondaryMessage,
      showLogo: model.showLogo,
      showProgress: model.showProgress,
      showProgressDetails: showProgressDetails ?? true,
    );
  }

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
    final bottom = 30.0 + MediaQuery.of(context).padding.bottom;
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BootFormTokens.constrainTextField(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showProgress) ...[
                        Semantics(
                          label:
                              l10n?.bootSemanticsLoadingInProgress ??
                              'Loading in progress',
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                (theme.platform == TargetPlatform.iOS ||
                                    theme.platform == TargetPlatform.macOS)
                                ? const CupertinoActivityIndicator(radius: 12)
                                : const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (showProgressDetails)
                        BootLoadingElapsedLabel(baseText: baseText)
                      else
                        Text(
                          baseText,
                          textAlign: TextAlign.center,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ) ??
                              TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                        ),
                      if (secondary != null && secondary.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          secondary,
                          textAlign: TextAlign.center,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ) ??
                              TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
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

/// Ligne de statut avec durée écoulée (suffixe · Ns), partagée par les
/// surfaces de chargement boot.
class BootLoadingElapsedLabel extends StatefulWidget {
  const BootLoadingElapsedLabel({
    super.key,
    required this.baseText,
    this.textStyle,
  });

  final String baseText;

  /// Si null, style discret `bodySmall` / `onSurfaceVariant`.
  final TextStyle? textStyle;

  @override
  State<BootLoadingElapsedLabel> createState() => _BootLoadingElapsedLabelState();
}

class _BootLoadingElapsedLabelState extends State<BootLoadingElapsedLabel> {
  late final Stopwatch _sw = Stopwatch()..start();

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final theme = Theme.of(context);
    final defaultStyle =
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ) ??
        TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12);
    final style = widget.textStyle ?? defaultStyle;

    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(seconds: 1), (i) => i),
      builder: (_, __) {
        final s = _sw.elapsed.inSeconds;
        final prefix = widget.baseText.isEmpty
            ? (l10n?.bootLoadingDefault ?? 'Loading…')
            : widget.baseText;
        final text = '$prefix · ${s}s';
        return Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: style,
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
