import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/images/image_loading_policy.dart';
import 'package:movi/src/core/images/safe_image_cache_manager.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/presentation/widgets/premium_feature_gate.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/movi_items_list.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/home/domain/entities/in_progress_media.dart'
    as domain;
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/home/presentation/widgets/continue_watching_card.dart';
import 'package:movi/src/features/home/presentation/widgets/home_first_section_transition.dart';
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
import 'package:movi/src/features/settings/presentation/localization/movi_premium_localizer.dart';
import 'package:movi/src/features/settings/presentation/pages/movi_premium_page.dart';
import 'package:movi/src/shared/domain/services/iptv_content_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

/// Section affichant les médias en cours de lecture.
class HomeContinueWatchingSection extends ConsumerStatefulWidget {
  const HomeContinueWatchingSection({
    super.key,
    required this.onMarkAsUnwatched,
    this.applyHeroTransition = false,
  });

  final void Function(
    BuildContext context,
    WidgetRef ref,
    String contentId,
    ContentType type,
  )
  onMarkAsUnwatched;
  final bool applyHeroTransition;

  @override
  ConsumerState<HomeContinueWatchingSection> createState() =>
      _HomeContinueWatchingSectionState();
}

class _HomeContinueWatchingSectionState
    extends ConsumerState<HomeContinueWatchingSection> {
  static const Duration _prefetchTimeout = Duration(seconds: 8);
  static const int _maxPrefetchItems = 14;
  static const int _maxPrefetchedUrlMemory = 500;

  final Set<String> _prefetchedBackdrops = <String>{};
  ProviderSubscription<AsyncValue<List<domain.InProgressMedia>>>?
  _inProgressSub;

  @override
  void initState() {
    super.initState();
    _inProgressSub = ref.listenManual(hp.homeInProgressProvider, (_, next) {
      next.whenData(_schedulePrefetch);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _inProgressSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inProgressAsync = ref.watch(hp.homeInProgressProvider);
    final screenType = ScreenTypeResolver.instance.resolve(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final itemLimit = switch (screenType) {
      ScreenType.mobile => HomeLayoutConstants.continueWatchingMobileLimit,
      ScreenType.tablet => HomeLayoutConstants.continueWatchingTabletLimit,
      ScreenType.desktop ||
      ScreenType.tv => HomeLayoutConstants.continueWatchingDesktopLimit,
    };

    return inProgressAsync.when(
      data: (List<domain.InProgressMedia> inProgress) {
        if (inProgress.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return PremiumFeatureGate(
          feature: PremiumFeature.localContinueWatching,
          lockedBuilder: (context) {
            final localizer = MoviPremiumLocalizer.fromBuildContext(context);

            return SliverToBoxAdapter(
              child: HomeFirstSectionTransition(
                enabled: widget.applyHeroTransition,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.homeContinueWatching,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizer.contextualUpsellBody,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 220,
                            child: MoviPrimaryButton(
                              label: localizer.contextualUpsellAction,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const MoviPremiumPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          unlockedBuilder: (context) {
            final section = MoviItemsList(
              title: AppLocalizations.of(context)!.homeContinueWatching,
              itemSpacing: HomeLayoutConstants.itemSpacing,
              estimatedItemWidth: HomeLayoutConstants.continueWatchingCardWidth,
              estimatedItemHeight:
                  HomeLayoutConstants.continueWatchingCardHeight,
              horizontalFocusAlignment: 0.18,
              items: inProgress
                  .take(itemLimit)
                  .map((media) => _buildCard(context, ref, media))
                  .toList(),
            );

            return SliverToBoxAdapter(
              child: HomeFirstSectionTransition(
                enabled: widget.applyHeroTransition,
                child: section,
              ),
            );
          },
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    domain.InProgressMedia media,
  ) {
    if (media.type == ContentType.movie) {
      return ContinueWatchingCard.movie(
        title: media.title,
        backdrop: media.backdrop?.toString(),
        progress: media.progress,
        year: media.year,
        duration: media.duration,
        rating: media.rating,
        onTap: () => unawaited(_openMedia(context, ref, media)),
        onLongPress: () =>
            widget.onMarkAsUnwatched(context, ref, media.contentId, media.type),
      );
    } else {
      final seasonEpisode = media.season != null && media.episode != null
          ? 'S${media.season!.toString().padLeft(2, '0')} E${media.episode!.toString().padLeft(2, '0')}'
          : '';
      return ContinueWatchingCard.episode(
        title: media.episodeTitle ?? media.title,
        backdrop: media.backdrop?.toString(),
        seriesTitle: media.seriesTitle,
        seasonEpisode: seasonEpisode,
        duration: media.duration,
        progress: media.progress,
        onTap: () => unawaited(_openMedia(context, ref, media)),
        onLongPress: () =>
            widget.onMarkAsUnwatched(context, ref, media.contentId, media.type),
      );
    }
  }

  void _schedulePrefetch(List<domain.InProgressMedia> items) {
    final policy = ImageLoadingPolicyService.resolve();
    final useDiskCachePath =
        policy.enableDiskCache &&
        policy.enableCachedNetworkPath &&
        !policy.forceNetworkFallbackOnly;
    final candidates = items
        .map((item) => item.backdrop?.toString().trim())
        .whereType<String>()
        .where(
          (url) =>
              url.isNotEmpty &&
              (url.startsWith('https://') || url.startsWith('http://')),
        )
        .take(_maxPrefetchItems);

    for (final url in candidates) {
      if (_prefetchedBackdrops.length > _maxPrefetchedUrlMemory) {
        _prefetchedBackdrops.clear();
      }
      if (_prefetchedBackdrops.add(url)) {
        unawaited(_prefetchImage(url, useDiskCachePath: useDiskCachePath));
      }
    }
  }

  Future<void> _prefetchImage(
    String url, {
    required bool useDiskCachePath,
  }) async {
    if (useDiskCachePath) {
      final cacheManager = SafeImageCacheManager.tryGet(enabled: true);
      if (cacheManager != null) {
        try {
          await cacheManager.getSingleFile(url).timeout(_prefetchTimeout);
          return;
        } catch (_) {
          // Fallback mémoire si le cache disque échoue.
        }
      }
    }

    if (!mounted) return;
    try {
      await precacheImage(NetworkImage(url), context).timeout(_prefetchTimeout);
    } catch (_) {
      // Aucune propagation: le rendu principal garde ses fallbacks.
    }
  }

  Future<void> _openMedia(
    BuildContext context,
    WidgetRef ref,
    domain.InProgressMedia media,
  ) async {
    final locator = ref.read(slProvider);
    final resolver = locator<IptvContentResolver>();
    final activeSourceIds = ref
        .read(asp.appStateControllerProvider)
        .preferredIptvSourceIds;
    final resolution = await resolver.resolve(
      contentId: media.contentId,
      type: media.type,
      activeSourceIds: activeSourceIds,
    );
    if (!context.mounted) return;
    if (!resolution.isAvailable || resolution.resolvedContentId == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackbarNotAvailableOnSource)),
      );
      return;
    }

    final resolvedId = resolution.resolvedContentId!;
    if (media.type == ContentType.movie) {
      navigateToMovieDetail(
        context,
        ref,
        ContentRouteArgs.movie(resolvedId),
        originRegionId: AppFocusRegionId.homePrimary,
        fallbackRegionId: AppFocusRegionId.homePrimary,
      );
    } else {
      navigateToTvDetail(
        context,
        ref,
        ContentRouteArgs.series(resolvedId),
        originRegionId: AppFocusRegionId.homePrimary,
        fallbackRegionId: AppFocusRegionId.homePrimary,
      );
    }
  }
}

/// Widget pour l'espacement après la section "En cours" si elle est visible.
class HomeContinueWatchingSpacer extends ConsumerWidget {
  const HomeContinueWatchingSpacer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgressAsync = ref.watch(hp.homeInProgressProvider);

    return inProgressAsync.when(
      data: (inProgress) {
        if (inProgress.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return const SliverToBoxAdapter(
          child: SizedBox(height: HomeLayoutConstants.sectionGap),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}
