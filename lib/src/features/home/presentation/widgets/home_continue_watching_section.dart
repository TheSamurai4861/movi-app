import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
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
class HomeContinueWatchingSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
                enabled: applyHeroTransition,
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
              items: inProgress
                  .take(itemLimit)
                  .map((media) => _buildCard(context, ref, media))
                  .toList(),
            );

            return SliverToBoxAdapter(
              child: HomeFirstSectionTransition(
                enabled: applyHeroTransition,
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
            onMarkAsUnwatched(context, ref, media.contentId, media.type),
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
            onMarkAsUnwatched(context, ref, media.contentId, media.type),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pas disponible sur cette source')),
      );
      return;
    }

    final resolvedId = resolution.resolvedContentId!;
    if (media.type == ContentType.movie) {
      navigateToMovieDetail(context, ref, ContentRouteArgs.movie(resolvedId));
    } else {
      navigateToTvDetail(context, ref, ContentRouteArgs.series(resolvedId));
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
