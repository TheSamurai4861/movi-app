import 'dart:async';

import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/performance/domain/performance_tuning.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_category_dto.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_stream_dto.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_settings.dart';
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
    this._tuning,
  );

  final IptvLocalRepository _local;
  final CredentialsVault _vault;
  final XtreamRemoteDataSource _remote;
  final PlaylistMapper _mapper;
  final XtreamCacheDataSource _cache;
  final AppLogger _logger;
  final PerformanceTuning _tuning;

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

    // Met à jour les infos du compte (expiration / statut) dès le rafraîchissement.
    await _refreshAccountAuthInfo(account: account, password: password);

    if (_tuning.isLowResources) {
      return _refreshCatalogLowResources(
        accountId: accountId,
        account: account,
        password: password,
      );
    }

    final data = await _fetchRemoteData(
      account: account,
      accountId: accountId,
      password: password,
    );

    final playlists = await _buildAndSavePlaylists(accountId, data);
    await _syncPlaylistSettings(accountId: accountId, playlists: playlists);

    // Les épisodes seront chargés à la demande lors de l'ouverture d'une série
    // via XtreamStreamUrlBuilder qui les mettra en cache automatiquement

    final snapshot = await _createAndStoreSnapshot(accountId, data);
    return snapshot;
  }

  Future<XtreamCatalogSnapshot> _refreshCatalogLowResources({
    required String accountId,
    required XtreamAccount account,
    required String password,
  }) async {
    final request = XtreamAccountRequest(
      endpoint: account.endpoint,
      username: account.username,
      password: password,
    );

    final moviesCategories = await _remote.getVodCategories(request);
    final seriesCategories = await _remote.getSeriesCategories(request);

    final playlistsMeta = <XtreamPlaylist>[];

    List<XtreamStreamDto> movies = await _remote.getVodStreams(request);
    final movieCount = movies.length;
    List<XtreamPlaylist> moviePlaylists = _mapper.buildPlaylists(
      accountId: accountId,
      movieCategories: moviesCategories,
      movieStreams: movies,
      seriesCategories: const <XtreamCategoryDto>[],
      seriesStreams: const <XtreamStreamDto>[],
    );
    await _savePlaylistsChunked(accountId, moviePlaylists);
    playlistsMeta.addAll(
      moviePlaylists.map(
        (p) => XtreamPlaylist(
          id: p.id,
          accountId: p.accountId,
          title: p.title,
          type: p.type,
          items: const <XtreamPlaylistItem>[],
        ),
      ),
    );

    // Laisser respirer l'UI sur des appareils plus lents.
    await Future<void>.delayed(Duration.zero);
    movies = const <XtreamStreamDto>[];
    moviePlaylists = const <XtreamPlaylist>[];

    List<XtreamStreamDto> series = await _remote.getSeries(request);
    final seriesCount = series.length;
    List<XtreamPlaylist> seriesPlaylists = _mapper.buildPlaylists(
      accountId: accountId,
      movieCategories: const <XtreamCategoryDto>[],
      movieStreams: const <XtreamStreamDto>[],
      seriesCategories: seriesCategories,
      seriesStreams: series,
    );
    await _savePlaylistsChunked(accountId, seriesPlaylists);
    playlistsMeta.addAll(
      seriesPlaylists.map(
        (p) => XtreamPlaylist(
          id: p.id,
          accountId: p.accountId,
          title: p.title,
          type: p.type,
          items: const <XtreamPlaylistItem>[],
        ),
      ),
    );

    await _syncPlaylistSettings(accountId: accountId, playlists: playlistsMeta);

    return _createAndStoreSnapshotFromCounts(
      accountId: accountId,
      movieCount: movieCount,
      seriesCount: seriesCount,
    );
  }

  Future<void> _refreshAccountAuthInfo({
    required XtreamAccount account,
    required String password,
  }) async {
    final auth = await _remote.authenticate(
      endpoint: account.endpoint,
      username: account.username,
      password: password,
    );

    final now = DateTime.now();
    XtreamAccountStatus nextStatus;
    if (auth.isAuthorized) {
      nextStatus = XtreamAccountStatus.active;
    } else if (auth.expiration != null && auth.expiration!.isBefore(now)) {
      nextStatus = XtreamAccountStatus.expired;
    } else {
      nextStatus = XtreamAccountStatus.error;
    }

    final updated = account.copyWith(
      status: nextStatus,
      expirationDate: auth.expiration,
      lastError: auth.isAuthorized ? null : auth.message,
    );
    await _local.saveAccount(updated);

    if (!auth.isAuthorized) {
      throw AuthFailure('Xtream authentication failed: ${auth.message}');
    }
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

  Future<void> _savePlaylistsChunked(
    String accountId,
    List<XtreamPlaylist> playlists,
  ) async {
    if (playlists.isEmpty) return;
    const chunkSize = 2;
    for (var i = 0; i < playlists.length; i += chunkSize) {
      final end = (i + chunkSize) < playlists.length ? (i + chunkSize) : playlists.length;
      await _local.savePlaylists(accountId, playlists.sublist(i, end));
      await Future<void>.delayed(Duration.zero);
    }
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
      'Series recuperees depuis l\'API: ${series.length} (accountId=$accountId)',
      category: 'IPTV',
    );

    // Compter les séries avec streamId valide avant le mapping
    final seriesWithValidId = series.where((s) => s.streamId > 0).length;
    final seriesWithZeroId = series.where((s) => s.streamId == 0).length;
    _logger.debug(
      'Repartition des series: $seriesWithValidId avec streamId>0, $seriesWithZeroId avec streamId=0',
      category: 'IPTV',
    );

    // Si toutes les séries ont streamId=0, logger un échantillon pour déboguer
    if (seriesWithValidId == 0 && series.isNotEmpty) {
      final sample = series.take(3).toList();
      _logger.warn(
        'Toutes les series ont streamId=0. Echantillon des premieres series: ${sample.map((s) => '${s.name} (streamId=${s.streamId}, categoryId=${s.categoryId})').join(', ')}',
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

  Future<List<XtreamPlaylist>> _buildAndSavePlaylists(
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
    return playlists;
  }

  Future<void> _syncPlaylistSettings({
    required String accountId,
    required List<XtreamPlaylist> playlists,
  }) async {
    final now = DateTime.now();
    final existing = await _local.getPlaylistSettings(accountId);
    final byId = {for (final s in existing) s.playlistId: s};

    int maxMovies = -1;
    int maxSeries = -1;
    int maxGlobal = -1;
    for (final s in existing) {
      if (s.type == XtreamPlaylistType.movies && s.position > maxMovies) {
        maxMovies = s.position;
      } else if (s.type == XtreamPlaylistType.series && s.position > maxSeries) {
        maxSeries = s.position;
      }
      if (s.globalPosition > maxGlobal) {
        maxGlobal = s.globalPosition;
      }
    }

    final toUpsert = <XtreamPlaylistSettings>[];
    final keepIds = <String>{};

    for (final pl in playlists) {
      keepIds.add(pl.id);
      final current = byId[pl.id];
      if (current != null) continue;

      final nextPos = pl.type == XtreamPlaylistType.movies
          ? (++maxMovies)
          : (++maxSeries);

      final nextGlobal = ++maxGlobal;
      toUpsert.add(
        XtreamPlaylistSettings(
          accountId: accountId,
          playlistId: pl.id,
          type: pl.type,
          position: nextPos,
          globalPosition: nextGlobal,
          isVisible: true,
          updatedAt: now,
        ),
      );
    }

    await _local.upsertPlaylistSettingsBatch(toUpsert);
    await _local.deletePlaylistSettingsNotIn(
      accountId: accountId,
      playlistIds: keepIds,
    );

    // Si aucune config n'existait auparavant, on initialise un ordre par défaut
    // identique à l'accueil historique: intercalé films/séries au départ.
    if (existing.isEmpty && toUpsert.isNotEmpty) {
      final movies = toUpsert
          .where((e) => e.type == XtreamPlaylistType.movies)
          .toList(growable: false)
        ..sort((a, b) => a.position.compareTo(b.position));
      final series = toUpsert
          .where((e) => e.type == XtreamPlaylistType.series)
          .toList(growable: false)
        ..sort((a, b) => a.position.compareTo(b.position));

      final orderedIds = <String>[];
      final maxLen = movies.length > series.length ? movies.length : series.length;
      for (var i = 0; i < maxLen; i++) {
        if (i < movies.length) orderedIds.add(movies[i].playlistId);
        if (i < series.length) orderedIds.add(series[i].playlistId);
      }

      await _local.reorderPlaylistsGlobal(
        accountId: accountId,
        orderedPlaylistIds: orderedIds,
      );
    }
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

  Future<XtreamCatalogSnapshot> _createAndStoreSnapshotFromCounts({
    required String accountId,
    required int movieCount,
    required int seriesCount,
  }) async {
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
