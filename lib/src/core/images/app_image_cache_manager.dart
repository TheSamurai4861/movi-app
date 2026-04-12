import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache disque global pour les images réseau raster.
///
/// Politique v1:
/// - stalePeriod: 7 jours
/// - capacité cible: ~400 MB (approximation via nombre d'objets)
class AppImageCacheManager extends CacheManager {
  AppImageCacheManager._()
    : super(
        Config(
          _cacheKey,
          stalePeriod: stalePeriod,
          // flutter_cache_manager borne la taille via le nombre d'objets.
          // 1000 objets correspond à ~400 MB avec une image moyenne ~400 KB.
          maxNrOfCacheObjects: maxCacheObjects,
        ),
      );

  static const String _cacheKey = 'movi_image_cache_v1';
  static const Duration stalePeriod = Duration(days: 7);
  static const int maxCacheObjects = 1000;
  static const int approxMaxCacheBytes = 400 * 1024 * 1024;

  static final AppImageCacheManager instance = AppImageCacheManager._();
}
