import 'dart:async';



import 'package:flutter/material.dart';

import 'package:movi/src/core/images/image_loading_policy.dart';

import 'package:movi/src/core/images/image_prefetch_policy.dart';

import 'package:movi/src/core/images/safe_image_cache_manager.dart';

import 'package:movi/src/core/utils/unawaited.dart';

import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';



/// File d'attente globale pour limiter I/O disque et décodage mémoire.

class ImagePrefetchCoordinator {

  ImagePrefetchCoordinator._();



  static final ImagePrefetchCoordinator instance = ImagePrefetchCoordinator._();



  static const int _maxTrackedUrls = 1200;



  final Set<String> _seenUrls = <String>{};

  final List<_PrefetchWorkItem> _queue = <_PrefetchWorkItem>[];

  int _activeCount = 0;



  /// Planifie le prefetch d'URLs HTTP(S). No-op si le cache est désactivé.

  ///

  /// Sans [context], seul le warmup disque est utilisé ([ImagePrefetchPolicy.diskOnly]).

  void scheduleUrls(

    Iterable<String> urls, {

    BuildContext? context,

    ImagePrefetchReason reason = ImagePrefetchReason.generic,

    int? maxItems,

    ImagePrefetchPolicy? policyOverride,

  }) {

    final loadingPolicy = ImageLoadingPolicyService.resolve();

    final prefetchPolicy =

        policyOverride ??

        (context != null

            ? ImagePrefetchPolicy.resolve(context)

            : ImagePrefetchPolicy.diskOnly);

    final canUseDisk =

        loadingPolicy.enableDiskCache && loadingPolicy.enableCachedNetworkPath;

    final canUseMemory =

        !loadingPolicy.forceNetworkFallbackOnly &&

        prefetchPolicy.allowMemoryPrecache;

    if (!canUseDisk && !canUseMemory) {

      return;

    }



    _enqueueUrls(

      urls,

      context: context,

      reason: reason,

      maxItems: maxItems,

      prefetchPolicy: prefetchPolicy,

      loadingPolicy: loadingPolicy,

      allowMemoryPrecache: canUseMemory,

    );



    _pumpQueue();

  }



  @visibleForTesting

  void enqueueUrlsForTest(

    Iterable<String> urls, {

    ImagePrefetchReason reason = ImagePrefetchReason.generic,

    int? maxItems,

    ImagePrefetchPolicy policyOverride = ImagePrefetchPolicy.diskOnly,

  }) {

    _enqueueUrls(

      urls,

      context: null,

      reason: reason,

      maxItems: maxItems,

      prefetchPolicy: policyOverride,

      loadingPolicy: ImageLoadingPolicy.defaults,

      allowMemoryPrecache: false,

    );

  }



  void _enqueueUrls(

    Iterable<String> urls, {

    required BuildContext? context,

    required ImagePrefetchReason reason,

    required int? maxItems,

    required ImagePrefetchPolicy prefetchPolicy,

    required ImageLoadingPolicy loadingPolicy,

    required bool allowMemoryPrecache,

  }) {

    final limit = maxItems ?? prefetchPolicy.maxUrlsFor(reason);



    final candidates = urls

        .map((url) => url.trim())

        .where(

          (url) =>

              url.isNotEmpty &&

              (url.startsWith('https://') || url.startsWith('http://')),

        )

        .take(limit);



    for (final rawUrl in candidates) {

      final url = _optimizePrefetchUrl(rawUrl, reason, prefetchPolicy);

      if (_seenUrls.length > _maxTrackedUrls) {

        _seenUrls.clear();

      }

      if (!_seenUrls.add(url)) {

        continue;

      }



      _queue.add(

        _PrefetchWorkItem(

          context: context,

          url: url,

          prefetchPolicy: prefetchPolicy,

          loadingPolicy: loadingPolicy,

          allowMemoryPrecache: allowMemoryPrecache,

        ),

      );

    }

  }



  void _pumpQueue() {

    while (_queue.isNotEmpty) {

      final maxConcurrent = _queue.first.prefetchPolicy.maxConcurrent;

      if (_activeCount >= maxConcurrent) {

        break;

      }

      final item = _queue.removeAt(0);

      _activeCount++;

      unawaited(_runItem(item));

    }

  }



  Future<void> _runItem(_PrefetchWorkItem item) async {

    try {

      await _prefetchUrl(item);

    } finally {

      _activeCount--;

      _pumpQueue();

    }

  }



  Future<void> _prefetchUrl(_PrefetchWorkItem item) async {

    final policy = item.prefetchPolicy;

    final loadingPolicy = item.loadingPolicy;

    final useDiskCachePath =

        loadingPolicy.enableDiskCache &&

        loadingPolicy.enableCachedNetworkPath &&

        !loadingPolicy.forceNetworkFallbackOnly;



    if (useDiskCachePath) {

      final cacheManager = SafeImageCacheManager.tryGet(enabled: true);

      if (cacheManager != null) {

        try {

          await cacheManager

              .getSingleFile(item.url)

              .timeout(policy.prefetchTimeout);

          return;

        } catch (_) {

          if (!policy.allowMemoryPrecache) {

            return;

          }

        }

      } else if (!policy.allowMemoryPrecache) {

        return;

      }

    } else if (!item.allowMemoryPrecache || !policy.allowMemoryPrecache) {

      return;

    }



    final context = item.context;

    if (context == null || !context.mounted) return;

    try {

      await precacheImage(

        NetworkImage(item.url),

        context,

      ).timeout(policy.prefetchTimeout);

    } catch (_) {

      // Le rendu principal conserve ses fallbacks.

    }

  }



  String _optimizePrefetchUrl(

    String url,

    ImagePrefetchReason reason,

    ImagePrefetchPolicy policy,

  ) {

    if (!policy.isTvLayout) {

      return url;

    }

    return TmdbImageResolver.downgradeHttpUrl(url, _tmdbSizeForPrefetch(reason)) ??

        url;

  }



  static String _tmdbSizeForPrefetch(ImagePrefetchReason reason) {

    return switch (reason) {

      ImagePrefetchReason.libraryPlaylists => 'w500',

      ImagePrefetchReason.continueWatching ||

      ImagePrefetchReason.heroCarousel ||

      ImagePrefetchReason.legacyHeroOverlay => 'w780',

      ImagePrefetchReason.providerGrid => 'w342',

      ImagePrefetchReason.generic => 'w500',

    };

  }



  @visibleForTesting

  void resetForTest() {

    _seenUrls.clear();

    _queue.clear();

    _activeCount = 0;

  }



  @visibleForTesting

  int get activeCountForTest => _activeCount;



  @visibleForTesting

  int get queueLengthForTest => _queue.length;



  @visibleForTesting

  String? peekQueuedUrlForTest() => _queue.isEmpty ? null : _queue.first.url;



  @visibleForTesting

  int get trackedUrlCountForTest => _seenUrls.length;



  @visibleForTesting

  Set<String> get trackedUrlsSnapshotForTest => Set<String>.from(_seenUrls);

}



class _PrefetchWorkItem {

  const _PrefetchWorkItem({

    required this.context,

    required this.url,

    required this.prefetchPolicy,

    required this.loadingPolicy,

    required this.allowMemoryPrecache,

  });



  final BuildContext? context;

  final String url;

  final ImagePrefetchPolicy prefetchPolicy;

  final ImageLoadingPolicy loadingPolicy;

  final bool allowMemoryPrecache;

}

