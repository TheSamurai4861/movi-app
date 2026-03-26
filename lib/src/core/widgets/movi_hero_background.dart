import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';

enum MoviHeroImageStrategy {
  adaptive,
  backdropFirst,
}

class MoviHeroBackground extends StatelessWidget {
  const MoviHeroBackground({
    super.key,
    this.posterBackground,
    this.poster,
    this.backdrop,
    required this.placeholderType,
    this.alignment = const Alignment(0.0, -0.5),
    this.fit = BoxFit.cover,
    this.imageStrategy = MoviHeroImageStrategy.adaptive,
  });

  final String? posterBackground;
  final String? poster;
  final String? backdrop;
  final PlaceholderType placeholderType;
  final Alignment alignment;
  final BoxFit fit;
  final MoviHeroImageStrategy imageStrategy;

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  ScreenType _screenType(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) {
      return ScreenType.mobile;
    }

    return ScreenTypeResolver.instance.resolve(
      mq.size.width,
      mq.size.height == 0 ? 1 : mq.size.height,
    );
  }

  String? _pickUrl(BuildContext context) {
    final screenType = _screenType(context);

    if (imageStrategy == MoviHeroImageStrategy.backdropFirst) {
      // Détail film/série :
      // backdrop > poster > posterBackground
      return _firstNonEmpty([backdrop, poster, posterBackground]);
    }

    if (screenType == ScreenType.mobile) {
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
    final screenType = _screenType(context);

    // Sur desktop / TV, on laisse Flutter décoder la vraie source
    // sinon le cap 2560 peut flouter le hero.
    if (screenType == ScreenType.desktop || screenType == ScreenType.tv) {
      return null;
    }

    final rawPx = (mq.size.width * mq.devicePixelRatio).round();
    return rawPx.clamp(480, 1920);
  }

  @override
  Widget build(BuildContext context) {
    final url = _pickUrl(context);
    final screenType = _screenType(context);

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
      filterQuality: screenType == ScreenType.mobile
          ? FilterQuality.low
          : FilterQuality.high,
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
