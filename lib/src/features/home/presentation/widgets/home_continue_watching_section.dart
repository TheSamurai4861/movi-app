import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/movi_items_list.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/home/domain/entities/in_progress_media.dart'
    as domain;
import 'package:movi/src/features/home/presentation/widgets/continue_watching_card.dart';
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/services/iptv_content_resolver.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

/// Section affichant les médias en cours de lecture.
class HomeContinueWatchingSection extends ConsumerWidget {
  const HomeContinueWatchingSection({
    super.key,
    required this.onMarkAsUnwatched,
  });

  final void Function(
    BuildContext context,
    WidgetRef ref,
    String contentId,
    ContentType type,
  )
  onMarkAsUnwatched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgressAsync = ref.watch(hp.homeInProgressProvider);

    return inProgressAsync.when(
      data: (List<domain.InProgressMedia> inProgress) {
        if (inProgress.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: MoviItemsList(
            title: AppLocalizations.of(context)!.homeContinueWatching,
            itemSpacing: HomeLayoutConstants.itemSpacing,
            estimatedItemWidth: HomeLayoutConstants.continueWatchingCardWidth,
            estimatedItemHeight: HomeLayoutConstants.continueWatchingCardHeight,
            items: inProgress
                .take(HomeLayoutConstants.continueWatchingLimit)
                .map((media) => _buildCard(context, ref, media))
                .toList(),
          ),
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
    final activeSourceIds =
        ref.read(asp.appStateControllerProvider).preferredIptvSourceIds;
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
