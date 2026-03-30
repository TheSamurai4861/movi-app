import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_detail_hero.dart';
import 'package:movi/src/core/widgets/movi_hero_gradients.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_hero_image.dart';

class MovieDetailHeroSection extends StatefulWidget {
  const MovieDetailHeroSection({
    super.key,
    this.poster,
    this.posterBackground,
    this.backdrop,
    required this.onBack,
    required this.onMore,
    this.height = 400,
    this.overlayHeight = 200,
  });

  final Uri? poster;
  final Uri? posterBackground;
  final Uri? backdrop;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final double height;
  final double overlayHeight;

  @override
  State<MovieDetailHeroSection> createState() => _MovieDetailHeroSectionState();
}

class _MovieDetailHeroSectionState extends State<MovieDetailHeroSection> {
  late final FocusNode _backFocusNode = FocusNode(debugLabel: 'MovieHeroBack');
  late final FocusNode _moreFocusNode = FocusNode(debugLabel: 'MovieHeroMore')
    ..canRequestFocus = false;

  @override
  void dispose() {
    _backFocusNode.dispose();
    _moreFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleBackKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.ignored;
    }
    _moreFocusNode.canRequestFocus = true;
    _moreFocusNode.requestFocus();
    return KeyEventResult.handled;
  }

  KeyEventResult _handleMoreKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _backFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final overlaySpec = MoviHeroOverlaySpec.detailMobile.copyWith(
      topHeightRatio: 100 / widget.height,
      bottomHeightRatio: widget.overlayHeight / widget.height,
    );
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    );

    return MoviDetailHeroScene(
      isWideLayout: false,
      mobileHeight: widget.height,
      wideHeight: widget.height,
      background: MovieHeroImage(
        poster: widget.poster,
        posterBackground: widget.posterBackground,
        backdrop: widget.backdrop,
      ),
      overlaySpec: overlaySpec,
      children: [
        MoviDetailHeroTopBar(
          isWideLayout: false,
          horizontalPadding: 20,
          leading: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) => _handleBackKey(event),
            child: MoviDetailHeroActionButton(
              focusNode: _backFocusNode,
              iconAsset: AppAssets.iconBack,
              semanticLabel: 'Retour',
              onPressed: widget.onBack,
              isWideLayout: true,
              padding: buttonPadding,
            ),
          ),
          trailing: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) => _handleMoreKey(event),
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                _moreFocusNode.canRequestFocus = false;
              }
            },
            child: MoviDetailHeroActionButton(
              focusNode: _moreFocusNode,
              iconAsset: AppAssets.iconMore,
              semanticLabel: 'Plus d actions',
              onPressed: widget.onMore,
              isWideLayout: true,
              iconWidth: 25,
              padding: buttonPadding,
            ),
          ),
        ),
      ],
    );
  }
}
