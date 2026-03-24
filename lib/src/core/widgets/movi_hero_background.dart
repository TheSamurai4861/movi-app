import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/presentation/extensions/responsive_context.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';

class MoviHeroBackground extends StatelessWidget {
  const MoviHeroBackground({
    super.key,
    this.posterBackground,
    this.poster,
    this.backdrop,
    required this.placeholderType,
    this.alignment = const Alignment(0.0, -0.5),
    this.fit = BoxFit.cover,
  });

  final String? posterBackground;
  final String? poster;
  final String? backdrop;
  final PlaceholderType placeholderType;
  final Alignment alignment;
  final BoxFit fit;

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  String? _pickUrl(BuildContext context) {
    if (context.isMobile) {
      // Règle métier mobile :
      // posterBackground > backdrop > poster
      return _firstNonEmpty([posterBackground, backdrop, poster]);
    }

    // Règle métier tablette / desktop / TV :
    // backdrop > poster > posterBackground
    return _firstNonEmpty([backdrop, poster, posterBackground]);
  }

  int? _computeCacheWidth(BuildContext context) {
    final mq = MediaQuery.of(context);

    // Sur desktop / TV, on laisse Flutter décoder la vraie source
    // sinon le cap 2560 peut flouter le hero.
    if (context.isDesktop || context.isTv) {
      return null;
    }

    final rawPx = (mq.size.width * mq.devicePixelRatio).round();
    return rawPx.clamp(480, 1920);
  }

  @override
  Widget build(BuildContext context) {
    final url = _pickUrl(context);

    if (url == null || url.isEmpty) {
      return MoviPlaceholderCard(
        type: placeholderType,
        fit: fit,
        alignment: alignment,
        borderRadius: BorderRadius.zero,
      );
    }

    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      cacheWidth: _computeCacheWidth(context),
      filterQuality: context.isMobile ? FilterQuality.low : FilterQuality.high,
      errorBuilder: (_, __, ___) {
        return MoviPlaceholderCard(
          type: placeholderType,
          fit: fit,
          alignment: alignment,
          borderRadius: BorderRadius.zero,
        );
      },
    );
  }
}
