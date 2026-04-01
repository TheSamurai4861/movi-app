import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

/// En-tête sous-page : retour + titre centré (mise en page partagée avec la grille provider).
class MoviSubpageBackTitleHeader extends StatelessWidget {
  const MoviSubpageBackTitleHeader({
    super.key,
    required this.title,
    this.onBack,
    this.pageHorizontalPadding = 20,
  });

  final String title;
  final VoidCallback? onBack;

  /// Même valeur que le padding horizontal du contenu sous-jacent (ex. grille).
  final double pageHorizontalPadding;

  static const double _backButtonFramePadding = 8;
  static const double _backButtonSize = 35;

  @override
  Widget build(BuildContext context) {
    final headerStartPadding = pageHorizontalPadding - _backButtonFramePadding;
    final trailingHeaderSpacerWidth =
        _backButtonSize + _backButtonFramePadding;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        headerStartPadding,
        16,
        pageHorizontalPadding,
        16,
      ),
      child: Row(
        children: [
          MoviFocusableAction(
            onPressed: onBack ?? () => context.pop(),
            semanticLabel: 'Retour',
            builder: (context, state) {
              return MoviFocusFrame(
                scale: state.focused ? 1.04 : 1,
                padding: const EdgeInsets.all(_backButtonFramePadding),
                borderRadius: BorderRadius.circular(999),
                backgroundColor: state.focused
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.transparent,
                child: const SizedBox(
                  width: _backButtonSize,
                  height: _backButtonSize,
                  child: MoviAssetIcon(
                    AppAssets.iconBack,
                    color: Colors.white,
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
                ),
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
