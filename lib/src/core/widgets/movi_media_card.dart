import 'package:flutter/material.dart';
import 'package:movi/src/core/images/image_decode_size.dart';
import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/widgets/movi_ellipsis_text.dart';
import 'package:movi/src/core/widgets/movi_network_image.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';

Widget _buildPosterImage(
  BuildContext context,
  Uri? poster,
  double width,
  double height, {
  PlaceholderType? placeholderType,
}) {
  final decodeSize = ImageDecodeSize.decodeSizeForCard(context, width, height);
  final Widget placeholder = (placeholderType == null)
      ? Container(
          width: width,
          height: height,
          color: const Color(0xFF222222),
          child: const Center(
            child: Icon(Icons.broken_image, size: 32, color: Colors.white54),
          ),
        )
      : MoviPlaceholderCard(
          type: placeholderType,
          width: width,
          height: height,
        );

  if (poster == null) return placeholder;
  final source = poster.toString().trim();
  if (source.isEmpty) return placeholder;
  final scheme = poster.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') {
    return MoviNetworkImage(
      poster.toString(),
      width: width,
      height: height,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      cacheWidth: decodeSize.width,
      cacheHeight: decodeSize.height,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  final assetPath = scheme == 'asset' ? poster.path : source;

  return Image.asset(
    assetPath,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => placeholder,
    cacheWidth: decodeSize.width,
    cacheHeight: decodeSize.height,
  );
}

/// Card used to display either a movie or a series.
class MoviMediaCard extends StatefulWidget {
  static const double listHeight = 262;

  const MoviMediaCard({
    super.key,
    required this.media,
    this.width = 150,
    this.height = 225,
    this.onTap,
    this.heroTag,
    this.highlightBorder = false,
    this.focusNode,
    this.autofocus = false,
  });

  final MoviMedia media;
  final double width;
  final double height;
  final ValueChanged<MoviMedia>? onTap;
  final Object? heroTag;
  final bool highlightBorder;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<MoviMediaCard> createState() => _MoviMediaCardState();
}

class _MoviMediaCardState extends State<MoviMediaCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final uiScale = context.tvUiScale;
    final scaledWidth = widget.width * uiScale;
    final scaledHeight = widget.height * uiScale;
    final focusRadius = 18.0 * uiScale;
    final cardTitleGap = 12.0 * uiScale;
    final focusBorderWidth = 2.0 * uiScale;
    final focusShadowBlur = 18.0 * uiScale;
    final focusShadowSpread = 2.0 * uiScale;
    final theme = Theme.of(context);
    final focusBorderColor = theme.colorScheme.primary;
    final textStyle =
        theme.textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.2,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onTap: widget.onTap == null
            ? null
            : () => widget.onTap?.call(widget.media),
        onFocusChange: (focused) {
          if (_focused == focused) return;
          setState(() => _focused = focused);
        },
        borderRadius: BorderRadius.circular(focusRadius),
        child: AnimatedScale(
          scale: _focused ? 1.035 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: scaledWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.all(focusBorderWidth),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(focusRadius),
                    border: Border.all(
                      color: _focused ? focusBorderColor : Colors.transparent,
                      width: focusBorderWidth,
                    ),
                    boxShadow: _focused
                        ? [
                            BoxShadow(
                              color: focusBorderColor.withValues(alpha: 0.18),
                              blurRadius: focusShadowBlur,
                              spreadRadius: focusShadowSpread,
                            ),
                          ]
                        : null,
                  ),
                  child: _PosterWithOverlay(
                    media: widget.media,
                    width: scaledWidth,
                    height: scaledHeight,
                    heroTag: widget.heroTag,
                    highlightBorder: widget.highlightBorder,
                  ),
                ),
                SizedBox(height: cardTitleGap),
                MoviEllipsisText(
                  text: widget.media.title,
                  style: textStyle,
                  maxWidth: scaledWidth,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterWithOverlay extends StatelessWidget {
  const _PosterWithOverlay({
    required this.media,
    required this.width,
    required this.height,
    this.heroTag,
    this.highlightBorder = false,
  });

  final MoviMedia media;
  final double width;
  final double height;
  final Object? heroTag;
  final bool highlightBorder;

  @override
  Widget build(BuildContext context) {
    final uiScale = context.tvUiScale;
    final borderWidth = 2.0 * uiScale;
    final borderInset = borderWidth * 2;
    final image = Stack(
      fit: StackFit.expand,
      children: [
        _buildPosterImage(
          context,
          media.poster,
          width,
          height,
          placeholderType: media.type == MoviMediaType.movie
              ? PlaceholderType.movie
              : PlaceholderType.series,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(height: height * 0.35),
        ),
      ],
    );

    final widgetContent = highlightBorder
        ? Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16 * context.tvUiScale),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: borderWidth,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                14 * context.tvUiScale,
              ), // 16 - 2 pour la bordure
              child: SizedBox(
                width: width - borderInset,
                height: height - borderInset,
                child: image,
              ),
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(16 * context.tvUiScale),
            child: SizedBox(width: width, height: height, child: image),
          );

    if (heroTag == null) return widgetContent;
    return Hero(tag: heroTag!, child: widgetContent);
  }
}
