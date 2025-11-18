import 'dart:async';

import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_stream_dto.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/iptv/domain/failures/iptv_failures.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_remote_data_source.dart';
import 'package:movi/src/features/iptv/application/services/playlist_mapper.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_cache_data_source.dart';

class IptvRepositoryImpl implements IptvRepository {
  IptvRepositoryImpl(
    this._local,
    this._vault,
    this._remote,
    this._mapper,
    this._cache,
    this._logger,
  );

  final IptvLocalRepository _local;
  final CredentialsVault _vault;
  final XtreamRemoteDataSource _remote;
  final PlaylistMapper _mapper;
  final XtreamCacheDataSource _cache;
  final AppLogger _logger;

  @override
  Future<XtreamAccount> addSource({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
    required String alias,
  }) async {
    final auth = await _remote.authenticate(
      endpoint: endpoint,
      username: username,
      password: password,
    );
    final id = '${endpoint.host}_$username'.toLowerCase();
    final status = auth.isAuthorized
        ? XtreamAccountStatus.active
        : XtreamAccountStatus.error;
    final account = XtreamAccount(
      id: id,
      alias: alias,
      endpoint: endpoint,
      username: username,
      status: status,
      createdAt: DateTime.now(),
      expirationDate: auth.expiration,
      lastError: auth.isAuthorized ? null : auth.message,
    );
    await _local.saveAccount(account);
    await _vault.storePassword(id, password);
    if (!auth.isAuthorized) {
      throw AuthFailure('Xtream authentication failed: ${auth.message}');
    }
    return account;
  }

  @override
  Future<XtreamCatalogSnapshot> refreshCatalog(String accountId) async {
    final accounts = await _local.getAccounts();
    final account = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () =>
          throw AccountNotFoundFailure('Unknown Xtream account $accountId'),
    );

    String? password = await _vault.readPassword(accountId);
    if (password == null || password.isEmpty) {
      final hostKey = '${account.endpoint.host}_${account.username}'
          .toLowerCase();
      if (hostKey != accountId) {
        password = await _vault.readPassword(hostKey);
      }
    }
    if (password == null || password.isEmpty) {
      final rawUrlKey = '${account.endpoint.toRawUrl()}_${account.username}'
          .toLowerCase();
      if (rawUrlKey != accountId) {
        password = await _vault.readPassword(rawUrlKey);
      }
    }
    if (password == null || password.isEmpty) {
      throw MissingCredentialsFailure('Missing credentials for $accountId');
    }

    final request = XtreamAccountRequest(
      endpoint: account.endpoint,
      username: account.username,
      password: password,
    );

    final moviesCategories = await _remote.getVodCategories(request);
    final seriesCategories = await _remote.getSeriesCategories(request);
    final movies = await _remote.getVodStreams(request);
    final series = await _remote.getSeries(request);

    _logger.debug(
      'Séries récupérées depuis l\'API: ${series.length} (accountId=$accountId)',
      category: 'IPTV',
    );

    // Compter les séries avec streamId valide avant le mapping
    final seriesWithValidId = series.where((s) => s.streamId > 0).length;
    final seriesWithZeroId = series.where((s) => s.streamId == 0).length;
    _logger.debug(
      'Répartition des séries: $seriesWithValidId avec streamId>0, $seriesWithZeroId avec streamId=0',
      category: 'IPTV',
    );

    // Si toutes les séries ont streamId=0, logger un échantillon pour déboguer
    if (seriesWithValidId == 0 && series.isNotEmpty) {
      final sample = series.take(3).toList();
      _logger.warn(
        'Toutes les séries ont streamId=0. Échantillon des premières séries: ${sample.map((s) => '${s.name} (streamId=${s.streamId}, categoryId=${s.categoryId})').join(', ')}',
        category: 'IPTV',
      );
    }

    final playlists = _mapper.buildPlaylists(
      accountId: accountId,
      movieCategories: moviesCategories,
      movieStreams: movies,
      seriesCategories: seriesCategories,
      seriesStreams: series,
    );

    await _local.savePlaylists(accountId, playlists);

    // Les épisodes seront chargés à la demande lors de l'ouverture d'une série
    // via XtreamStreamUrlBuilder qui les mettra en cache automatiquement

    final movieCount = movies.length;
    final seriesCount = series.length;
    final snapshot = XtreamCatalogSnapshot(
      accountId: accountId,
      lastSyncAt: DateTime.now(),
      movieCount: movieCount,
      seriesCount: seriesCount,
    );
    await _cache.saveSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<List<XtreamPlaylist>> listPlaylists(String accountId) {
    return _local.getPlaylists(accountId);
  }

  /// Charge et stocke les épisodes pour toutes les séries avec streamId valide
  /// Note: Non utilisé actuellement - les épisodes sont chargés à la demande via XtreamStreamUrlBuilder
  // ignore: unused_element
  Future<void> _loadAndStoreEpisodes(
    XtreamAccountRequest request,
    String accountId,
    List<XtreamStreamDto> series,
  ) async {
    // Filtrer les séries avec streamId valide
    final validSeries = series.where((s) => s.streamId > 0).toList();
    final totalSeries = validSeries.length;

    _logger.info(
      'Début du chargement des épisodes pour $totalSeries séries (accountId=$accountId)',
      category: 'IPTV',
    );

    if (totalSeries == 0) {
      _logger.debug('Aucune série valide à traiter', category: 'IPTV');
      return;
    }

    // Traiter les séries par lots pour éviter de surcharger l'API
    const batchSize = 10;
    int processed = 0;
    int success = 0;
    int failed = 0;
    int skipped = 0;

    for (var i = 0; i < validSeries.length; i += batchSize) {
      final batch = validSeries.skip(i).take(batchSize).toList();
      final results = await Future.wait(
        batch.map((s) => _loadAndStoreSeriesEpisodes(request, accountId, s)),
        eagerError: false,
      );

      processed += batch.length;

      // Compter les résultats
      for (final result in results) {
        if (result == true) {
          success++;
        } else if (result == false) {
          skipped++;
        } else {
          failed++;
        }
      }

      if (processed % 50 == 0 || processed == totalSeries) {
        _logger.debug(
          'Progression épisodes: $processed/$totalSeries (succès: $success, ignorés: $skipped, erreurs: $failed)',
          category: 'IPTV',
        );
      }
    }

    _logger.info(
      'Chargement des épisodes terminé: $processed/$totalSeries séries traitées (succès: $success, ignorés: $skipped, erreurs: $failed)',
      category: 'IPTV',
    );
  }

  /// Charge et stocke les épisodes d'une série
  /// Retourne true si succès, false si ignoré, null si erreur
  Future<bool?> _loadAndStoreSeriesEpisodes(
    XtreamAccountRequest request,
    String accountId,
    XtreamStreamDto series,
  ) async {
    // Ignorer les séries avec streamId invalide
    if (series.streamId == 0) {
      return false;
    }

    try {
      final seriesInfo = await _remote.getSeriesInfo(
        request,
        seriesId: series.streamId,
      );

      // Parser la réponse pour extraire les épisodes avec leur extension
      final episodes =
          <
            int,
            Map<int, EpisodeData>
          >{}; // Map<seasonNumber, Map<episodeNumber, EpisodeData>>
      final episodesData = seriesInfo['episodes'];

      if (episodesData is Map<String, dynamic>) {
        for (final seasonEntry in episodesData.entries) {
          final seasonNumber = int.tryParse(seasonEntry.key);
          if (seasonNumber == null) continue;

          final seasonEpisodes = seasonEntry.value;
          if (seasonEpisodes is List) {
            for (final episodeData in seasonEpisodes) {
              if (episodeData is Map<String, dynamic>) {
                final episodeNum = episodeData['episode_num'];
                final episodeId = episodeData['id'] ?? episodeData['stream_id'];
                final extension =
                    episodeData['container_extension']?.toString() ??
                    episodeData['extension']?.toString();

                if (episodeNum != null && episodeId != null) {
                  final epNum = episodeNum is int
                      ? episodeNum
                      : int.tryParse(episodeNum.toString());
                  final epId = episodeId is int
                      ? episodeId
                      : int.tryParse(episodeId.toString());

                  if (epNum != null && epId != null && epId > 0) {
                    episodes.putIfAbsent(
                      seasonNumber,
                      () => <int, EpisodeData>{},
                    );
                    episodes[seasonNumber]![epNum] = EpisodeData(
                      episodeId: epId,
                      extension: extension,
                    );
                  }
                }
              }
            }
          }
        }
      }

      // Sauvegarder les épisodes si on en a trouvé
      if (episodes.isNotEmpty) {
        final totalEpisodes = episodes.values.fold<int>(
          0,
          (sum, seasonEpisodes) => sum + seasonEpisodes.length,
        );
        await _local.saveEpisodes(
          accountId: accountId,
          seriesId: series.streamId,
          episodes: episodes,
        );
        _logger.debug(
          'Épisodes sauvegardés pour série ${series.streamId} (${episodes.length} saisons, $totalEpisodes épisodes)',
          category: 'IPTV',
        );
        return true;
      } else {
        _logger.debug(
          'Aucun épisode trouvé pour série ${series.streamId}',
          category: 'IPTV',
        );
        return false;
      }
    } catch (e) {
      // En cas d'erreur, logger et continuer avec les autres séries
      _logger.warn(
        'Erreur lors du chargement des épisodes pour série ${series.streamId}: $e',
        category: 'IPTV',
      );
      return null;
    }
  }
}
