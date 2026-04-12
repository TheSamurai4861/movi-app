import 'package:flutter/material.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';
import 'package:movi/src/core/widgets/movi_network_image.dart';

enum MoviHeroImageStrategy { adaptive, backdropFirst }

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
  static final Set<String> _loggedBuildKeys = <String>{};
  static final Set<String> _loggedPlaceholderKeys = <String>{};
  static final Set<String> _loggedErrorUrls = <String>{};

  void _logBackgroundDebug(
    String event, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    final message = <String>[
      '[HomeHeroDebug]',
      'surface=hero_background',
      'event=$event',
      for (final entry in context.entries)
        if (entry.value != null) '${entry.key}=${entry.value}',
    ].join(' ');
    unawaited(LoggingService.log(message, category: 'home_hero_debug'));
  }

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
    final cacheWidth = url == null || url.isEmpty
        ? null
        : _computeCacheWidth(context);
    final buildKey = [
      imageStrategy.name,
      screenType.name,
      cacheWidth,
      posterBackground,
      poster,
      backdrop,
      url,
    ].join('|');
    if (_loggedBuildKeys.add(buildKey)) {
      _logBackgroundDebug(
        'build',
        context: <String, Object?>{
          'imageStrategy': imageStrategy.name,
          'screenType': screenType.name,
          'cacheWidth': cacheWidth,
          'posterBackground': posterBackground,
          'poster': poster,
          'backdrop': backdrop,
          'selectedUrl': url,
        },
      );
    }

    if (url == null || url.isEmpty) {
      final placeholderKey = [
        imageStrategy.name,
        screenType.name,
        posterBackground,
        poster,
        backdrop,
      ].join('|');
      if (_loggedPlaceholderKeys.add(placeholderKey)) {
        _logBackgroundDebug(
          'placeholder',
          context: <String, Object?>{
            'imageStrategy': imageStrategy.name,
            'screenType': screenType.name,
          },
        );
      }
      return MoviPlaceholderCard(
        type: placeholderType,
        fit: fit,
        alignment: alignment,
        borderRadius: BorderRadius.zero,
      );
    }

    return MoviNetworkImage(
      url,
      fit: fit,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      filterQuality: screenType == ScreenType.mobile
          ? FilterQuality.low
          : FilterQuality.high,
      errorBuilder: (_, __, ___) {
        if (_loggedErrorUrls.add(url)) {
          _logBackgroundDebug(
            'image_error',
            context: <String, Object?>{
              'screenType': screenType.name,
              'cacheWidth': cacheWidth,
              'selectedUrl': url,
            },
          );
        }
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
