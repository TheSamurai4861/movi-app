import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

import 'package:movi/src/core/images/app_image_cache_manager.dart';
import 'package:movi/src/core/preferences/playback_sync_offset_preferences.dart';
import 'package:movi/src/core/preferences/subtitle_appearance_preferences.dart';
import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/shared/domain/services/tmdb_cache_store.dart';

/// Clears on-disk and in-memory app caches without touching user playback prefs.
///
/// Audio/subtitle sync offsets and subtitle appearance are stored in secure
/// storage under [protectedSecureStorageKeyPrefixes] and are intentionally
/// excluded from any wipe performed here.
typedef ImageDiskCacheClearer = Future<void> Function();

class AppCacheClearService {
  AppCacheClearService({
    required ContentCacheRepository contentCache,
    TmdbCacheStore? tmdbCache,
    ImageDiskCacheClearer? clearImageDiskCache,
  }) : _contentCache = contentCache,
       _tmdbCache = tmdbCache,
       _clearImageDiskCache =
           clearImageDiskCache ?? AppImageCacheManager.instance.emptyCache;

  /// Secure-storage key prefixes that must survive a user-initiated cache clear.
  static const List<String> protectedSecureStorageKeyPrefixes = <String>[
    PlaybackSyncOffsetPreferences.defaultStorageKeyPrefix,
    SubtitleAppearancePreferences.defaultStorageKeyPrefix,
  ];

  final ContentCacheRepository _contentCache;
  final TmdbCacheStore? _tmdbCache;
  final ImageDiskCacheClearer _clearImageDiskCache;

  Future<void> clearAppCaches() async {
    await _contentCache.clearAll();
    _tmdbCache?.clearMemoryMemo();
    await _clearImageDiskCache();
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
    if (kDebugMode) {
      debugPrint('[AppCacheClearService] App caches cleared');
    }
  }
}
