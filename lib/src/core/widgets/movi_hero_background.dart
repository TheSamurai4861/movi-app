import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
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

  ScreenType _resolveScreenType(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq != null) {
      return ScreenTypeResolver.instance.resolve(
        mq.size.width,
        mq.size.height,
      );
    }

    final view = View.maybeOf(context);
    if (view != null) {
      final dpr = view.devicePixelRatio == 0 ? 1.0 : view.devicePixelRatio;
      return ScreenTypeResolver.instance.resolve(
        view.physicalSize.width / dpr,
        view.physicalSize.height / dpr,
      );
    }

    return ScreenType.mobile;
  }

  String? _firstNonEmpty(List<String?> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _pickUrl(BuildContext context) {
    final screenType = _resolveScreenType(context);
    final isMobile = screenType == ScreenType.mobile;

    return isMobile
        ? _firstNonEmpty([posterBackground, poster, backdrop])
        : _firstNonEmpty([backdrop, posterBackground, poster]);
  }

  int _computeCacheWidth(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    final view = View.maybeOf(context);

    final logicalWidth = mq?.size.width ??
        ((view?.physicalSize.width ?? 1280) / (view?.devicePixelRatio ?? 1.0));
    final dpr = mq?.devicePixelRatio ?? view?.devicePixelRatio ?? 1.0;
    final rawPx = (logicalWidth * dpr).round();

    final screenType = _resolveScreenType(context);
    final isLarge = screenType == ScreenType.desktop || screenType == ScreenType.tv;
    final maxWidth = isLarge ? 2560 : 1920;

    return rawPx.clamp(480, maxWidth).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final screenType = _resolveScreenType(context);
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