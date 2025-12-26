import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/saga/presentation/providers/saga_detail_providers.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

class SagaDetailPage extends ConsumerWidget {
  const SagaDetailPage({super.key, required this.sagaId});

  final String sagaId;

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes}m';
  }

  Future<void> _playMovie(
    BuildContext context,
    WidgetRef ref,
    String movieId,
  ) async {
    // Pour l'instant, ouvrir la page de détail du film
    navigateToMovieDetail(context, ref, ContentRouteArgs.movie(movieId));
  }

  Future<void> _startSaga(
    BuildContext context,
    WidgetRef ref,
    SagaDetailViewModel viewModel,
  ) async {
    // Trouver le premier film non visionné ou reprendre le film en cours
    final inProgressMovieId = await ref.read(
      sagaInProgressMovieProvider(sagaId).future,
    );
    if (!context.mounted) return;

    if (inProgressMovieId != null) {
      // Reprendre le film en cours
      if (!context.mounted) return;
      await _playMovie(context, ref, inProgressMovieId);
    } else {
      // Commencer par le premier film
      if (!context.mounted) return;
      final movies = viewModel.saga.timeline
          .where((entry) => entry.reference.type == ContentType.movie)
          .toList();
      if (movies.isNotEmpty && context.mounted) {
        await _playMovie(context, ref, movies.first.reference.id);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sagaDetailAsync = ref.watch(sagaDetailProvider(sagaId));
    final inProgressMovieAsync = ref.watch(sagaInProgressMovieProvider(sagaId));
    final isFavoriteAsync = ref.watch(sagaIsFavoriteProvider(sagaId));

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          top: true,
          bottom: true,
          child: sagaDetailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.errorWithMessage(error.toString()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.refresh(sagaDetailProvider(sagaId)),
                    child: Text(AppLocalizations.of(context)!.actionRetry),
                  ),
                ],
              ),
            ),
            data: (viewModel) {
              final movies = viewModel.saga.timeline
                  .where((entry) => entry.reference.type == ContentType.movie)
                  .map((entry) {
                    final ref = entry.reference;
                    return MoviMedia(
                      id: ref.id,
                      title: ref.title.display,
                      poster: ref.poster,
                      year: entry.timelineYear,
                      type: MoviMediaType.movie,
                    );
                  })
                  .toList();

              // Trier par année
              movies.sort((a, b) {
                final yearA = a.year ?? 0;
                final yearB = b.year ?? 0;
                return yearA.compareTo(yearB);
              });

              const heroHeight = 400.0;
              const overlayHeight = 200.0;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: heroHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildHeroImage(context, viewModel.poster),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 100,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF141414),
                                    Color(0x00000000),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 20,
                            right: 20,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => context.pop(),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                      width: 35,
                                      height: 35,
                                      child: Image.asset(AppAssets.iconBack),
                                    ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: overlayHeight,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0xFF141414),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 20,
                        end: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          // Titre de la saga
                          Text(
                            viewModel.saga.title.display,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ) ??
                                const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Nombre de films et durée totale
                          Text(
                            '${AppLocalizations.of(context)!.sagaMovieCount(viewModel.movieCount)} - ${_formatDuration(viewModel.totalDuration)}',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white70,
                                ) ??
                                const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Boutons d'action
                          Row(
                            children: [
                              // Bouton "Commencer maintenant" ou "Poursuivre"
                              Expanded(
                                child: inProgressMovieAsync.when(
                                  data: (inProgressMovieId) {
                                    if (inProgressMovieId != null) {
                                      // Afficher "Poursuivre"
                                      return MoviPrimaryButton(
                                        label: AppLocalizations.of(
                                          context,
                                        )!.sagaContinue,
                                        assetIcon: AppAssets.iconPlay,
                                        onPressed: () =>
                                            _startSaga(context, ref, viewModel),
                                      );
                                    } else {
                                      // Afficher "Commencer maintenant"
                                      return MoviPrimaryButton(
                                        label: AppLocalizations.of(
                                          context,
                                        )!.sagaStartNow,
                                        assetIcon: AppAssets.iconPlay,
                                        onPressed: () =>
                                            _startSaga(context, ref, viewModel),
                                      );
                                    }
                                  },
                                  loading: () => MoviPrimaryButton(
                                    label: AppLocalizations.of(
                                      context,
                                    )!.sagaStartNow,
                                    assetIcon: AppAssets.iconPlay,
                                    onPressed: () {},
                                  ),
                                  error: (_, __) => MoviPrimaryButton(
                                    label: AppLocalizations.of(
                                      context,
                                    )!.sagaStartNow,
                                    assetIcon: AppAssets.iconPlay,
                                    onPressed: () =>
                                        _startSaga(context, ref, viewModel),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Bouton favoris
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: isFavoriteAsync.when(
                                  data: (isFavorite) => MoviFavoriteButton(
                                    isFavorite: isFavorite,
                                    onPressed: () async {
                                      await ref
                                          .read(
                                            sagaToggleFavoriteProvider.notifier,
                                          )
                                          .toggle(
                                            sagaId,
                                            SagaSummary(
                                              id: viewModel.saga.id,
                                              tmdbId: viewModel.saga.tmdbId,
                                              title: viewModel.saga.title,
                                              cover: viewModel.poster,
                                            ),
                                          );
                                    },
                                  ),
                                  loading: () => MoviFavoriteButton(
                                    isFavorite: true,
                                    onPressed: () {},
                                  ),
                                  error: (_, __) => MoviFavoriteButton(
                                    isFavorite: true,
                                    onPressed: () {},
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Liste des films
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 20,
                        end: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.sagaMoviesList,
                            style:
                                Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.white) ??
                                const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 16),
                          // Liste horizontale des films
                          Consumer(
                            builder: (context, ref, _) {
                              final availabilityAsync = ref.watch(
                                sagaMoviesAvailabilityProvider(sagaId),
                              );
                              return availabilityAsync.when(
                                data: (availability) {
                                  return SizedBox(
                                    height: 258,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: movies.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 16),
                                      itemBuilder: (context, index) {
                                        final movie = movies[index];
                                        final movieId = int.tryParse(movie.id);
                                        final isAvailable =
                                            movieId != null &&
                                            (availability[movieId] ?? false);
                                        return _SagaMovieCard(
                                          media: movie,
                                          isAvailable: isAvailable,
                                        );
                                      },
                                    ),
                                  );
                                },
                                loading: () => const SizedBox(
                                  height: 258,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (_, __) => SizedBox(
                                  height: 258,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: movies.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 16),
                                    itemBuilder: (context, index) {
                                      final movie = movies[index];
                                      return MoviMediaCard(
                                        media: movie,
                                        heroTag: 'saga_movie_${movie.id}',
                                        onTap: (m) => context.push(
                                          AppRouteNames.movie,
                                          extra: m,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, Uri? poster) {
    if (poster == null) {
      return MoviPlaceholderCard(
        type: PlaceholderType.movie,
        fit: BoxFit.cover,
        alignment: const Alignment(0.0, -0.5),
        borderRadius: BorderRadius.zero,
      );
    }
    final mq = MediaQuery.of(context);
    final int rawPx = (mq.size.width * mq.devicePixelRatio).round();
    final int cacheWidth = rawPx.clamp(480, 1920);
    return Image.network(
      poster.toString(),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      alignment: const Alignment(0.0, -0.5),
      errorBuilder: (_, __, ___) => MoviPlaceholderCard(
        type: PlaceholderType.movie,
        fit: BoxFit.cover,
        alignment: const Alignment(0.0, -0.5),
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}

class _SagaMovieCard extends ConsumerWidget {
  const _SagaMovieCard({required this.media, required this.isAvailable});

  final MoviMedia media;
  final bool isAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: ColorFiltered(
        colorFilter: isAvailable
            ? const ColorFilter.mode(Colors.transparent, BlendMode.color)
            : const ColorFilter.matrix([
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
        child: MoviMediaCard(
          media: media,
          heroTag: 'saga_movie_${media.id}',
          onTap: isAvailable
              ? (mm) =>
                  navigateToMovieDetail(context, ref, ContentRouteArgs.movie(mm.id))
              : null,
        ),
      ),
    );
  }
}
