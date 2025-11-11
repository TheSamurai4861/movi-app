import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movi_media.dart';
import '../router/app_router.dart';
import '../utils/app_assets.dart';
import 'movi_marquee_text.dart';
import 'movi_pill.dart';

Widget _buildPosterImage(String source, double width, double height) {
  final placeholder = Container(
    width: width,
    height: height,
    color: const Color(0xFF222222),
    child: const Center(
      child: Icon(Icons.broken_image, size: 32, color: Colors.white54),
    ),
  );

  // Si source vide → placeholder direct (pas d’essai asset/network)
  if (source.trim().isEmpty) return placeholder;

  if (source.startsWith('http')) {
    return Image.network(
      source,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      // Supprime le loadingBuilder pour éviter des reconstructions fréquentes.
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }

  return Image.asset(
    source,
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
  });

  final MoviMedia media;
  final double width;
  final double height;

  @override
  State<MoviMediaCard> createState() => _MoviMediaCardState();
}

class _MoviMediaCardState extends State<MoviMediaCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );

    return GestureDetector(
      onTap: () => _handleTap(context, widget.media),
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

  void _handleTap(BuildContext context, MoviMedia media) {
    switch (media.type) {
      case MoviMediaType.movie:
        context.push(AppRouteNames.movie);
        break;
      case MoviMediaType.series:
        context.push(AppRouteNames.tv);
        break;
    }
  }
}

class _PosterWithOverlay extends StatelessWidget {
  const _PosterWithOverlay({
    required this.media,
    required this.width,
    required this.height,
  });

  final MoviMedia media;
  final double width;
  final double height;

  bool get _hasYear {
    final y = media.year.trim();
    return y.isNotEmpty && y != '—';
  }

  bool get _hasRating {
    final r = media.rating.trim();
    return r.isNotEmpty && r != '—';
  }

  @override
  Widget build(BuildContext context) {
    final showAnyPill = _hasYear || _hasRating;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          SizedBox(
            width: width,
            height: height,
            child: _buildPosterImage(media.poster, width, height),
          ),
          // Dégradé bas pour lisibilité
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF404040),
                      Color(0x00404040),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Pills conditionnelles (Patch 6)
          if (showAnyPill)
            Positioned(
              left: 16,
              bottom: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasYear) MoviPill(media.year, large: false),
                  if (_hasYear && _hasRating) const SizedBox(width: 4),
                  if (_hasRating)
                    MoviPill(
                      media.rating,
                      large: false,
                      trailingIcon: Image.asset(
                        AppAssets.iconStarFilled,
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
