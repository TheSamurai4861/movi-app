import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
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
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MovieHeroImage(
            poster: widget.poster,
            posterBackground: widget.posterBackground,
            backdrop: widget.backdrop,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF141414), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, event) => _handleBackKey(event),
                  child: MoviFocusableAction(
                    focusNode: _backFocusNode,
                    onPressed: widget.onBack,
                    semanticLabel: 'Retour',
                    builder: (context, state) {
                      return MoviFocusFrame(
                        scale: state.focused ? 1.04 : 1,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
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
                Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, event) => _handleMoreKey(event),
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) {
                      _moreFocusNode.canRequestFocus = false;
                    }
                  },
                  child: MoviFocusableAction(
                    focusNode: _moreFocusNode,
                    onPressed: widget.onMore,
                    semanticLabel: 'Plus d actions',
                    builder: (context, state) {
                      return MoviFocusFrame(
                        scale: state.focused ? 1.04 : 1,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: state.focused
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.transparent,
                        child: const SizedBox(
                          width: 25,
                          height: 35,
                          child: MoviAssetIcon(
                            AppAssets.iconMore,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: widget.overlayHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xFF141414)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
