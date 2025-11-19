import 'dart:async';

import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_category_dto.dart';
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

    final password = await _resolvePasswordForAccount(account, accountId);

    final data = await _fetchRemoteData(
      account: account,
      accountId: accountId,
      password: password,
    );

    await _buildAndSavePlaylists(accountId, data);

    // Les épisodes seront chargés à la demande lors de l'ouverture d'une série
    // via XtreamStreamUrlBuilder qui les mettra en cache automatiquement

    final snapshot = await _createAndStoreSnapshot(accountId, data);
    return snapshot;
  }

  @override
  Future<List<XtreamPlaylist>> listPlaylists(String accountId) {
    return _local.getPlaylists(accountId);
  }

  Future<String> _resolvePasswordForAccount(
    XtreamAccount account,
    String accountId,
  ) async {
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
    return password;
  }

  Future<_RemoteCatalogData> _fetchRemoteData({
    required XtreamAccount account,
    required String accountId,
    required String password,
  }) async {
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

    return _RemoteCatalogData(
      moviesCategories: moviesCategories,
      seriesCategories: seriesCategories,
      movies: movies,
      series: series,
    );
  }

  Future<void> _buildAndSavePlaylists(
    String accountId,
    _RemoteCatalogData data,
  ) async {
    final playlists = _mapper.buildPlaylists(
      accountId: accountId,
      movieCategories: data.moviesCategories,
      movieStreams: data.movies,
      seriesCategories: data.seriesCategories,
      seriesStreams: data.series,
    );

    await _local.savePlaylists(accountId, playlists);
  }

  Future<XtreamCatalogSnapshot> _createAndStoreSnapshot(
    String accountId,
    _RemoteCatalogData data,
  ) async {
    final movieCount = data.movies.length;
    final seriesCount = data.series.length;
    final snapshot = XtreamCatalogSnapshot(
      accountId: accountId,
      lastSyncAt: DateTime.now(),
      movieCount: movieCount,
      seriesCount: seriesCount,
    );
    await _cache.saveSnapshot(snapshot);
    return snapshot;
  }
}

class _RemoteCatalogData {
  const _RemoteCatalogData({
    required this.moviesCategories,
    required this.seriesCategories,
    required this.movies,
    required this.series,
  });

  final List<XtreamCategoryDto> moviesCategories;
  final List<XtreamCategoryDto> seriesCategories;
  final List<XtreamStreamDto> movies;
  final List<XtreamStreamDto> series;
}
