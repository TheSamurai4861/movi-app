import 'dart:async';

import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_tuning.dart';
import 'package:movi/src/features/iptv/data/dtos/stalker_category_dto.dart';
import 'package:movi/src/features/iptv/data/dtos/stalker_stream_dto.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_settings.dart';
import 'package:movi/src/features/iptv/domain/repositories/stalker_repository.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';
import 'package:movi/src/features/iptv/domain/failures/iptv_failures.dart';
import 'package:movi/src/features/iptv/data/datasources/stalker_remote_data_source.dart';
import 'package:movi/src/features/iptv/data/mappers/stalker_playlist_mapper.dart';
import 'package:movi/src/features/iptv/data/datasources/stalker_cache_data_source.dart';

class StalkerRepositoryImpl implements StalkerRepository {
  StalkerRepositoryImpl(
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
  final StalkerRemoteDataSource _remote;
  final StalkerPlaylistMapper _mapper;
  final StalkerCacheDataSource _cache;
  final AppLogger _logger;
  final PerformanceTuning _tuning;

  void _debugLog(String Function() message) {
    assert(() {
      _logger.debug(message(), category: 'Stalker');
      return true;
    }());
  }

  @override
  Future<StalkerAccount> addSource({
    required StalkerEndpoint endpoint,
    required String macAddress,
    String? username,
    String? password,
    required String alias,
  }) async {
    // 1. Handshake pour obtenir le token
    final handshakeAuth = await _remote.handshake(
      endpoint: endpoint,
      macAddress: macAddress,
    );

    if (!handshakeAuth.isAuthorized || handshakeAuth.token.isEmpty) {
      throw AuthFailure(
        'Stalker handshake failed: ${handshakeAuth.message ?? 'No token received'}',
      );
    }

    // 2. Get Profile pour valider l'authentification
    final profileAuth = await _remote.getProfile(
      endpoint: endpoint,
      token: handshakeAuth.token,
      macAddress: macAddress,
    );

    final id = '${endpoint.host}_$macAddress'.toLowerCase().replaceAll(':', '');
    final status = profileAuth.isAuthorized
        ? StalkerAccountStatus.active
        : StalkerAccountStatus.error;

    final account = StalkerAccount(
      id: id,
      alias: alias,
      endpoint: endpoint,
      macAddress: macAddress,
      username: username,
      token: profileAuth.token.isNotEmpty ? profileAuth.token : handshakeAuth.token,
      status: status,
      createdAt: DateTime.now(),
      expirationDate: profileAuth.expiration,
      lastError: profileAuth.isAuthorized ? null : profileAuth.message,
    );

    await _local.saveStalkerAccount(account);

    // Stocke le password si fourni (pour certains serveurs qui l'utilisent)
    if (password != null && password.isNotEmpty) {
      await _vault.storePassword(id, password);
    }

    if (!profileAuth.isAuthorized) {
      throw AuthFailure('Stalker authentication failed: ${profileAuth.message}');
    }

    return account;
  }

  @override
  Future<StalkerCatalogSnapshot> refreshCatalog(String accountId) async {
    final accounts = await _local.getStalkerAccounts();
    final account = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () =>
          throw AccountNotFoundFailure('Unknown Stalker account $accountId'),
    );

    // Rafraîchit le token si nécessaire (handshake)
    await _refreshAccountAuthInfo(account: account);

    if (_tuning.isLowResources) {
      return _refreshCatalogLowResources(accountId: accountId, account: account);
    }

    final data = await _fetchRemoteData(accountId: accountId, account: account);
    final playlists = await _buildAndSavePlaylists(accountId, data);
    await _syncPlaylistSettings(accountId: accountId, playlists: playlists);

    final snapshot = await _createAndStoreSnapshot(accountId, data);
    return snapshot;
  }

  Future<void> _refreshAccountAuthInfo({
    required StalkerAccount account,
  }) async {
    try {
      final handshakeAuth = await _remote.handshake(
        endpoint: account.endpoint,
        macAddress: account.macAddress,
      );

      if (handshakeAuth.isAuthorized && handshakeAuth.token.isNotEmpty) {
        final profileAuth = await _remote.getProfile(
          endpoint: account.endpoint,
          token: handshakeAuth.token,
          macAddress: account.macAddress,
        );

        final now = DateTime.now();
        StalkerAccountStatus nextStatus;
        if (profileAuth.isAuthorized) {
          nextStatus = StalkerAccountStatus.active;
        } else if (profileAuth.expiration != null &&
            profileAuth.expiration!.isBefore(now)) {
          nextStatus = StalkerAccountStatus.expired;
        } else {
          nextStatus = StalkerAccountStatus.error;
        }

        final updated = account.copyWith(
          status: nextStatus,
          token: profileAuth.token.isNotEmpty ? profileAuth.token : handshakeAuth.token,
          expirationDate: profileAuth.expiration,
          lastError: profileAuth.isAuthorized ? null : profileAuth.message,
        );
        await _local.saveStalkerAccount(updated);
      }
    } catch (e) {
      _logger.debug('Failed to refresh Stalker account auth: $e', category: 'Stalker');
    }
  }

  Future<StalkerCatalogSnapshot> _refreshCatalogLowResources({
    required String accountId,
    required StalkerAccount account,
  }) async {
    // Version simplifiée pour appareils à faibles ressources
    final token = account.token ?? '';
    if (token.isEmpty) {
      throw AuthFailure('No token available for Stalker account');
    }

    final movieCategories = await _remote.getVodCategories(
      endpoint: account.endpoint,
      token: token,
      macAddress: account.macAddress,
    );

    final seriesCategories = await _remote.getSeriesCategories(
      endpoint: account.endpoint,
      token: token,
      macAddress: account.macAddress,
    );

    final playlistsMeta = <XtreamPlaylist>[];

    // Charge seulement la première page pour les films
    final vodData = await _remote.getVodContent(
      endpoint: account.endpoint,
      token: token,
      page: 1,
      perPage: 50,
      macAddress: account.macAddress,
    );

    var movieStreams = _parseStreamsFromResponse(vodData, 'vod');
    if (movieStreams.isEmpty && movieCategories.isNotEmpty) {
      final fallbackId = movieCategories.first.id;
      final fallbackData = await _remote.getVodContent(
        endpoint: account.endpoint,
        token: token,
        categoryId: fallbackId,
        page: 1,
        perPage: 50,
        macAddress: account.macAddress,
      );
      movieStreams = _parseStreamsFromResponse(
        fallbackData,
        'vod',
        fallbackCategoryId: fallbackId,
      );
    }
    final movieCount = vodData['total_items'] as int? ?? movieStreams.length;

    final moviePlaylists = _mapper.buildPlaylists(
      accountId: accountId,
      movieCategories: movieCategories,
      movieStreams: movieStreams,
      seriesCategories: const <StalkerCategoryDto>[],
      seriesStreams: const <StalkerStreamDto>[],
    );
    await _savePlaylistsChunked(accountId, moviePlaylists);
    playlistsMeta.addAll(
      moviePlaylists.map(
        (p) => XtreamPlaylist(
          id: p.id,
          accountId: p.accountId,
          title: p.title,
          type: p.type,
          items: const [],
        ),
      ),
    );

    // Charge seulement la première page pour les séries
    final seriesData = await _remote.getSeriesContent(
      endpoint: account.endpoint,
      token: token,
      page: 1,
      perPage: 50,
      macAddress: account.macAddress,
    );

    var seriesStreams = _parseStreamsFromResponse(seriesData, 'series');
    if (seriesStreams.isEmpty && seriesCategories.isNotEmpty) {
      final fallbackId = seriesCategories.first.id;
      final fallbackData = await _remote.getSeriesContent(
        endpoint: account.endpoint,
        token: token,
        categoryId: fallbackId,
        page: 1,
        perPage: 50,
        macAddress: account.macAddress,
      );
      seriesStreams = _parseStreamsFromResponse(
        fallbackData,
        'series',
        fallbackCategoryId: fallbackId,
      );
    }
    final seriesCount = seriesData['total_items'] as int? ?? seriesStreams.length;

    final seriesPlaylists = _mapper.buildPlaylists(
      accountId: accountId,
      movieCategories: const <StalkerCategoryDto>[],
      movieStreams: const <StalkerStreamDto>[],
      seriesCategories: seriesCategories,
      seriesStreams: seriesStreams,
    );
    await _savePlaylistsChunked(accountId, seriesPlaylists);
    playlistsMeta.addAll(
      seriesPlaylists.map(
        (p) => XtreamPlaylist(
          id: p.id,
          accountId: p.accountId,
          title: p.title,
          type: p.type,
          items: const [],
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

  Future<({
    List<StalkerCategoryDto> movieCategories,
    List<StalkerCategoryDto> seriesCategories,
    List<StalkerStreamDto> movieStreams,
    List<StalkerStreamDto> seriesStreams,
  })> _fetchRemoteData({
    required String accountId,
    required StalkerAccount account,
  }) async {
    _debugLog(() => '📥 [STALKER REPO] _fetchRemoteData start');
    final token = account.token ?? '';
    if (token.isEmpty) {
      throw AuthFailure('No token available for Stalker account');
    }
    _debugLog(() => '📥 [STALKER REPO] Token OK: ${token.substring(0, 10)}...');

    // Récupère les catégories
    _debugLog(() => '📥 [STALKER REPO] Fetching VOD categories...');
    final movieCategories = await _remote.getVodCategories(
      endpoint: account.endpoint,
      token: token,
      macAddress: account.macAddress,
    );
    _debugLog(() => '📥 [STALKER REPO] VOD categories: ${movieCategories.length}');

    _debugLog(() => '📥 [STALKER REPO] Fetching Series categories...');
    final seriesCategories = await _remote.getSeriesCategories(
      endpoint: account.endpoint,
      token: token,
      macAddress: account.macAddress,
    );
    _debugLog(() => '📥 [STALKER REPO] Series categories: ${seriesCategories.length}');

    const perPage = 100;
    final movieMaxPages = _categoryMaxPages(movieCategories.length);
    final movieStreams = await _loadStreams(
      label: 'VOD',
      type: 'vod',
      categories: movieCategories,
      perPage: perPage,
      maxPages: movieMaxPages,
      fallbackCategoryId: '01',
      fetchPage: (categoryId, page) => _remote.getVodContent(
        endpoint: account.endpoint,
        token: token,
        categoryId: categoryId,
        page: page,
        perPage: perPage,
        macAddress: account.macAddress,
      ),
    );
    _debugLog(() => '📥 [STALKER REPO] Total VOD streams: ${movieStreams.length}');

    final seriesMaxPages = _categoryMaxPages(seriesCategories.length);
    final seriesStreams = await _loadStreams(
      label: 'Series',
      type: 'series',
      categories: seriesCategories,
      perPage: perPage,
      maxPages: seriesMaxPages,
      fallbackCategoryId: '02',
      fetchPage: (categoryId, page) => _remote.getSeriesContent(
        endpoint: account.endpoint,
        token: token,
        categoryId: categoryId,
        page: page,
        perPage: perPage,
        macAddress: account.macAddress,
      ),
    );
    _debugLog(() => '📥 [STALKER REPO] Total Series streams: ${seriesStreams.length}');

    _debugLog(
      () =>
          '📥 [STALKER REPO] _fetchRemoteData done: ${movieStreams.length} films, ${seriesStreams.length} séries',
    );
    return (
      movieCategories: movieCategories,
      seriesCategories: seriesCategories,
      movieStreams: movieStreams,
      seriesStreams: seriesStreams,
    );
  }

  List<StalkerStreamDto> _parseStreamsFromResponse(
    Map<String, dynamic> response,
    String type, {
    String? fallbackCategoryId,
  }) {
    _debugLog(() => '🔍 [PARSE] response keys: ${response.keys}');
    
    // Essayer d'extraire les données de la réponse Stalker
    // Format possible 1: {js: {data: [...]}}
    // Format possible 2: {data: [...]}
    // Format possible 3: {detail: ...}
    
    dynamic data;
    if (response.containsKey('js')) {
      _debugLog(() => '🔍 [PARSE] Found js key');
      final js = response['js'];
      if (js is Map<String, dynamic>) {
        data = js['data'];
        _debugLog(() => '🔍 [PARSE] Extracted data from js: ${data.runtimeType}');
      }
    } else if (response.containsKey('data')) {
      data = response['data'];
      _debugLog(() => '🔍 [PARSE] Found data key directly: ${data.runtimeType}');
    } else if (response.containsKey('detail')) {
      _debugLog(() => '🔍 [PARSE] Found detail key: ${response['detail']}');
      return [];
    }
    
    if (data is List) {
      _debugLog(() => '🔍 [PARSE] Data is List with ${data.length} items');
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) {
            final parsed = StalkerStreamDto.fromJson(json);
            if ((parsed.categoryId.isEmpty) &&
                fallbackCategoryId != null &&
                fallbackCategoryId.isNotEmpty) {
              return _overrideCategory(parsed, fallbackCategoryId);
            }
            return parsed;
          })
          .toList(growable: false);
    }
    
    _debugLog(() => '🔍 [PARSE] No valid data found, returning empty list');
    return [];
  }

  StalkerStreamDto _overrideCategory(
    StalkerStreamDto stream,
    String categoryId,
  ) {
    return StalkerStreamDto(
      streamId: stream.streamId,
      name: stream.name,
      streamType: stream.streamType,
      categoryId: categoryId,
      streamIcon: stream.streamIcon,
      plot: stream.plot,
      released: stream.released,
      year: stream.year,
      tmdbId: stream.tmdbId,
      rating: stream.rating,
      director: stream.director,
      actors: stream.actors,
    );
  }

  Future<List<StalkerStreamDto>> _loadStreams({
    required String label,
    required String type,
    required List<StalkerCategoryDto> categories,
    required int perPage,
    required int maxPages,
    String? fallbackCategoryId,
    required Future<Map<String, dynamic>> Function(String? categoryId, int page)
        fetchPage,
  }) async {
    _debugLog(() => '📥 [STALKER REPO] Starting $label pagination...');
    final streams = <StalkerStreamDto>[];

    final probeData = await fetchPage(null, 1);
    _debugLog(
      () => '📥 [STALKER REPO] $label page 1 response keys: ${probeData.keys}',
    );
    final probeStreams = _parseStreamsFromResponse(probeData, type);
    final canUseNoCategory = probeStreams.isNotEmpty &&
        probeStreams.any((s) => s.categoryId.isNotEmpty);

    if (canUseNoCategory || categories.isEmpty) {
      streams.addAll(probeStreams);
      var page = 2;
      var hasMore = _hasMorePages(
        probeData,
        probeStreams.length,
        perPage,
        page,
      );
      while (hasMore && page <= maxPages) {
        _debugLog(() => '📥 [STALKER REPO] Fetching $label page $page...');
        final data = await fetchPage(null, page);
        final pageStreams = _parseStreamsFromResponse(data, type);
        _debugLog(
          () =>
              '📥 [STALKER REPO] Parsed ${pageStreams.length} streams from page $page',
        );
        streams.addAll(pageStreams);
        page++;
        hasMore = _hasMorePages(
          data,
          pageStreams.length,
          perPage,
          page,
        );
      }
      if (streams.isNotEmpty) return streams;
    }

    if (categories.isEmpty && fallbackCategoryId != null) {
      var page = 1;
      var hasMore = true;
      while (hasMore && page <= maxPages) {
        _debugLog(
          () => '📥 [STALKER REPO] Fetching $label $fallbackCategoryId page $page...',
        );
        final data = await fetchPage(fallbackCategoryId, page);
        final pageStreams = _parseStreamsFromResponse(
          data,
          type,
          fallbackCategoryId: fallbackCategoryId,
        );
        _debugLog(
          () =>
              '📥 [STALKER REPO] Parsed ${pageStreams.length} streams from page $page',
        );
        streams.addAll(pageStreams);
        page++;
        hasMore = _hasMorePages(
          data,
          pageStreams.length,
          perPage,
          page,
        );
      }
      return streams;
    }

    for (final category in categories) {
      if (category.id.trim().isEmpty) continue;
      var page = 1;
      var hasMore = true;
      while (hasMore && page <= maxPages) {
        _debugLog(
          () => '📥 [STALKER REPO] Fetching $label ${category.id} page $page...',
        );
        final data = await fetchPage(category.id, page);
        final pageStreams = _parseStreamsFromResponse(
          data,
          type,
          fallbackCategoryId: category.id,
        );
        _debugLog(
          () =>
              '📥 [STALKER REPO] Parsed ${pageStreams.length} streams from page $page',
        );
        streams.addAll(pageStreams);
        page++;
        hasMore = _hasMorePages(
          data,
          pageStreams.length,
          perPage,
          page,
        );
      }
    }

    return streams;
  }

  bool _hasMorePages(
    Map<String, dynamic> response,
    int streamCount,
    int perPage,
    int nextPage,
  ) {
    final totalItems = response['total_items'] as int? ?? 0;
    final maxPageItems = response['max_page_items'] as int? ?? perPage;
    final hasMore = streamCount >= maxPageItems &&
        ((nextPage - 1) * maxPageItems) < totalItems;
    _debugLog(
      () =>
          '📥 [STALKER REPO] totalItems=$totalItems, maxPageItems=$maxPageItems, streams.length=$streamCount',
    );
    _debugLog(
      () => '📥 [STALKER REPO] hasMore=$hasMore (continue? ${hasMore ? "YES" : "NO"})',
    );
    return hasMore;
  }

  int _categoryMaxPages(int categoryCount) {
    if (categoryCount >= 20) return 1;
    if (categoryCount >= 8) return 2;
    return 3;
  }

  Future<List<XtreamPlaylist>> _buildAndSavePlaylists(
    String accountId,
    ({
      List<StalkerCategoryDto> movieCategories,
      List<StalkerCategoryDto> seriesCategories,
      List<StalkerStreamDto> movieStreams,
      List<StalkerStreamDto> seriesStreams,
    }) data,
  ) async {
    final playlists = _mapper.buildPlaylists(
      accountId: accountId,
      movieCategories: data.movieCategories,
      movieStreams: data.movieStreams,
      seriesCategories: data.seriesCategories,
      seriesStreams: data.seriesStreams,
    );

    _debugLog(() => '🔧 [STALKER REPO] Playlists construites: ${playlists.length} playlists');
    for (final pl in playlists) {
      _debugLog(
        () => '🔧 [STALKER REPO]   - ${pl.title} (${pl.type.name}): ${pl.items.length} items',
      );
    }

    await _savePlaylistsChunked(accountId, playlists);
    return playlists;
  }

  Future<void> _savePlaylistsChunked(
    String accountId,
    List<XtreamPlaylist> playlists,
  ) async {
    const chunkSize = 50;
    for (var i = 0; i < playlists.length; i += chunkSize) {
      final chunk = playlists.sublist(
        i,
        i + chunkSize > playlists.length ? playlists.length : i + chunkSize,
      );
      await _local.savePlaylists(accountId, chunk);
      // Laisse respirer l'UI
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _syncPlaylistSettings({
    required String accountId,
    required List<XtreamPlaylist> playlists,
  }) async {
    // Synchronise les paramètres de playlist (ordre, visibilité, etc.)
    // Les playlists Stalker utilisent la même table que Xtream
    // Utilise la même logique que IptvRepositoryImpl
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
      final existingSettings = byId[pl.id];
      int position;
      if (existingSettings != null) {
        position = existingSettings.position;
      } else {
        if (pl.type == XtreamPlaylistType.movies) {
          maxMovies++;
          position = maxMovies;
        } else {
          maxSeries++;
          position = maxSeries;
        }
      }

      final globalPos = existingSettings?.globalPosition ?? (++maxGlobal);
      toUpsert.add(
        XtreamPlaylistSettings(
          accountId: accountId,
          playlistId: pl.id,
          type: pl.type,
          position: position,
          isVisible: existingSettings?.isVisible ?? true,
          globalPosition: globalPos,
          updatedAt: now,
        ),
      );
    }

    // Supprime les settings pour les playlists qui n'existent plus
    final toDelete = existing
        .where((s) => !keepIds.contains(s.playlistId))
        .map((s) => s.playlistId)
        .toList();

    await _local.upsertPlaylistSettingsBatch(toUpsert);
    if (toDelete.isNotEmpty) {
      await _local.deletePlaylistSettingsNotIn(
        accountId: accountId,
        playlistIds: toDelete.toSet(),
      );
    }
  }

  Future<StalkerCatalogSnapshot> _createAndStoreSnapshot(
    String accountId,
    ({
      List<StalkerCategoryDto> movieCategories,
      List<StalkerCategoryDto> seriesCategories,
      List<StalkerStreamDto> movieStreams,
      List<StalkerStreamDto> seriesStreams,
    }) data,
  ) async {
    // 🔧 FIX: Sauvegarder les playlists AVANT le snapshot
    _debugLog(() => '💾 [STALKER REPO] Sauvegarde des playlists en DB...');
    final playlists = await _buildAndSavePlaylists(accountId, data);
    _debugLog(() => '✅ [STALKER REPO] Playlists sauvegardées: ${playlists.length} playlists');
    
    // Synchroniser les settings (ordre, visibilité)
    _debugLog(() => '💾 [STALKER REPO] Synchronisation des settings...');
    await _syncPlaylistSettings(accountId: accountId, playlists: playlists);
    _debugLog(() => '✅ [STALKER REPO] Settings synchronisés');
    
    return _createAndStoreSnapshotFromCounts(
      accountId: accountId,
      movieCount: data.movieStreams.length,
      seriesCount: data.seriesStreams.length,
    );
  }

  Future<StalkerCatalogSnapshot> _createAndStoreSnapshotFromCounts({
    required String accountId,
    required int movieCount,
    required int seriesCount,
  }) async {
    final snapshot = StalkerCatalogSnapshot(
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
}

