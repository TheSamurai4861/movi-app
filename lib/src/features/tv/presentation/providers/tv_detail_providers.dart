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
import 'package:movi/src/features/iptv/data/datasources/xtream_remote_data_source.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/services/tmdb_id_resolver_service.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/tv/domain/usecases/ensure_tv_enrichment.dart';
import 'package:movi/src/features/tv/domain/usecases/resolve_episode_playback_selection.dart';

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
final tvIsFavoriteProvider = FutureProvider.family<bool, String>((
  ref,
  seriesId,
) async {
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

final ensureTvEnrichmentUseCaseProvider = Provider<EnsureTvEnrichment>(
  (ref) => ref.watch(slProvider)<EnsureTvEnrichment>(),
);

final resolveEpisodePlaybackSelectionUseCaseProvider =
    Provider<ResolveEpisodePlaybackSelection>(
      (ref) => ref.watch(slProvider)<ResolveEpisodePlaybackSelection>(),
    );

/// Provider qui vérifie et déclenche l'enrichissement d'une série si nécessaire.
/// Retourne `true` si un enrichissement a été déclenché, `false` si déjà complet.
/// Charge également les épisodes Xtream en arrière-plan.
final tvDetailEnrichmentProvider = FutureProvider.family<bool, String>((
  ref,
  seriesId,
) async {
  final logger = ref.watch(slProvider)<AppLogger>();
  logger.debug(
    '📺 [PROVIDER] tvDetailEnrichmentProvider appelé pour seriesId=$seriesId',
    category: 'tv_enrichment',
  );
  final useCase = ref.watch(ensureTvEnrichmentUseCaseProvider);
  final result = await useCase(SeriesId(seriesId));
  logger.debug(
    '📺 [PROVIDER] tvDetailEnrichmentProvider terminé pour seriesId=$seriesId, result=$result',
    category: 'tv_enrichment',
  );
  return result;
});

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
        if (foundTmdbId == null) {
          final resolver = locator<TmdbIdResolverService>();
          // La recherche améliorée essaie d'abord IMDB si disponible, puis recherche par titre
          foundTmdbId = await resolver.enhancedSearchTmdbId(
            item: xtreamItem,
            language: lang,
          );
        }

        // Si on a trouvé un tmdbId, charger depuis TMDB (version lite pour plus de rapidité)
        if (foundTmdbId != null) {
          try {
            final tmdbShow = await repo.getShowLite(
              SeriesId(foundTmdbId.toString()),
            );

            // Charger les épisodes Xtream avant de continuer (attendre le chargement)
            // Les épisodes doivent être disponibles depuis Xtream pour le streaming
            await _loadXtreamEpisodesForSeries(
              streamId: streamId,
              accountId: xtreamItem.accountId,
              iptvLocal: iptvLocal,
              locator: locator,
              logger: logger,
            );

            // Mettre à jour avec l'ID Xtream original
            detailLiteNullable = TvShow(
              id: id, // Garder l'ID Xtream original
              tmdbId: tmdbShow.tmdbId,
              title: tmdbShow.title,
              synopsis: tmdbShow.synopsis,
              poster: tmdbShow.poster,
              posterBackground: tmdbShow.posterBackground,
              backdrop: tmdbShow.backdrop,
              firstAirDate: tmdbShow.firstAirDate,
              lastAirDate: tmdbShow.lastAirDate,
              status: tmdbShow.status,
              rating: tmdbShow.rating,
              voteAverage: tmdbShow.voteAverage,
              genres: tmdbShow.genres,
              cast: tmdbShow.cast,
              creators: tmdbShow.creators,
              seasons: tmdbShow
                  .seasons, // Saisons sans épisodes, seront chargées progressivement
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
          // xtreamItem ne peut pas être null ici car on a vérifié plus haut
          final item = xtreamItem;
          final images = locator<TmdbImageResolver>();
          final poster = images.poster(item.posterUrl);
          if (poster == null) {
            throw StateError('Series xtream:$streamId missing poster');
          }

          // Charger les saisons depuis IptvLocalRepository ou depuis l'API si le cache est vide
          List<Season> xtreamSeasons = [];
          try {
            var allEpisodes = await iptvLocal.getAllEpisodesForSeries(
              accountId: item.accountId,
              seriesId: streamId,
            );

            // Si le cache est vide, charger depuis l'API Xtream
            if (allEpisodes.isEmpty) {
              logger.debug(
                'Cache vide pour série $streamId, chargement depuis l\'API Xtream',
                category: 'tv_detail',
              );

              try {
                final remote = locator<XtreamRemoteDataSource>();
                final vault = locator<CredentialsVault>();
                final accounts = await iptvLocal.getAccounts();
                if (accounts.isEmpty) {
                  logger.warn(
                    'Aucun compte Xtream disponible',
                    category: 'tv_detail',
                  );
                } else {
                  final account = accounts.firstWhere(
                    (a) => a.id == item.accountId,
                    orElse: () => accounts.first,
                  );

                  // Récupérer le mot de passe
                  String? password = await vault.readPassword(account.id);
                  if (password == null || password.isEmpty) {
                    final hostKey =
                        '${account.endpoint.host}_${account.username}'
                            .toLowerCase();
                    if (hostKey != account.id) {
                      password = await vault.readPassword(hostKey);
                    }
                  }
                  if (password == null || password.isEmpty) {
                    final rawUrlKey =
                        '${account.endpoint.toRawUrl()}_${account.username}'
                            .toLowerCase();
                    if (rawUrlKey != account.id) {
                      password = await vault.readPassword(rawUrlKey);
                    }
                  }

                  if (password != null && password.isNotEmpty) {
                    final request = XtreamAccountRequest(
                      endpoint: account.endpoint,
                      username: account.username,
                      password: password,
                    );

                    // Charger toutes les informations de la série depuis l'API
                    final seriesInfo = await remote.getSeriesInfo(
                      request,
                      seriesId: streamId,
                    );

                    // Parser tous les épisodes depuis la réponse API
                    allEpisodes = _parseEpisodesFromSeriesInfo(
                      seriesInfo,
                      logger: logger,
                    );

                    // Sauvegarder en cache pour les prochaines fois
                    if (allEpisodes.isNotEmpty) {
                      // Compter le total d'épisodes pour le log
                      final totalEpisodes = allEpisodes.values.fold<int>(
                        0,
                        (sum, episodes) => sum + episodes.length,
                      );
                      logger.debug(
                        'Episodes parses depuis l\'API pour serie $streamId: ${allEpisodes.length} saisons, $totalEpisodes episodes',
                        category: 'tv_detail',
                      );

                      await iptvLocal.saveEpisodes(
                        accountId: item.accountId,
                        seriesId: streamId,
                        episodes: allEpisodes,
                      );
                      logger.debug(
                        'Episodes sauvegardes en cache pour serie $streamId',
                        category: 'tv_detail',
                      );

                      // Vérifier que les épisodes sont bien sauvegardés
                      final firstSeason = allEpisodes.keys.firstOrNull;
                      if (firstSeason != null) {
                        final firstEpisode =
                            allEpisodes[firstSeason]!.keys.firstOrNull;
                        if (firstEpisode != null) {
                          final testData = await iptvLocal.getEpisodeData(
                            accountId: item.accountId,
                            seriesId: streamId,
                            seasonNumber: firstSeason,
                            episodeNumber: firstEpisode,
                          );
                          if (testData != null) {
                            logger.debug(
                              'Vérification cache: épisode S$firstSeason E$firstEpisode trouvé avec episodeId=${testData.episodeId}',
                              category: 'tv_detail',
                            );
                          } else {
                            logger.warn(
                              'Vérification cache: épisode S$firstSeason E$firstEpisode NON trouvé après sauvegarde!',
                              category: 'tv_detail',
                            );
                          }
                        }
                      }
                    } else {
                      logger.warn(
                        'Aucun épisode parsé depuis l\'API pour série $streamId',
                        category: 'tv_detail',
                      );
                    }
                  } else {
                    logger.warn(
                      'Impossible de récupérer le mot de passe pour le compte ${account.id}',
                      category: 'tv_detail',
                    );
                  }
                }
              } catch (e) {
                logger.warn(
                  'Erreur lors du chargement des épisodes depuis l\'API Xtream pour série $streamId: $e',
                  category: 'tv_detail',
                );
                // Continuer sans épisodes si le chargement API échoue
              }
            }

            // Mapper les épisodes en saisons
            xtreamSeasons = _mapXtreamEpisodesToSeasons(allEpisodes);

            // S'assurer que les épisodes sont bien sauvegardés avant de continuer
            if (allEpisodes.isNotEmpty) {
              logger.debug(
                'Épisodes mappés en ${xtreamSeasons.length} saisons pour série $streamId',
                category: 'tv_detail',
              );
            }
          } catch (e) {
            logger.warn(
              'Failed to load Xtream episodes for series $streamId: $e',
              category: 'tv_detail',
            );
            // Continuer sans saisons si le chargement échoue
          }

          detailLiteNullable = TvShow(
            id: id,
            tmdbId: null,
            title: MediaTitle(xtreamItem.title),
            synopsis: Synopsis(xtreamItem.overview ?? ''),
            poster: poster,
            posterBackground: null,
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
            seasons: xtreamSeasons,
          );
        }

        // Les séries Xtream sont toujours disponibles dans la playlist
        isSeriesAvailable = true;
      } else {
        // Charger depuis TMDB pour les IDs normaux (version lite sans épisodes)
        try {
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

          // Si la série est disponible dans la playlist, charger les épisodes Xtream en arrière-plan
          if (isSeriesAvailable && detailLiteNullable.tmdbId != null) {
            // Trouver l'item Xtream correspondant pour obtenir le streamId et accountId
            final tmdbId = detailLiteNullable.tmdbId!;
            final accounts = await iptvLocal.getAccounts();
            for (final account in accounts) {
              final playlists = await iptvLocal.getPlaylists(account.id);
              for (final playlist in playlists) {
                if (playlist.type != XtreamPlaylistType.series) continue;
                final found = playlist.items
                    .where(
                      (item) =>
                          item.tmdbId == tmdbId &&
                          item.type == XtreamPlaylistItemType.series &&
                          item.streamId > 0,
                    )
                    .firstOrNull;
                if (found != null) {
                  // Charger les épisodes Xtream avant de continuer (attendre le chargement)
                  await _loadXtreamEpisodesForSeries(
                    streamId: found.streamId,
                    accountId: found.accountId,
                    iptvLocal: iptvLocal,
                    locator: locator,
                    logger: logger,
                  );
                  break;
                }
              }
            }
          }
        } catch (e) {
          logger.warn(
            'Failed to load TMDB show for id=$_seriesId: $e',
            category: 'tv_detail',
          );
          // Re-throw pour que l'erreur soit gérée par le catch global
          rethrow;
        }
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

  Future<void> reloadSeasonEpisodes(int seasonNumber) async {
    final vm = state.value;
    if (vm == null) return;
    try {
      final repo = ref.read(tvRepositoryProvider);
      final id = SeriesId(_seriesId);
      final seasonIndex = vm.seasons.indexWhere(
        (s) => s.seasonNumber == seasonNumber,
      );
      if (seasonIndex == -1) return;

      final updatedSeasons = List<SeasonViewModel>.from(vm.seasons);
      updatedSeasons[seasonIndex] = updatedSeasons[seasonIndex].copyWith(
        isLoadingEpisodes: true,
      );
      state = AsyncValue.data(
        TvDetailViewModel(
          title: vm.title,
          yearText: vm.yearText,
          seasonsCountText: vm.seasonsCountText,
          ratingText: vm.ratingText,
          overviewText: vm.overviewText,
          cast: vm.cast,
          seasons: updatedSeasons,
          poster: vm.poster,
          posterBackground: vm.posterBackground,
          backdrop: vm.backdrop,
          language: vm.language,
        ),
      );

      final seasonId = SeasonId(seasonNumber.toString());
      final episodes = await repo.getEpisodes(id, seasonId);
      final now = DateTime.now();
      final episodesVm = episodes
          .map(
            (e) => EpisodeViewModel(
              id: e.id.value,
              episodeNumber: e.episodeNumber,
              title: e.title.display,
              overview: e.overview?.value,
              runtime: e.runtime,
              airDate: e.airDate,
              still: e.still,
              voteAverage: e.voteAverage,
              isAvailableInPlaylist:
                  e.airDate == null || e.airDate!.isBefore(now),
            ),
          )
          .toList(growable: false);

      updatedSeasons[seasonIndex] = updatedSeasons[seasonIndex].copyWith(
        episodes: episodesVm,
        isLoadingEpisodes: false,
      );
      state = AsyncValue.data(
        TvDetailViewModel(
          title: vm.title,
          yearText: vm.yearText,
          seasonsCountText: vm.seasonsCountText,
          ratingText: vm.ratingText,
          overviewText: vm.overviewText,
          cast: vm.cast,
          seasons: updatedSeasons,
          poster: vm.poster,
          posterBackground: vm.posterBackground,
          backdrop: vm.backdrop,
          language: vm.language,
        ),
      );
    } catch (e) {
      final vm = state.value;
      if (vm != null) {
        final updatedSeasons = vm.seasons
            .map(
              (s) => s.seasonNumber == seasonNumber
                  ? s.copyWith(isLoadingEpisodes: false)
                  : s,
            )
            .toList();
        state = AsyncValue.data(
          TvDetailViewModel(
            title: vm.title,
            yearText: vm.yearText,
            seasonsCountText: vm.seasonsCountText,
            ratingText: vm.ratingText,
            overviewText: vm.overviewText,
            cast: vm.cast,
            seasons: updatedSeasons,
            poster: vm.poster,
            posterBackground: vm.posterBackground,
            backdrop: vm.backdrop,
            language: vm.language,
          ),
        );
      }
    }
  }

  /// Charge les épisodes Xtream pour une série (utilisé même quand on charge depuis TMDB)
  Future<void> _loadXtreamEpisodesForSeries({
    required int streamId,
    required String accountId,
    required IptvLocalRepository iptvLocal,
    required GetIt locator,
    required AppLogger logger,
  }) async {
    try {
      // Vérifier d'abord si les épisodes sont déjà en cache
      var allEpisodes = await iptvLocal.getAllEpisodesForSeries(
        accountId: accountId,
        seriesId: streamId,
      );

      // Si le cache est vide, charger depuis l'API Xtream
      if (allEpisodes.isEmpty) {
        logger.debug(
          'Cache vide pour série $streamId, chargement des épisodes depuis l\'API Xtream',
          category: 'tv_detail',
        );

        try {
          final remote = locator<XtreamRemoteDataSource>();
          final vault = locator<CredentialsVault>();
          final accounts = await iptvLocal.getAccounts();
          if (accounts.isEmpty) {
            logger.warn(
              'Aucun compte Xtream disponible pour charger les épisodes',
              category: 'tv_detail',
            );
            return;
          }

          final account = accounts.firstWhere(
            (a) => a.id == accountId,
            orElse: () => accounts.first,
          );

          // Récupérer le mot de passe
          String? password = await vault.readPassword(account.id);
          if (password == null || password.isEmpty) {
            final hostKey = '${account.endpoint.host}_${account.username}'
                .toLowerCase();
            if (hostKey != account.id) {
              password = await vault.readPassword(hostKey);
            }
          }
          if (password == null || password.isEmpty) {
            final rawUrlKey =
                '${account.endpoint.toRawUrl()}_${account.username}'
                    .toLowerCase();
            if (rawUrlKey != account.id) {
              password = await vault.readPassword(rawUrlKey);
            }
          }

          if (password != null && password.isNotEmpty) {
            final request = XtreamAccountRequest(
              endpoint: account.endpoint,
              username: account.username,
              password: password,
            );

            // Charger toutes les informations de la série depuis l'API
            final seriesInfo = await remote.getSeriesInfo(
              request,
              seriesId: streamId,
            );

            // Log la structure de la réponse pour diagnostiquer
            logger.debug(
              'Réponse API get_series_info pour série $streamId: clés=${seriesInfo.keys.toList()}',
              category: 'tv_detail',
            );
            final episodesData = seriesInfo['episodes'];
            if (episodesData != null) {
              logger.debug(
                'Données épisodes trouvées: type=${episodesData.runtimeType}, est Map=${episodesData is Map}, est List=${episodesData is List}',
                category: 'tv_detail',
              );
              if (episodesData is Map) {
                logger.debug(
                  'Clés des saisons dans episodes: ${episodesData.keys.toList()}',
                  category: 'tv_detail',
                );
              } else if (episodesData is List) {
                logger.debug(
                  'Nombre total d\'éléments dans la liste episodes: ${episodesData.length}',
                  category: 'tv_detail',
                );
                if (episodesData.isNotEmpty) {
                  // Log la structure du premier élément pour diagnostiquer
                  final firstElement = episodesData.first;
                  logger.debug(
                    'Type du premier élément: ${firstElement.runtimeType}, est Map=${firstElement is Map}, est List=${firstElement is List}',
                    category: 'tv_detail',
                  );
                  if (firstElement is List) {
                    // Structure: List<List<Map>> - liste de saisons
                    logger.debug(
                      'Structure détectée: List<List<Map>> - ${episodesData.length} saisons',
                      category: 'tv_detail',
                    );
                    if (firstElement.isNotEmpty) {
                      final firstEpisode = firstElement.first;
                      if (firstEpisode is Map) {
                        logger.debug(
                          'Premier épisode (Saison 0): season=${firstEpisode['season']}, episode_num=${firstEpisode['episode_num']}, id=${firstEpisode['id']}',
                          category: 'tv_detail',
                        );
                      }
                    }
                  } else if (firstElement is Map) {
                    // Structure: List<Map> - liste plate d'épisodes
                    logger.debug(
                      'Structure détectée: List<Map> - liste plate d\'épisodes',
                      category: 'tv_detail',
                    );
                    logger.debug(
                      'Premier épisode: season=${firstElement['season']}, episode_num=${firstElement['episode_num']}, id=${firstElement['id']}',
                      category: 'tv_detail',
                    );
                  }
                }
              }
            } else {
              logger.warn(
                'Clé "episodes" non trouvée dans la réponse API pour série $streamId',
                category: 'tv_detail',
              );
            }

            // Parser tous les épisodes depuis la réponse API
            allEpisodes = _parseEpisodesFromSeriesInfo(
              seriesInfo,
              logger: logger,
            );

            // Log le résultat du parsing
            if (allEpisodes.isNotEmpty) {
              final totalParsed = allEpisodes.values.fold<int>(
                0,
                (sum, episodes) => sum + episodes.length,
              );
              logger.debug(
                'Parsing réussi: ${allEpisodes.length} saisons, $totalParsed épisodes parsés',
                category: 'tv_detail',
              );
            } else {
              final episodesCount = episodesData is List
                  ? episodesData.length
                  : 0;
              logger.warn(
                'Parsing échoué: aucun épisode parsé depuis la liste de $episodesCount éléments',
                category: 'tv_detail',
              );
            }

            // Sauvegarder en cache pour les prochaines fois
            if (allEpisodes.isNotEmpty) {
              final totalEpisodes = allEpisodes.values.fold<int>(
                0,
                (sum, episodes) => sum + episodes.length,
              );
              logger.debug(
                'Episodes Xtream parses depuis l\'API pour serie $streamId: ${allEpisodes.length} saisons, $totalEpisodes episodes',
                category: 'tv_detail',
              );

              await iptvLocal.saveEpisodes(
                accountId: accountId,
                seriesId: streamId,
                episodes: allEpisodes,
              );

              logger.debug(
                'Episodes Xtream sauvegardes en cache pour serie $streamId',
                category: 'tv_detail',
              );

              // Vérifier que les épisodes sont bien sauvegardés en testant la récupération du premier épisode
              final firstSeason = allEpisodes.keys.firstOrNull;
              if (firstSeason != null) {
                final firstEpisode = allEpisodes[firstSeason]!.keys.firstOrNull;
                if (firstEpisode != null) {
                  final testData = await iptvLocal.getEpisodeData(
                    accountId: accountId,
                    seriesId: streamId,
                    seasonNumber: firstSeason,
                    episodeNumber: firstEpisode,
                  );
                  if (testData != null) {
                    logger.debug(
                      'Vérification cache réussie: épisode S$firstSeason E$firstEpisode trouvé avec episodeId=${testData.episodeId}',
                      category: 'tv_detail',
                    );
                  } else {
                    logger.warn(
                      'Vérification cache échouée: épisode S$firstSeason E$firstEpisode NON trouvé après sauvegarde!',
                      category: 'tv_detail',
                    );
                  }
                }
              }
            } else {
              logger.warn(
                'Aucun épisode parsé depuis l\'API pour série $streamId',
                category: 'tv_detail',
              );
            }
          } else {
            logger.warn(
              'Impossible de récupérer le mot de passe pour charger les épisodes Xtream',
              category: 'tv_detail',
            );
          }
        } catch (e) {
          logger.warn(
            'Erreur lors du chargement des épisodes Xtream pour série $streamId: $e',
            category: 'tv_detail',
          );
        }
      } else {
        final totalEpisodes = allEpisodes.values.fold<int>(
          0,
          (sum, episodes) => sum + episodes.length,
        );
        logger.debug(
          'Épisodes Xtream déjà en cache pour série $streamId: ${allEpisodes.length} saisons, $totalEpisodes épisodes',
          category: 'tv_detail',
        );
      }
    } catch (e) {
      logger.warn(
        'Erreur lors du chargement des épisodes Xtream pour série $streamId: $e',
        category: 'tv_detail',
      );
    }
  }

  /// Parse les épisodes depuis la réponse get_series_info de l'API Xtream
  Map<int, Map<int, EpisodeData>> _parseEpisodesFromSeriesInfo(
    Map<String, dynamic> seriesInfo, {
    AppLogger? logger,
  }) {
    final episodes = <int, Map<int, EpisodeData>>{};
    final episodesData = seriesInfo['episodes'];

    if (episodesData == null) {
      // Pas de données d'épisodes dans la réponse
      logger?.debug(
        'Aucune donnée d\'épisodes trouvée dans la réponse API',
        category: 'tv_detail',
      );
      return episodes;
    }

    int parsedCount = 0;
    int skippedCount = 0;

    // Gérer le cas où episodes est une Map (structure classique)
    if (episodesData is Map<String, dynamic>) {
      for (final seasonEntry in episodesData.entries) {
        final seasonNumber = int.tryParse(seasonEntry.key);
        if (seasonNumber == null) {
          skippedCount++;
          continue;
        }

        final seasonEpisodes = seasonEntry.value;
        if (seasonEpisodes is List) {
          for (final episodeData in seasonEpisodes) {
            if (episodeData is Map<String, dynamic>) {
              // Ordre de priorité pour les champs d'épisode
              final episodeNum =
                  episodeData['episode_num'] ??
                  episodeData['episode'] ??
                  episodeData['episode_number'];
              // Ordre de priorité pour l'ID : id (string) > stream_id > episode_id
              final episodeIdRaw =
                  episodeData['id'] ??
                  episodeData['stream_id'] ??
                  episodeData['episode_id'];
              final extension =
                  episodeData['container_extension']?.toString() ??
                  episodeData['extension']?.toString();

              if (episodeNum != null && episodeIdRaw != null) {
                final epNum = episodeNum is int
                    ? episodeNum
                    : int.tryParse(episodeNum.toString());
                // Gérer id comme string (doit être parsé en int)
                final epId = episodeIdRaw is int
                    ? episodeIdRaw
                    : int.tryParse(episodeIdRaw.toString());

                if (epNum != null && epId != null && epId > 0) {
                  episodes.putIfAbsent(
                    seasonNumber,
                    () => <int, EpisodeData>{},
                  );
                  episodes[seasonNumber]![epNum] = EpisodeData(
                    episodeId: epId,
                    extension: extension,
                  );
                  parsedCount++;
                } else {
                  skippedCount++;
                  logger?.debug(
                    'Épisode ignoré: epNum=$epNum, epId=$epId (saison $seasonNumber)',
                    category: 'tv_detail',
                  );
                }
              } else {
                skippedCount++;
              }
            }
          }
        }
      }
    }
    // Gérer le cas où episodes est une List
    // Structure: List<List<Map>> où chaque sous-liste représente une saison
    else if (episodesData is List) {
      // Vérifier si c'est une liste de listes (structure avec saisons)
      if (episodesData.isNotEmpty && episodesData.first is List) {
        // Structure: List<List<Map>> - chaque sous-liste est une saison
        for (final seasonList in episodesData) {
          if (seasonList is List) {
            // Itérer sur les épisodes de cette saison
            for (final episodeData in seasonList) {
              if (episodeData is Map<String, dynamic>) {
                // Ordre de priorité pour la saison : season > season_num > season_number
                final seasonNum =
                    episodeData['season'] ??
                    episodeData['season_num'] ??
                    episodeData['season_number'];
                // Ordre de priorité pour l'épisode : episode_num > episode > episode_number
                final episodeNum =
                    episodeData['episode_num'] ??
                    episodeData['episode'] ??
                    episodeData['episode_number'];
                // Ordre de priorité pour l'ID : id (string) > stream_id > episode_id
                final episodeIdRaw =
                    episodeData['id'] ??
                    episodeData['stream_id'] ??
                    episodeData['episode_id'];
                final extension =
                    episodeData['container_extension']?.toString() ??
                    episodeData['extension']?.toString();

                if (seasonNum != null &&
                    episodeNum != null &&
                    episodeIdRaw != null) {
                  final seasonNumber = seasonNum is int
                      ? seasonNum
                      : int.tryParse(seasonNum.toString());
                  final epNum = episodeNum is int
                      ? episodeNum
                      : int.tryParse(episodeNum.toString());
                  // Gérer id comme string (doit être parsé en int)
                  final epId = episodeIdRaw is int
                      ? episodeIdRaw
                      : int.tryParse(episodeIdRaw.toString());

                  if (seasonNumber != null &&
                      epNum != null &&
                      epId != null &&
                      epId > 0) {
                    episodes.putIfAbsent(
                      seasonNumber,
                      () => <int, EpisodeData>{},
                    );
                    episodes[seasonNumber]![epNum] = EpisodeData(
                      episodeId: epId,
                      extension: extension,
                    );
                    parsedCount++;
                  } else {
                    skippedCount++;
                    logger?.debug(
                      'Épisode ignoré: season=$seasonNumber, epNum=$epNum, epId=$epId',
                      category: 'tv_detail',
                    );
                  }
                } else {
                  skippedCount++;
                  logger?.debug(
                    'Épisode ignoré: champs manquants (season=$seasonNum, episode=$episodeNum, id=$episodeIdRaw)',
                    category: 'tv_detail',
                  );
                }
              }
            }
          }
        }
      } else {
        // Structure alternative: List<Map> - liste plate d'épisodes
        for (final episodeData in episodesData) {
          if (episodeData is Map<String, dynamic>) {
            // Ordre de priorité pour la saison : season > season_num > season_number
            final seasonNum =
                episodeData['season'] ??
                episodeData['season_num'] ??
                episodeData['season_number'];
            // Ordre de priorité pour l'épisode : episode_num > episode > episode_number
            final episodeNum =
                episodeData['episode_num'] ??
                episodeData['episode'] ??
                episodeData['episode_number'];
            // Ordre de priorité pour l'ID : id (string) > stream_id > episode_id
            final episodeIdRaw =
                episodeData['id'] ??
                episodeData['stream_id'] ??
                episodeData['episode_id'];
            final extension =
                episodeData['container_extension']?.toString() ??
                episodeData['extension']?.toString();

            if (seasonNum != null &&
                episodeNum != null &&
                episodeIdRaw != null) {
              final seasonNumber = seasonNum is int
                  ? seasonNum
                  : int.tryParse(seasonNum.toString());
              final epNum = episodeNum is int
                  ? episodeNum
                  : int.tryParse(episodeNum.toString());
              // Gérer id comme string (doit être parsé en int)
              final epId = episodeIdRaw is int
                  ? episodeIdRaw
                  : int.tryParse(episodeIdRaw.toString());

              if (seasonNumber != null &&
                  epNum != null &&
                  epId != null &&
                  epId > 0) {
                episodes.putIfAbsent(seasonNumber, () => <int, EpisodeData>{});
                episodes[seasonNumber]![epNum] = EpisodeData(
                  episodeId: epId,
                  extension: extension,
                );
                parsedCount++;
              } else {
                skippedCount++;
                logger?.debug(
                  'Épisode ignoré: season=$seasonNumber, epNum=$epNum, epId=$epId',
                  category: 'tv_detail',
                );
              }
            } else {
              skippedCount++;
              logger?.debug(
                'Épisode ignoré: champs manquants (season=$seasonNum, episode=$episodeNum, id=$episodeIdRaw)',
                category: 'tv_detail',
              );
            }
          }
        }
      }
    }

    if (logger != null) {
      final totalEpisodes = episodes.values.fold<int>(
        0,
        (sum, seasonEpisodes) => sum + seasonEpisodes.length,
      );
      logger.debug(
        'Parsing terminé: $parsedCount épisodes parsés, $skippedCount ignorés, ${episodes.length} saisons, $totalEpisodes épisodes au total',
        category: 'tv_detail',
      );
    }

    return episodes;
  }

  /// Mappe les épisodes Xtream en Season/Episode domain entities
  List<Season> _mapXtreamEpisodesToSeasons(
    Map<int, Map<int, EpisodeData>> allEpisodes,
  ) {
    if (allEpisodes.isEmpty) return const [];

    return allEpisodes.entries
        .map((seasonEntry) {
          final seasonNumber = seasonEntry.key;
          final episodes = seasonEntry.value;

          final episodeList = episodes.entries
              .map((episodeEntry) {
                final episodeNumber = episodeEntry.key;
                // Les épisodes Xtream n'ont pas de métadonnées, utiliser des valeurs par défaut
                return Episode(
                  id: EpisodeId('xtream_${seasonNumber}_$episodeNumber'),
                  episodeNumber: episodeNumber,
                  title: MediaTitle('Episode $episodeNumber'),
                  overview: null,
                  runtime: null,
                  airDate: null,
                  still: null,
                  voteAverage: null,
                );
              })
              .toList(growable: false);

          return Season(
            id: SeasonId(seasonNumber.toString()),
            seasonNumber: seasonNumber,
            title: MediaTitle('Season $seasonNumber'),
            overview: null,
            poster: null,
            episodes: episodeList,
            airDate: null,
          );
        })
        .toList(growable: false)
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
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
      posterBackground: vm.posterBackground,
      backdrop: vm.backdrop,
      language: vm.language,
    );

    state = AsyncValue.data(updatedVm);
  }
}

final episodesBySeasonProvider =
    FutureProvider.family<List<Episode>, ({String seriesId, int seasonNumber})>(
      (ref, args) async {
        final repo = ref.watch(tvRepositoryProvider);
        final id = SeriesId(args.seriesId);
        final seasonId = SeasonId(args.seasonNumber.toString());
        return repo.getEpisodes(id, seasonId);
      },
    );

final watchlistStatusProvider = FutureProvider.family<bool, String>((
  ref,
  seriesId,
) async {
  final repo = ref.watch(tvRepositoryProvider);
  return repo.isInWatchlist(SeriesId(seriesId));
});

final continueWatchingProvider = FutureProvider<List<TvShowSummary>>((
  ref,
) async {
  final repo = ref.watch(tvRepositoryProvider);
  return repo.getContinueWatching();
});

final tvAvailabilityProvider = FutureProvider.family<bool, String>((
  ref,
  seriesId,
) async {
  final locator = ref.read(slProvider);
  final iptvLocal = locator<IptvLocalRepository>();
  if (seriesId.startsWith('xtream:')) return true;
  final repo = ref.read(tvRepositoryProvider);
  try {
    final detail = await repo.getShowLite(SeriesId(seriesId));
    final tmdbId = detail.tmdbId;
    if (tmdbId == null) return false;
    final available = await iptvLocal.getAvailableTmdbIds(
      type: XtreamPlaylistItemType.series,
    );
    return available.contains(tmdbId);
  } catch (_) {
    return false;
  }
});
