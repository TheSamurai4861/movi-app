export 'package:movi/src/core/storage/repositories/iptv/iptv_episode_data.dart';

import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/database/iptv_owner_scope.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_account_store.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_episode_data.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_episode_store.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_playlist_query_store.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_playlist_settings_store.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_playlist_store.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_settings.dart';

/// Repository local pour la persistance des comptes et playlists IPTV.
/// Implémentation basée sur `sqflite` avec conversions typées et garde-fous.
class IptvLocalRepository {
  IptvLocalRepository(
    Database db, {
    String? Function()? ownerIdProvider,
  }) : _ownerIdProvider = ownerIdProvider,
      _accountStore = IptvAccountStore(db),
      _episodeStore = IptvEpisodeStore(db),
      _playlistStore = IptvPlaylistStore(
        db,
        normalizePlaylistType: _normalizePlaylistType,
        normalizeItemType: _normalizeItemType,
      ),
      _playlistQueryStore = IptvPlaylistQueryStore(
        db,
        normalizePlaylistType: _normalizePlaylistType,
        normalizeItemType: _normalizeItemType,
      ),
      _playlistSettingsStore = IptvPlaylistSettingsStore(
        db,
        normalize: _normalizePlaylistType,
      );
  final String? Function()? _ownerIdProvider;
  final IptvAccountStore _accountStore;
  final IptvEpisodeStore _episodeStore;
  final IptvPlaylistStore _playlistStore;
  final IptvPlaylistQueryStore _playlistQueryStore;
  final IptvPlaylistSettingsStore _playlistSettingsStore;

  final Map<String, Future<void>> _v2MigrationByAccount =
      <String, Future<void>>{};

  Future<void> _ensureV2PlaylistsForAccount(String accountId) {
    final ownerId = _currentOwnerId;
    final key = '$ownerId::$accountId';
    final existing = _v2MigrationByAccount[key];
    if (existing != null) return existing;
    final future = _playlistStore.migrateLegacyPlaylistsForAccount(
      ownerId: ownerId,
      accountId: accountId,
    );
    _v2MigrationByAccount[key] = future;
    return future.whenComplete(() {
      _v2MigrationByAccount.remove(key);
    });
  }

  /// Enregistre ou met à jour un [XtreamAccount].
  Future<void> saveAccount(XtreamAccount account) =>
      _accountStore.saveAccount(ownerId: _currentOwnerId, account: account);

  /// Récupère tous les comptes IPTV persistés.
  Future<List<XtreamAccount>> getAccounts({bool includeAllOwners = false}) =>
      _accountStore.getAccounts(
        ownerId: includeAllOwners ? null : _currentOwnerId,
      );

  /// Supprime un compte et ses playlists associées.
  Future<void> removeAccount(String id, {bool includeAllOwners = false}) =>
      _accountStore.removeAccount(
        id,
        ownerId: includeAllOwners ? null : _currentOwnerId,
      );

  // ============================================================================
  // Méthodes Stalker
  // ============================================================================

  Future<void> saveStalkerAccount(StalkerAccount account) =>
      _accountStore.saveStalkerAccount(
        ownerId: _currentOwnerId,
        account: account,
      );

  Future<List<StalkerAccount>> getStalkerAccounts({
    bool includeAllOwners = false,
  }) => _accountStore.getStalkerAccounts(
    ownerId: includeAllOwners ? null : _currentOwnerId,
  );

  Future<StalkerAccount?> getStalkerAccount(
    String id, {
    bool includeAllOwners = false,
  }) => _accountStore.getStalkerAccount(
    id,
    ownerId: includeAllOwners ? null : _currentOwnerId,
  );

  Future<void> removeStalkerAccount(
    String id, {
    bool includeAllOwners = false,
  }) => _accountStore.removeStalkerAccount(
    id,
    ownerId: includeAllOwners ? null : _currentOwnerId,
  );

  /// Sauvegarde les playlists d'un compte (tables v2 normalisées).
  Future<void> savePlaylists(
    String accountId,
    List<XtreamPlaylist> playlists,
  ) => _playlistStore.savePlaylists(
    accountId,
    playlists,
    ownerId: _currentOwnerId,
  );

  /// Récupère les playlists d'un compte (tables v2 normalisées).
  ///
  /// - `itemLimit` (optionnel) limite le nombre d’items par playlist.
  ///   Utile pour l’accueil (preview) afin de réduire I/O et mémoire.
  Future<List<XtreamPlaylist>> getPlaylists(
    String accountId, {
    int? itemLimit,
  }) async {
    await _ensureV2PlaylistsForAccount(accountId);
    return _playlistStore.getPlaylists(
      accountId,
      ownerId: _currentOwnerId,
      itemLimit: itemLimit,
    );
  }

  Future<List<XtreamPlaylistItem>> getPlaylistItems({
    required String accountId,
    required String playlistId,
    required String categoryName,
    required XtreamPlaylistType playlistType,
    int? limit,
    int? offset,
  }) async {
    await _ensureV2PlaylistsForAccount(accountId);
    return _playlistStore.getPlaylistItems(
      ownerId: _currentOwnerId,
      accountId: accountId,
      playlistId: playlistId,
      categoryName: categoryName,
      playlistType: playlistType,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<XtreamPlaylistSettings>> getPlaylistSettings(String accountId) =>
      _playlistSettingsStore.getPlaylistSettings(
        accountId,
        ownerId: _currentOwnerId,
      );

  Future<void> upsertPlaylistSettings(XtreamPlaylistSettings settings) =>
      _playlistSettingsStore.upsertPlaylistSettings(
        settings,
        ownerId: _currentOwnerId,
      );

  Future<void> upsertPlaylistSettingsBatch(
    List<XtreamPlaylistSettings> settings,
  ) => _playlistSettingsStore.upsertPlaylistSettingsBatch(
    settings,
    ownerId: _currentOwnerId,
  );

  Future<void> deletePlaylistSettingsNotIn({
    required String accountId,
    required Set<String> playlistIds,
  }) => _playlistSettingsStore.deletePlaylistSettingsNotIn(
    ownerId: _currentOwnerId,
    accountId: accountId,
    playlistIds: playlistIds,
  );

  Future<void> setPlaylistVisibility({
    required String accountId,
    required String playlistId,
    required bool isVisible,
  }) => _playlistSettingsStore.setPlaylistVisibility(
    ownerId: _currentOwnerId,
    accountId: accountId,
    playlistId: playlistId,
    isVisible: isVisible,
  );

  Future<void> setAllPlaylistsVisibility({
    required String accountId,
    required XtreamPlaylistType type,
    required bool isVisible,
  }) => _playlistSettingsStore.setAllPlaylistsVisibility(
    ownerId: _currentOwnerId,
    accountId: accountId,
    type: type,
    isVisible: isVisible,
  );

  Future<void> reorderPlaylists({
    required String accountId,
    required XtreamPlaylistType type,
    required List<String> orderedPlaylistIds,
  }) => _playlistSettingsStore.reorderPlaylists(
    ownerId: _currentOwnerId,
    accountId: accountId,
    type: type,
    orderedPlaylistIds: orderedPlaylistIds,
  );

  Future<void> reorderPlaylistsGlobal({
    required String accountId,
    required List<String> orderedPlaylistIds,
  }) => _playlistSettingsStore.reorderPlaylistsGlobal(
    ownerId: _currentOwnerId,
    accountId: accountId,
    orderedPlaylistIds: orderedPlaylistIds,
  );

  /// Construit l'ensemble des TMDB IDs disponibles localement.
  Future<Set<int>> getAvailableTmdbIds({
    XtreamPlaylistItemType? type,
    Set<String>? accountIds,
  }) async {
    final accountIdsResolved = await _resolveAccountIds(accountIds);
    if (accountIdsResolved.isEmpty) return <int>{};

    for (final accountId in accountIdsResolved) {
      await _ensureV2PlaylistsForAccount(accountId);
    }
    return _playlistQueryStore.getAvailableTmdbIds(
      ownerId: _currentOwnerId,
      type: type,
      accountIds: accountIdsResolved,
    );
  }

  /// Récupère tous les items de playlist pour les sources actives.
  /// Utilisé pour le préchargement des ratings.
  Future<List<XtreamPlaylistItem>> getAllPlaylistItems({
    Set<String>? accountIds,
    XtreamPlaylistItemType? type,
  }) async {
    final ids = await _resolveAccountIds(accountIds);
    if (ids.isEmpty) return const <XtreamPlaylistItem>[];

    for (final accountId in ids) {
      await _ensureV2PlaylistsForAccount(accountId);
    }
    return _playlistQueryStore.getAllPlaylistItems(
      ownerId: _currentOwnerId,
      accountIds: ids,
      type: type,
    );
  }

  /// Indique si au moins un item de playlist est présent localement.
  ///
  /// Utilisé pour éviter d'arriver sur Home avant la première synchro IPTV.
  Future<bool> hasAnyPlaylistItems({Set<String>? accountIds}) async {
    return _playlistQueryStore.hasAnyPlaylistItems(
      ownerId: _currentOwnerId,
      accountIds: accountIds,
    );
  }

  Future<List<XtreamPlaylistItem>> searchItems(
    String query, {
    int limit = 500,
    Set<String>? accountIds,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const <XtreamPlaylistItem>[];

    final safeLimit = limit <= 0 ? 0 : limit;
    if (safeLimit == 0) return const <XtreamPlaylistItem>[];

    final ids = await _resolveAccountIds(accountIds);
    if (ids.isEmpty) return const <XtreamPlaylistItem>[];

    for (final accountId in ids) {
      await _ensureV2PlaylistsForAccount(accountId);
    }
    return _playlistQueryStore.searchItems(
      q,
      ownerId: _currentOwnerId,
      limit: safeLimit,
      accountIds: ids,
    );
  }

  /// Sauvegarde les épisodes d'une série
  Future<void> saveEpisodes({
    required String accountId,
    required int seriesId,
    required Map<int, Map<int, EpisodeData>> episodes,
  }) => _episodeStore.saveEpisodes(
    ownerId: _currentOwnerId,
    accountId: accountId,
    seriesId: seriesId,
    episodes: episodes,
  );

  /// Récupère l'ID de l'épisode pour une série donnée
  Future<int?> getEpisodeId({
    required String accountId,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
  }) => _episodeStore.getEpisodeId(
    ownerId: _currentOwnerId,
    accountId: accountId,
    seriesId: seriesId,
    seasonNumber: seasonNumber,
    episodeNumber: episodeNumber,
  );

  /// Récupère les données complètes de l'épisode (ID + extension)
  Future<EpisodeData?> getEpisodeData({
    required String accountId,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
  }) => _episodeStore.getEpisodeData(
    ownerId: _currentOwnerId,
    accountId: accountId,
    seriesId: seriesId,
    seasonNumber: seasonNumber,
    episodeNumber: episodeNumber,
  );

  /// Récupère toutes les saisons et épisodes d'une série depuis le cache local
  /// Retourne `Map<seasonNumber, Map<episodeNumber, EpisodeData>>`
  Future<Map<int, Map<int, EpisodeData>>> getAllEpisodesForSeries({
    required String accountId,
    required int seriesId,
  }) => _episodeStore.getAllEpisodesForSeries(
    ownerId: _currentOwnerId,
    accountId: accountId,
    seriesId: seriesId,
  );

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<Set<String>> _resolveAccountIds(Set<String>? accountIds) =>
      _accountStore.resolveAccountIds(accountIds, ownerId: _currentOwnerId);

  String get _currentOwnerId =>
      IptvOwnerScope.normalize(_ownerIdProvider?.call());

  static XtreamPlaylistType _normalizePlaylistType(String? raw) {
    final r = (raw ?? '').toLowerCase().trim();
    for (final t in XtreamPlaylistType.values) {
      if (t.name == r) return t;
    }
    // Tentatives de normalisation simples
    const moviesTokens = <String>{'movie', 'movies', 'vod', 'films'};
    const seriesTokens = <String>{
      'tv',
      'tvshow',
      'tvshows',
      'show',
      'shows',
      'serie',
      'series',
      'tv_series',
      'series_tv',
      'série',
      'séries',
    };
    if (seriesTokens.contains(r)) return XtreamPlaylistType.series;
    if (moviesTokens.contains(r)) return XtreamPlaylistType.movies;
    return XtreamPlaylistType.movies;
  }

  static XtreamPlaylistItemType _normalizeItemType(
    String raw,
    XtreamPlaylistType playlistType,
  ) {
    if (raw.isEmpty || raw == 'null') {
      return playlistType == XtreamPlaylistType.series
          ? XtreamPlaylistItemType.series
          : XtreamPlaylistItemType.movie;
    }

    final r = raw.replaceAll('-', '_');

    for (final t in XtreamPlaylistItemType.values) {
      if (t.name == r) return t;
    }

    const seriesTokens = <String>{
      'tv',
      'tvshow',
      'tvshows',
      'show',
      'shows',
      'serie',
      'series',
      'tv_series',
      'series_tv',
      'série',
      'séries',
      'epg_series',
    };

    if (seriesTokens.contains(r)) return XtreamPlaylistItemType.series;

    return playlistType == XtreamPlaylistType.series
        ? XtreamPlaylistItemType.series
        : XtreamPlaylistItemType.movie;
  }
}
