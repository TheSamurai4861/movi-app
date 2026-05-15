import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';

/// Identifie l'origine d'un lot de prefetch pour appliquer des plafonds dédiés.
enum ImagePrefetchReason {
  generic,
  libraryPlaylists,
  continueWatching,
  providerGrid,
  heroCarousel,
  legacyHeroOverlay,
}

@immutable
class ImagePrefetchPolicy {
  const ImagePrefetchPolicy({
    required this.maxConcurrent,
    required this.allowMemoryPrecache,
    required this.prefetchTimeout,
    required this.maxUrlsByReason,
    required this.isTvLayout,
  });

  final int maxConcurrent;
  final bool allowMemoryPrecache;
  final Duration prefetchTimeout;
  final Map<ImagePrefetchReason, int> maxUrlsByReason;
  final bool isTvLayout;

  static const ImagePrefetchPolicy standard = ImagePrefetchPolicy(
    maxConcurrent: 3,
    allowMemoryPrecache: true,
    prefetchTimeout: Duration(seconds: 8),
    isTvLayout: false,
    maxUrlsByReason: {
      ImagePrefetchReason.generic: 12,
      ImagePrefetchReason.libraryPlaylists: 32,
      ImagePrefetchReason.continueWatching: 14,
      ImagePrefetchReason.providerGrid: 4,
      ImagePrefetchReason.heroCarousel: 2,
      ImagePrefetchReason.legacyHeroOverlay: 1,
    },
  );

  /// Prefetch disque uniquement (sans [BuildContext], ex. providers Riverpod).
  static const ImagePrefetchPolicy diskOnly = ImagePrefetchPolicy(
    maxConcurrent: 3,
    allowMemoryPrecache: false,
    prefetchTimeout: Duration(seconds: 8),
    isTvLayout: false,
    maxUrlsByReason: {
      ImagePrefetchReason.generic: 12,
      ImagePrefetchReason.libraryPlaylists: 32,
      ImagePrefetchReason.continueWatching: 14,
      ImagePrefetchReason.providerGrid: 4,
      ImagePrefetchReason.heroCarousel: 2,
      ImagePrefetchReason.legacyHeroOverlay: 1,
    },
  );

  static const ImagePrefetchPolicy television = ImagePrefetchPolicy(
    maxConcurrent: 2,
    allowMemoryPrecache: false,
    prefetchTimeout: Duration(seconds: 6),
    isTvLayout: true,
    maxUrlsByReason: {
      ImagePrefetchReason.generic: 6,
      ImagePrefetchReason.libraryPlaylists: 16,
      ImagePrefetchReason.continueWatching: 7,
      ImagePrefetchReason.providerGrid: 2,
      ImagePrefetchReason.heroCarousel: 2,
      ImagePrefetchReason.legacyHeroOverlay: 1,
    },
  );

  int maxUrlsFor(ImagePrefetchReason reason) {
    return maxUrlsByReason[reason] ?? maxUrlsByReason[ImagePrefetchReason.generic]!;
  }

  static ImagePrefetchPolicy resolve(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenType = context.resolveScreenType(size.width, size.height);
    if (screenType == ScreenType.tv) {
      return television;
    }
    return standard;
  }
}
