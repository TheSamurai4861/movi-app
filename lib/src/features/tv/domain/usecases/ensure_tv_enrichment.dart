import 'dart:async';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/domain/services/enrichment_check_service.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_remote_data_source.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/utils/unawaited.dart';

/// Use case qui vérifie si une série est suffisamment enrichie et déclenche
/// le full enrich si nécessaire, ainsi que le chargement des épisodes Xtream
/// en arrière-plan.
class EnsureTvEnrichment {
  EnsureTvEnrichment(this._enrichmentCheck, this._tvRepository, this._appState);

  final EnrichmentCheckService _enrichmentCheck;
  final TvRepository _tvRepository;
  final AppStateController _appState;

  /// Code de langue basé sur la locale courante (`fr-FR`, `en-US`, ou `en`).
  String get _languageCode {
    final locale = _appState.preferredLocale;
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}-$country';
  }

  /// Vérifie l'enrichissement et déclenche le full enrich si nécessaire.
  ///
  /// Charge également les épisodes Xtream en arrière-plan si la série
  /// est disponible dans IPTV.
  ///
  /// Retourne `true` si un enrichissement a été déclenché, `false` si
  /// les données sont déjà complètes.
  Future<bool> call(SeriesId seriesId) async {
    final logger = sl<AppLogger>();
    logger.debug(
      '📺 [ENRICH] EnsureTvEnrichment.call() démarré pour seriesId=${seriesId.value}',
      category: 'tv_enrichment',
    );

    final seriesIdInt = int.tryParse(seriesId.value);
    if (seriesIdInt == null) {
      logger.debug(
        '📺 [ENRICH] seriesId n\'est pas un entier (${seriesId.value}), enrichissement direct',
        category: 'tv_enrichment',
      );
      // Si l'ID n'est pas un entier (ex: xtream:123), on ne peut pas vérifier
      // l'enrichissement TMDB. On considère qu'il faut enrichir.
      try {
        logger.debug(
          '📺 [ENRICH] Appel _tvRepository.getShowLite() (ID non entier) pour seriesId=${seriesId.value}...',
          category: 'tv_enrichment',
        );
        final startTime = DateTime.now();
        await _tvRepository
            .getShowLite(seriesId)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                logger.log(
                  LogLevel.warn,
                  '📺 [ENRICH] Timeout lors de l\'enrichissement lite (ID non entier) pour seriesId=${seriesId.value} (15s)',
                  category: 'tv_enrichment',
                );
                throw TimeoutException(
                  'Timeout enrichissement série (ID non entier, lite) après 15s',
                );
              },
            );
        final duration = DateTime.now().difference(startTime);
        logger.debug(
          '📺 [ENRICH] Enrichissement lite réussi pour seriesId=${seriesId.value} en ${duration.inMilliseconds}ms',
          category: 'tv_enrichment',
        );
        // Charger les épisodes Xtream en arrière-plan si c'est une série Xtream
        _loadXtreamEpisodesInBackground(seriesId);
        return true;
      } on TimeoutException catch (e, st) {
        logger.log(
          LogLevel.warn,
          '📺 [ENRICH] Timeout lors de l\'enrichissement direct pour seriesId=${seriesId.value}: $e',
          category: 'tv_enrichment',
          error: e,
          stackTrace: st,
        );
        return false;
      } catch (e, st) {
        logger.log(
          LogLevel.warn,
          '📺 [ENRICH] Erreur lors de l\'enrichissement direct pour seriesId=${seriesId.value}: $e',
          category: 'tv_enrichment',
          error: e,
          stackTrace: st,
        );
        return false;
      }
    }

    final language = _appState.preferredLocale;
    logger.debug(
      '📺 [ENRICH] Vérification enrichissement pour seriesId=$seriesIdInt, language=$language',
      category: 'tv_enrichment',
    );

    final status = await _enrichmentCheck.checkTvEnrichment(
      seriesIdInt,
      _languageCode,
    );

    logger.debug(
      '📺 [ENRICH] Statut enrichissement pour seriesId=$seriesIdInt: $status',
      category: 'tv_enrichment',
    );

    // Si les données sont complètes, pas besoin d'enrichir
    // Mais on charge quand même les épisodes Xtream en arrière-plan
    if (status == EnrichmentStatus.complete) {
      logger.debug(
        '📺 [ENRICH] Données complètes pour seriesId=$seriesIdInt, pas d\'enrichissement nécessaire, chargement épisodes Xtream en arrière-plan',
        category: 'tv_enrichment',
      );
      _loadXtreamEpisodesInBackground(seriesId);
      return false;
    }

    // Si les données sont manquantes ou partielles, déclencher le full enrich
    logger.debug(
      '📺 [ENRICH] Données incomplètes (status=$status) pour seriesId=$seriesIdInt, déclenchement enrich (lite)',
      category: 'tv_enrichment',
    );
    try {
      logger.debug(
        '📺 [ENRICH] Appel _tvRepository.getShowLite() pour seriesId=$seriesIdInt (plus rapide, sans saisons)...',
        category: 'tv_enrichment',
      );
      final startTime = DateTime.now();
      await _tvRepository
          .getShowLite(seriesId)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              logger.log(
                LogLevel.warn,
                '📺 [ENRICH] Timeout lors de l\'enrichissement lite pour seriesId=$seriesIdInt (15s)',
                category: 'tv_enrichment',
              );
              throw TimeoutException(
                'Timeout enrichissement série (lite) après 15s',
              );
            },
          );
      final duration = DateTime.now().difference(startTime);
      logger.debug(
        '📺 [ENRICH] Enrichissement lite réussi pour seriesId=$seriesIdInt en ${duration.inMilliseconds}ms, chargement épisodes Xtream en arrière-plan',
        category: 'tv_enrichment',
      );
      // Charger les épisodes Xtream en arrière-plan
      _loadXtreamEpisodesInBackground(seriesId);
      return true;
    } on TimeoutException catch (e, st) {
      logger.log(
        LogLevel.warn,
        '📺 [ENRICH] Timeout lors du full enrich pour seriesId=$seriesIdInt: $e',
        category: 'tv_enrichment',
        error: e,
        stackTrace: st,
      );
      // En cas de timeout, on considère que l'enrichissement n'a pas été déclenché
      // La page pourra quand même s'afficher avec les données partielles
      return false;
    } catch (e, st) {
      logger.log(
        LogLevel.warn,
        '📺 [ENRICH] Erreur lors du full enrich pour seriesId=$seriesIdInt: $e',
        category: 'tv_enrichment',
        error: e,
        stackTrace: st,
      );
      // En cas d'erreur, on considère que l'enrichissement n'a pas été déclenché
      // La page pourra quand même s'afficher avec les données partielles
      return false;
    }
  }

  /// Charge les épisodes Xtream en arrière-plan sans bloquer
  void _loadXtreamEpisodesInBackground(SeriesId seriesId) {
    // Ne pas attendre le résultat, charger en arrière-plan
    unawaited(_loadXtreamEpisodes(seriesId));
  }

  /// Charge les épisodes Xtream pour une série si elle est disponible dans IPTV
  Future<void> _loadXtreamEpisodes(SeriesId seriesId) async {
    try {
      final iptvLocal = sl<IptvLocalRepository>();
      final logger = sl<AppLogger>();

      // Vérifier si c'est un ID Xtream direct
      int? streamId;
      String? accountId;

      if (seriesId.value.startsWith('xtream:')) {
        final streamIdStr = seriesId.value.substring(7);
        streamId = int.tryParse(streamIdStr);
        if (streamId == null) return;

        // Trouver l'accountId
        final accounts = await iptvLocal.getAccounts();
        for (final account in accounts) {
          final playlists = await iptvLocal.getPlaylists(account.id);
          for (final playlist in playlists) {
            if (playlist.type != XtreamPlaylistType.series) continue;
            final found = playlist.items.firstWhere(
              (item) =>
                  item.streamId == streamId &&
                  item.type == XtreamPlaylistItemType.series,
              orElse: () => playlist.items.first,
            );
            if (found.streamId == streamId) {
              accountId = found.accountId;
              break;
            }
          }
          if (accountId != null) break;
        }
      } else {
        // Chercher par tmdbId
        final tmdbId = int.tryParse(seriesId.value);
        if (tmdbId == null) return;

        final accounts = await iptvLocal.getAccounts();
        for (final account in accounts) {
          final playlists = await iptvLocal.getPlaylists(account.id);
          for (final playlist in playlists) {
            if (playlist.type != XtreamPlaylistType.series) continue;
            final found = playlist.items.firstWhere(
              (item) =>
                  item.tmdbId == tmdbId &&
                  item.type == XtreamPlaylistItemType.series &&
                  item.streamId > 0,
              orElse: () => playlist.items.first,
            );
            if (found.tmdbId == tmdbId && found.streamId > 0) {
              streamId = found.streamId;
              accountId = found.accountId;
              break;
            }
          }
          if (accountId != null) break;
        }
      }

      if (streamId == null || accountId == null) {
        // Série non trouvée dans IPTV, pas besoin de charger les épisodes
        return;
      }

      // Vérifier si les épisodes sont déjà en cache
      final cachedEpisodes = await iptvLocal.getAllEpisodesForSeries(
        accountId: accountId,
        seriesId: streamId,
      );

      if (cachedEpisodes.isNotEmpty) {
        // Déjà en cache, pas besoin de charger
        return;
      }

      // Charger depuis l'API Xtream
      final remote = sl<XtreamRemoteDataSource>();
      final vault = sl<CredentialsVault>();
      final accounts = await iptvLocal.getAccounts();
      if (accounts.isEmpty) return;

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
        final rawUrlKey = '${account.endpoint.toRawUrl()}_${account.username}'
            .toLowerCase();
        if (rawUrlKey != account.id) {
          password = await vault.readPassword(rawUrlKey);
        }
      }

      if (password == null || password.isEmpty) {
        logger.log(
          LogLevel.warn,
          'Impossible de récupérer le mot de passe pour charger les épisodes Xtream',
          category: 'ensure_tv_enrichment',
        );
        return;
      }

      final request = XtreamAccountRequest(
        endpoint: account.endpoint,
        username: account.username,
        password: password,
      );

      // Charger les informations de la série depuis l'API
      final seriesInfo = await remote.getSeriesInfo(
        request,
        seriesId: streamId,
      );

      // Parser les épisodes (logique simplifiée)
      final episodesData = seriesInfo['episodes'];
      if (episodesData == null) return;

      final allEpisodes = <int, Map<int, EpisodeData>>{};

      if (episodesData is Map<String, dynamic>) {
        for (final seasonEntry in episodesData.entries) {
          final seasonNumber = int.tryParse(seasonEntry.key);
          if (seasonNumber == null) continue;

          final seasonEpisodes = seasonEntry.value;
          if (seasonEpisodes is! List) continue;

          final episodes = <int, EpisodeData>{};
          for (final ep in seasonEpisodes) {
            if (ep is! Map<String, dynamic>) continue;

            // Parser episode_num (peut être int ou String)
            final episodeNumRaw = ep['episode_num'];
            final episodeNum = episodeNumRaw is int
                ? episodeNumRaw
                : (episodeNumRaw is String
                      ? int.tryParse(episodeNumRaw)
                      : null);

            // Parser id (peut être int ou String)
            final episodeIdRaw = ep['id'];
            final episodeId = episodeIdRaw is int
                ? episodeIdRaw
                : (episodeIdRaw is String ? int.tryParse(episodeIdRaw) : null);

            if (episodeNum == null || episodeId == null) continue;

            episodes[episodeNum] = EpisodeData(
              episodeId: episodeId,
              extension: ep['container_extension']?.toString(),
            );
          }
          if (episodes.isNotEmpty) {
            allEpisodes[seasonNumber] = episodes;
          }
        }
      }

      if (allEpisodes.isNotEmpty) {
        await iptvLocal.saveEpisodes(
          accountId: accountId,
          seriesId: streamId,
          episodes: allEpisodes,
        );
        logger.debug(
          'Épisodes Xtream chargés en arrière-plan pour série $streamId: ${allEpisodes.length} saisons',
          category: 'ensure_tv_enrichment',
        );
      }
    } catch (e, st) {
      final logger = sl<AppLogger>();
      logger.log(
        LogLevel.warn,
        'Erreur lors du chargement des épisodes Xtream en arrière-plan: $e',
        category: 'ensure_tv_enrichment',
        error: e,
        stackTrace: st,
      );
      // Ne pas propager l'erreur, c'est en arrière-plan
    }
  }
}
