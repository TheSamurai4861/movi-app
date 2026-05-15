import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

/// En-tête sous-page : retour + titre centré (mise en page partagée avec la grille provider).
class MoviSubpageBackTitleHeader extends StatelessWidget {
  const MoviSubpageBackTitleHeader({
    super.key,
    required this.title,
    this.onBack,
    this.focusNode,
    this.pageHorizontalPadding = 20,
  });

  final String title;
  final VoidCallback? onBack;
  final FocusNode? focusNode;

  /// Même valeur que le padding horizontal du contenu sous-jacent (ex. grille).
  final double pageHorizontalPadding;

  static const double _backButtonFramePadding = 8;
  static const double _backButtonSize = 35;

  @override
  Widget build(BuildContext context) {
    final uiScale = context.tvUiScale;
    final scaledPageHorizontalPadding = pageHorizontalPadding * uiScale;
    final scaledBackButtonFramePadding = _backButtonFramePadding * uiScale;
    final scaledBackButtonSize = _backButtonSize * uiScale;
    final headerStartPadding =
        (scaledPageHorizontalPadding - scaledBackButtonFramePadding).clamp(
          0.0,
          double.infinity,
        );
    final trailingHeaderSpacerWidth =
        scaledBackButtonSize + scaledBackButtonFramePadding;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        headerStartPadding,
        16 * uiScale,
        scaledPageHorizontalPadding,
        16 * uiScale,
      ),
      child: Row(
        children: [
          MoviFocusableAction(
            focusNode: focusNode,
            onPressed: onBack ?? () => context.pop(),
            semanticLabel:
                AppLocalizations.of(context)?.semanticsBack ?? 'Retour',
            builder: (context, state) {
              return MoviFocusFrame(
                scale: state.focused ? 1.04 : 1,
                padding: EdgeInsets.all(scaledBackButtonFramePadding),
                borderRadius: BorderRadius.circular(999),
                backgroundColor: state.focused
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.transparent,
                child: SizedBox(
                  width: scaledBackButtonSize,
                  height: scaledBackButtonSize,
                  child: MoviAssetIcon(
                    AppAssets.iconBack,
                    color: Colors.white,
                    width: 24 * uiScale,
                    height: 24 * uiScale,
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ).copyWith(fontSize: 24 * uiScale),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(width: trailingHeaderSpacerWidth),
        ],
      ),
    );
  }
}
