import 'package:flutter/material.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/widgets/movi_marquee_text.dart';

Widget _buildPosterImage(Uri? poster, double width, double height) {
  final placeholder = Container(
    width: width,
    height: height,
    color: const Color(0xFF222222),
    child: const Center(
      child: Icon(Icons.broken_image, size: 32, color: Colors.white54),
    ),
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
      // Supprime le loadingBuilder pour éviter des reconstructions fréquentes.
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }

  final assetPath = scheme == 'asset' ? poster.path : source;

  return Image.asset(
    assetPath,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => placeholder,
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
  });

  final MoviMedia media;
  final double width;
  final double height;
  final ValueChanged<MoviMedia>? onTap;
  final Object? heroTag;

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
  });

  final MoviMedia media;
  final double width;
  final double height;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final image = Stack(
      fit: StackFit.expand,
      children: [
        _buildPosterImage(media.poster, width, height),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: height * 0.35,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xCC000000)],
              ),
            ),
          ),
        ),
      ],
    );

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(width: width, height: height, child: image),
    );

    if (heroTag == null) return content;
    return Hero(tag: heroTag!, child: content);
  }
}
