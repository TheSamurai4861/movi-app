import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/data/repositories/tv_repository_impl.dart';
import 'package:movi/src/features/tv/data/datasources/tv_local_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/utils/title_cleaner.dart';
import 'package:movi/src/shared/domain/services/similarity_service.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';

/// Provider pour TvRepository avec userId actuel
final tvRepositoryProvider = Provider<TvRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return TvRepositoryImpl(
    ref.watch(slProvider)<TmdbTvRemoteDataSource>(),
    ref.watch(slProvider)<TmdbImageResolver>(),
    ref.watch(slProvider)<WatchlistLocalRepository>(),
    ref.watch(slProvider)<TvLocalDataSource>(),
    ref.watch(slProvider)<ContinueWatchingLocalRepository>(),
    ref.watch(slProvider)<AppStateController>(),
    userId: userId,
  );
});

/// Provider pour vérifier si une série est dans les favoris
final tvIsFavoriteProvider =
    FutureProvider.family<bool, String>((ref, seriesId) async {
  final repo = ref.watch(tvRepositoryProvider);
  return await repo.isInWatchlist(SeriesId(seriesId));
});

/// Notifier pour basculer le statut favori d'une série
class TvToggleFavoriteNotifier extends Notifier<void> {
  @override
  void build() {
    // État initial vide, la méthode toggle() fait le travail
  }

  Future<void> toggle(String seriesId) async {
    final repo = ref.read(tvRepositoryProvider);
    final isFavorite = await ref.read(tvIsFavoriteProvider(seriesId).future);
    await repo.setWatchlist(SeriesId(seriesId), saved: !isFavorite);
    ref.invalidate(tvIsFavoriteProvider(seriesId));
    // Invalider les playlists de la bibliothèque pour mettre à jour les favoris
    ref.invalidate(libraryPlaylistsProvider);
  }
}

/// Provider pour basculer le statut favori d'une série
final tvToggleFavoriteProvider =
    NotifierProvider<TvToggleFavoriteNotifier, void>(
  TvToggleFavoriteNotifier.new,
);

final tvDetailControllerProvider =
    FutureProvider.family<TvDetailViewModel, String>((ref, seriesId) async {
      final lang = ref.watch(currentLanguageCodeProvider);
      final locator = ref.watch(slProvider);
      final logger = locator<AppLogger>();
      final repo = ref.watch(tvRepositoryProvider);
      final id = SeriesId(seriesId);
      final t0 = DateTime.now();
      final detail = await repo.getShow(id);
      final t1 = DateTime.now();
      logger.debug(
        'tv_detail fetch id=$seriesId lang=$lang duration: ${t1.difference(t0).inMilliseconds}ms',
        category: 'tv_detail',
      );
      return TvDetailViewModel.fromDomain(detail: detail, language: lang);
    });

/// Provider pour le chargement progressif des séries avec recherche par titre
final tvDetailProgressiveControllerProvider =
    NotifierProvider.family<
      TvDetailProgressiveController,
      AsyncValue<TvDetailViewModel>,
      String
    >((seriesId) => TvDetailProgressiveController(seriesId));

class TvDetailProgressiveController
    extends Notifier<AsyncValue<TvDetailViewModel>> {
  TvDetailProgressiveController(this._seriesId);

  final String _seriesId;

  static const int _prioritySeasonsCount = 3;

  @override
  AsyncValue<TvDetailViewModel> build() {
    _loadProgressive();
    return const AsyncValue.loading();
  }

  Future<void> _loadProgressive() async {
    try {
      final lang = ref.read(currentLanguageCodeProvider);
      final locator = ref.read(slProvider);
      final logger = locator<AppLogger>();
      final repo = ref.read(tvRepositoryProvider);
      final iptvLocal = locator<IptvLocalRepository>();
      final id = SeriesId(_seriesId);

      TvShow? detailLiteNullable;
      bool isSeriesAvailable = false;

      // Vérifier si c'est un ID Xtream
      if (_seriesId.startsWith('xtream:')) {
        // Pour les séries Xtream, charger depuis la playlist locale
        final streamIdStr = _seriesId.substring(7); // "xtream:".length = 7
        final streamId = int.tryParse(streamIdStr);

        if (streamId == null) {
          throw FormatException('Invalid Xtream streamId: $streamIdStr');
        }
        // Chercher la série dans les playlists IPTV
        final accounts = await iptvLocal.getAccounts();
        XtreamPlaylistItem? xtreamItem;

        for (final account in accounts) {
          final playlists = await iptvLocal.getPlaylists(account.id);
          for (final playlist in playlists) {
            if (playlist.type != XtreamPlaylistType.series) continue;
            final found = playlist.items
                .where(
                  (item) =>
                      item.streamId == streamId &&
                      item.type == XtreamPlaylistItemType.series,
                )
                .firstOrNull;
            if (found != null) {
              xtreamItem = found;
              break;
            }
          }
          if (xtreamItem != null) break;
        }

        if (xtreamItem == null) {
          throw StateError(
            'Series xtream:$streamId not found in IPTV playlists',
          );
        }

        // Si pas de tmdbId, essayer de le trouver via recherche TMDB
        int? foundTmdbId = xtreamItem.tmdbId;
        foundTmdbId ??= await _searchTmdbIdForXtreamItem(
            xtreamItem,
            lang,
            locator,
            logger,
          );

        // Si on a trouvé un tmdbId, charger depuis TMDB
        if (foundTmdbId != null) {
          try {
            final tmdbShow = await repo.getShow(
              SeriesId(foundTmdbId.toString()),
            );
            // Mettre à jour avec l'ID Xtream original
            detailLiteNullable = TvShow(
              id: id, // Garder l'ID Xtream original
              tmdbId: tmdbShow.tmdbId,
              title: tmdbShow.title,
              synopsis: tmdbShow.synopsis,
              poster: tmdbShow.poster,
              backdrop: tmdbShow.backdrop,
              firstAirDate: tmdbShow.firstAirDate,
              lastAirDate: tmdbShow.lastAirDate,
              status: tmdbShow.status,
              rating: tmdbShow.rating,
              voteAverage: tmdbShow.voteAverage,
              genres: tmdbShow.genres,
              cast: tmdbShow.cast,
              creators: tmdbShow.creators,
              seasons: tmdbShow.seasons,
            );
          } catch (e) {
            logger.warn(
              'Failed to load TMDB show for xtream:$streamId (tmdbId=$foundTmdbId): $e',
              category: 'tv_detail',
            );
            // Fallback sur les données Xtream
            foundTmdbId = null;
          }
        }

        // Si toujours pas de tmdbId, utiliser les données Xtream minimales
        if (foundTmdbId == null) {
          final images = locator<TmdbImageResolver>();
          final poster = images.poster(xtreamItem.posterUrl);
          if (poster == null) {
            throw StateError('Series xtream:$streamId missing poster');
          }

          detailLiteNullable = TvShow(
            id: id,
            tmdbId: null,
            title: MediaTitle(xtreamItem.title),
            synopsis: Synopsis(xtreamItem.overview ?? ''),
            poster: poster,
            backdrop: null,
            firstAirDate: xtreamItem.releaseYear != null
                ? DateTime(xtreamItem.releaseYear!, 1, 1)
                : null,
            lastAirDate: null,
            status: null,
            rating: null,
            voteAverage: xtreamItem.rating,
            genres: const [],
            cast: const [],
            creators: const [],
            seasons:
                const [], // Pas de saisons pour les séries Xtream sans tmdbId
          );
        }

        // Les séries Xtream sont toujours disponibles dans la playlist
        isSeriesAvailable = true;
      } else {
        // Charger depuis TMDB pour les IDs normaux (version lite sans épisodes)
        final t0 = DateTime.now();
        detailLiteNullable = await repo.getShowLite(id);
        final t1 = DateTime.now();
        logger.debug(
          'tv_detail lite fetch id=$_seriesId lang=$lang duration: ${t1.difference(t0).inMilliseconds}ms',
          category: 'tv_detail',
        );

        // Vérifier si la série est disponible dans la playlist IPTV
        final availableSeriesIds = await iptvLocal.getAvailableTmdbIds(
          type: XtreamPlaylistItemType.series,
        );
        isSeriesAvailable =
            detailLiteNullable.tmdbId != null &&
            availableSeriesIds.contains(detailLiteNullable.tmdbId);
      }

      // S'assurer que detailLite est initialisé
      final detailLite = detailLiteNullable!;

      // Créer le ViewModel initial avec saisons sans épisodes
      final vm = TvDetailViewModel.fromDomain(
        detail: detailLite,
        language: lang,
        isAvailableInPlaylist: isSeriesAvailable,
      );
      state = AsyncValue.data(vm);

      // Charger les épisodes seulement si la série a des saisons et un tmdbId
      // (les séries Xtream sans tmdbId n'ont pas de saisons chargées depuis TMDB)
      if (vm.seasons.isNotEmpty && detailLite.tmdbId != null) {
        // Charger immédiatement les épisodes des premières saisons en priorité
        final prioritySeasons = vm.seasons.take(_prioritySeasonsCount).toList();
        if (prioritySeasons.isNotEmpty) {
          await _loadPrioritySeasons(
            repo,
            id,
            vm,
            prioritySeasons,
            isSeriesAvailable,
          );
        }

        // Charger les autres saisons progressivement en arrière-plan
        final remainingSeasons = vm.seasons
            .skip(_prioritySeasonsCount)
            .toList();
        if (remainingSeasons.isNotEmpty) {
          unawaited(
            _loadRemainingSeasons(
              repo,
              id,
              remainingSeasons,
              isSeriesAvailable,
            ),
          );
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Recherche un tmdbId pour un item Xtream en utilisant le titre nettoyé
  Future<int?> _searchTmdbIdForXtreamItem(
    XtreamPlaylistItem item,
    String language,
    GetIt locator,
    AppLogger logger,
  ) async {
    try {
      // Nettoyer le titre
      final cleaned = TitleCleaner.cleanWithYear(item.title);
      if (cleaned.cleanedTitle.isEmpty) {
        return null;
      }

      // Rechercher dans TMDB
      final remote = locator<TmdbTvRemoteDataSource>();
      final searchResults = await remote.searchShows(
        cleaned.cleanedTitle,
        language: language,
        page: 1,
      );

      if (searchResults.isEmpty) {
        return null;
      }

      // Utiliser le service de similarité pour trouver le meilleur match
      final similarity = locator<SimilarityService>();
      double bestScore = 0.0;
      int? bestMatchId;

      for (final result in searchResults) {
        // Calculer le score de similarité
        final resultTitle = result.name;
        final score = similarity.score(cleaned.cleanedTitle, resultTitle);

        // Bonus si l'année correspond
        if (cleaned.year != null && result.firstAirDate != null) {
          try {
            final resultYear = DateTime.parse(result.firstAirDate!).year;
            if (resultYear == cleaned.year) {
              // Bonus de 0.1 si l'année correspond
              final adjustedScore = (score + 0.1).clamp(0.0, 1.0);
              if (adjustedScore > bestScore) {
                bestScore = adjustedScore;
                bestMatchId = result.id;
              }
              continue;
            }
          } catch (_) {
            // Ignorer les erreurs de parsing de date
          }
        }

        if (score > bestScore) {
          bestScore = score;
          bestMatchId = result.id;
        }
      }

      // Seuil minimum de 0.6 pour accepter un match
      if (bestScore >= 0.6 && bestMatchId != null) {
        logger.debug(
          'Found TMDB match for Xtream item "${item.title}": tmdbId=$bestMatchId (score=$bestScore)',
          category: 'tv_detail',
        );
        return bestMatchId;
      }

      return null;
    } catch (e) {
      logger.warn(
        'Error searching TMDB for Xtream item "${item.title}": $e',
        category: 'tv_detail',
      );
      return null;
    }
  }

  Future<void> _loadPrioritySeasons(
    TvRepository repo,
    SeriesId id,
    TvDetailViewModel vm,
    List<SeasonViewModel> prioritySeasons,
    bool isSeriesAvailable,
  ) async {
    // Commencer avec toutes les saisons initiales
    final updatedSeasons = List<SeasonViewModel>.from(vm.seasons);

    for (final season in prioritySeasons) {
      try {
        // Trouver l'index de la saison dans la liste complète
        final seasonIndex = updatedSeasons.indexWhere(
          (s) => s.seasonNumber == season.seasonNumber,
        );
        if (seasonIndex == -1) continue;

        // Marquer comme en cours de chargement
        updatedSeasons[seasonIndex] = updatedSeasons[seasonIndex].copyWith(
          isLoadingEpisodes: true,
        );
        _updateViewModelWithSeasons(vm, updatedSeasons);

        // Charger les épisodes
        final seasonId = SeasonId(season.seasonNumber.toString());
        final episodes = await repo.getEpisodes(id, seasonId);
        final now = DateTime.now();
        final episodesVm = episodes
            .map((e) {
              // Un épisode est disponible seulement si :
              // 1. La série est disponible dans la playlist ET
              // 2. La date de diffusion n'est pas dans le futur
              final isAvailable =
                  isSeriesAvailable &&
                  (e.airDate == null ||
                      e.airDate!.isBefore(now) ||
                      e.airDate!.isAtSameMomentAs(now));
              return EpisodeViewModel(
                id: e.id.value,
                episodeNumber: e.episodeNumber,
                title: e.title.display,
                overview: e.overview?.value,
                runtime: e.runtime,
                airDate: e.airDate,
                still: e.still,
                voteAverage: e.voteAverage,
                isAvailableInPlaylist: isAvailable,
              );
            })
            .toList(growable: false);

        // Mettre à jour avec les épisodes chargés
        final loadedSeason = updatedSeasons[seasonIndex].copyWith(
          episodes: episodesVm,
          isLoadingEpisodes: false,
        );
        updatedSeasons[seasonIndex] = loadedSeason;
        _updateViewModelWithSeasons(vm, updatedSeasons);
      } catch (e) {
        // En cas d'erreur, garder la saison sans épisodes
        final seasonIndex = updatedSeasons.indexWhere(
          (s) => s.seasonNumber == season.seasonNumber,
        );
        if (seasonIndex != -1) {
          updatedSeasons[seasonIndex] = updatedSeasons[seasonIndex].copyWith(
            isLoadingEpisodes: false,
          );
          _updateViewModelWithSeasons(vm, updatedSeasons);
        }
      }
    }
  }

  Future<void> _loadRemainingSeasons(
    TvRepository repo,
    SeriesId id,
    List<SeasonViewModel> remainingSeasons,
    bool isSeriesAvailable,
  ) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    final vm = currentState.value!;
    final updatedSeasons = List<SeasonViewModel>.from(vm.seasons);

    for (final season in remainingSeasons) {
      try {
        // Trouver l'index de la saison dans la liste
        final seasonIndex = updatedSeasons.indexWhere(
          (s) => s.seasonNumber == season.seasonNumber,
        );
        if (seasonIndex == -1) continue;

        // Marquer comme en cours de chargement
        updatedSeasons[seasonIndex] = updatedSeasons[seasonIndex].copyWith(
          isLoadingEpisodes: true,
        );
        _updateViewModelWithSeasons(vm, updatedSeasons);

        // Charger les épisodes
        final seasonId = SeasonId(season.seasonNumber.toString());
        final episodes = await repo.getEpisodes(id, seasonId);
        final now = DateTime.now();
        final episodesVm = episodes
            .map((e) {
              // Un épisode est disponible seulement si :
              // 1. La série est disponible dans la playlist ET
              // 2. La date de diffusion n'est pas dans le futur
              final isAvailable =
                  isSeriesAvailable &&
                  (e.airDate == null ||
                      e.airDate!.isBefore(now) ||
                      e.airDate!.isAtSameMomentAs(now));
              return EpisodeViewModel(
                id: e.id.value,
                episodeNumber: e.episodeNumber,
                title: e.title.display,
                overview: e.overview?.value,
                runtime: e.runtime,
                airDate: e.airDate,
                still: e.still,
                voteAverage: e.voteAverage,
                isAvailableInPlaylist: isAvailable,
              );
            })
            .toList(growable: false);

        // Mettre à jour avec les épisodes chargés
        updatedSeasons[seasonIndex] = updatedSeasons[seasonIndex].copyWith(
          episodes: episodesVm,
          isLoadingEpisodes: false,
        );
        _updateViewModelWithSeasons(vm, updatedSeasons);
      } catch (e) {
        // En cas d'erreur, garder la saison sans épisodes
        final seasonIndex = updatedSeasons.indexWhere(
          (s) => s.seasonNumber == season.seasonNumber,
        );
        if (seasonIndex != -1) {
          updatedSeasons[seasonIndex] = updatedSeasons[seasonIndex].copyWith(
            isLoadingEpisodes: false,
          );
          _updateViewModelWithSeasons(vm, updatedSeasons);
        }
      }
    }
  }

  void _updateViewModelWithSeasons(
    TvDetailViewModel vm,
    List<SeasonViewModel> updatedSeasons,
  ) {
    // Filtrer les saisons : garder seulement celles qui :
    // 1. Sont en cours de chargement, OU
    // 2. N'ont pas encore été chargées (épisodes vides mais saison initiale), OU
    // 3. Ont au moins un épisode disponible dans la playlist
    final availableSeasons = updatedSeasons
        .where((season) {
          if (season.isLoadingEpisodes) return true;
          // Si la saison n'a pas encore été chargée (épisodes vides), la garder
          if (season.episodes.isEmpty) return true;
          // Si la saison a été chargée, vérifier qu'elle a au moins un épisode disponible
          return season.episodes.any(
            (episode) => episode.isAvailableInPlaylist,
          );
        })
        .toList(growable: false);

    final updatedVm = TvDetailViewModel(
      title: vm.title,
      yearText: vm.yearText,
      seasonsCountText: vm.seasonsCountText,
      ratingText: vm.ratingText,
      overviewText: vm.overviewText,
      cast: vm.cast,
      seasons: availableSeasons,
      poster: vm.poster,
      backdrop: vm.backdrop,
      language: vm.language,
    );

    state = AsyncValue.data(updatedVm);
  }
}
