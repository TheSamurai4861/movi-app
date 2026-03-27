// lib/src/features/category_browser/presentation/widgets/category_header.dart
import 'package:flutter/material.dart';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

class CategoryHeader extends StatelessWidget {
  const CategoryHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 25,
            child: MoviFocusableAction(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              semanticLabel: 'Retour',
              builder: (context, state) {
                return MoviFocusFrame(
                  scale: state.focused ? 1.04 : 1,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: state.focused
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.transparent,
                  child: const SizedBox(
                    width: 35,
                    height: 35,
                    child: MoviAssetIcon(
                      AppAssets.iconBack,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 30,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
