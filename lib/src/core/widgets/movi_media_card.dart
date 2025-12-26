import 'package:flutter/material.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/widgets/movi_marquee_text.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';

Widget _buildPosterImage(
  Uri? poster,
  double width,
  double height, {
  PlaceholderType? placeholderType,
}) {
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
    return Image.network(
      poster.toString(),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      cacheWidth: (width * 2).toInt(),
      cacheHeight: (height * 2).toInt(),
    );
  }

  final assetPath = scheme == 'asset' ? poster.path : source;

  return Image.asset(
    assetPath,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => placeholder,
    cacheWidth: (width * 2).toInt(),
    cacheHeight: (height * 2).toInt(),
  );
}

/// Card used to display either a movie or a series.
class MoviMediaCard extends StatefulWidget {
  const MoviMediaCard({
    super.key,
    required this.media,
    this.width = 150,
    this.height = 225,
    this.onTap,
    this.heroTag,
    this.highlightBorder = false,
  });

  final MoviMedia media;
  final double width;
  final double height;
  final ValueChanged<MoviMedia>? onTap;
  final Object? heroTag;
  final bool highlightBorder;

  @override
  State<MoviMediaCard> createState() => _MoviMediaCardState();
}

class _MoviMediaCardState extends State<MoviMediaCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle =
        theme.textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );

    return GestureDetector(
      onTap: () => widget.onTap?.call(widget.media),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PosterWithOverlay(
              media: widget.media,
              width: widget.width,
              height: widget.height,
              heroTag: widget.heroTag,
              highlightBorder: widget.highlightBorder,
            ),
            const SizedBox(height: 12),
            MoviMarqueeText(
              text: widget.media.title,
              style: textStyle,
              maxWidth: widget.width,
            ),
          ],
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
    final image = Stack(
      fit: StackFit.expand,
      children: [
        _buildPosterImage(
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14), // 16 - 2 pour la bordure
              child: SizedBox(
                width: width - 4, // Compenser la bordure (2px de chaque côté)
                height: height - 4, // Compenser la bordure (2px de chaque côté)
                child: image,
              ),
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(width: width, height: height, child: image),
          );

    if (heroTag == null) return widgetContent;
    return Hero(tag: heroTag!, child: widgetContent);
  }
}
