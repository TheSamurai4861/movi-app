import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_settings.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';

/// Données d'un épisode (ID + extension)
class EpisodeData {
  const EpisodeData({required this.episodeId, this.extension});

  final int episodeId;
  final String? extension;
}

/// Repository local pour la persistance des comptes et playlists IPTV.
/// Implémentation basée sur `sqflite` avec conversions typées et garde-fous.
class IptvLocalRepository {
  IptvLocalRepository(this._db);

  static const String _tblAccounts = 'iptv_accounts';
  static const String _tblStalkerAccounts = 'stalker_accounts';
  static const String _tblPlaylistsLegacy = 'iptv_playlists';
  static const String _tblPlaylists = 'iptv_playlists_v2';
  static const String _tblPlaylistItems = 'iptv_playlist_items_v2';
  static const String _tblEpisodes = 'iptv_episodes';
  static const String _tblPlaylistSettings = 'iptv_playlist_settings';

  final Database _db;

  final Map<String, Future<void>> _v2MigrationByAccount =
      <String, Future<void>>{};

  Future<void> _ensureV2PlaylistsForAccount(String accountId) {
    final existing = _v2MigrationByAccount[accountId];
    if (existing != null) return existing;
    final future = _ensureV2PlaylistsForAccountImpl(accountId);
    _v2MigrationByAccount[accountId] = future;
    return future.whenComplete(() {
      _v2MigrationByAccount.remove(accountId);
    });
  }

  Future<void> _ensureV2PlaylistsForAccountImpl(String accountId) async {
    final db = _db;

    final legacyHasAny = await _hasAnyRow(
      db,
      table: _tblPlaylistsLegacy,
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );
    if (!legacyHasAny) return;

    // Important: ne pas charger `payload` pour toutes les playlists d’un coup
    // (peut dépasser le CursorWindow Android). On récupère d’abord les IDs,
    // puis on migre playlist par playlist.
    final legacyRows = await db.query(
      _tblPlaylistsLegacy,
      columns: const ['category_id', 'updated_at'],
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );
    if (legacyRows.isEmpty) return;

    for (final row in legacyRows) {
      final playlistId = row['category_id'] as String?;
      if (playlistId == null || playlistId.isEmpty) continue;

      final payloadRow = await db.query(
        _tblPlaylistsLegacy,
        columns: const ['payload'],
        where: 'account_id = ? AND category_id = ?',
        whereArgs: <Object?>[accountId, playlistId],
        limit: 1,
      );
      if (payloadRow.isEmpty) continue;

      final payload = _decodeMap(payloadRow.first['payload']);
      if (payload == null) continue;

      final String title = _asString(payload['title']) ?? '';
      final XtreamPlaylistType playlistType = _normalizePlaylistType(
        _asString(payload['type']),
      );

      final int updatedAt =
          (row['updated_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch;

      final List<dynamic> itemsList = _asList(payload['items']);

      await db.transaction((txn) async {
        await txn.insert(_tblPlaylists, <String, Object?>{
          'account_id': accountId,
          'playlist_id': playlistId,
          'title': title,
          'type': playlistType.name,
          'updated_at': updatedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        await txn.delete(
          _tblPlaylistItems,
          where: 'account_id = ? AND playlist_id = ?',
          whereArgs: <Object?>[accountId, playlistId],
        );

        if (itemsList.isNotEmpty) {
          var batch = txn.batch();
          const chunkSize = 400;
          var pos = 0;

          for (final dynamic raw in itemsList) {
            if (raw is! Map) continue;
            final map = Map<String, dynamic>.from(raw);

            final int? streamId = _asNum(map['streamId'])?.toInt();
            final String itemTitle = _asString(map['title']) ?? '';
            if (streamId == null || itemTitle.isEmpty) continue;

            final String rawType = (_asString(map['type']) ?? '')
                .toLowerCase()
                .trim();
            final XtreamPlaylistItemType itemType = _normalizeItemType(
              rawType,
              playlistType,
            );

            batch.insert(_tblPlaylistItems, <String, Object?>{
              'account_id': accountId,
              'playlist_id': playlistId,
              'stream_id': streamId,
              'position': pos++,
              'title': itemTitle,
              'type': itemType.name,
              'poster': _asString(map['poster']),
              'tmdb_id': _asNum(map['tmdbId'])?.toInt(),
              'container_extension': _asString(map['containerExtension']),
              'rating': _asNum(map['rating'])?.toDouble(),
              'release_year': _asNum(map['releaseYear'])?.toInt(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            if (pos % chunkSize == 0) {
              await batch.commit(noResult: true);
              batch = txn.batch();
            }
          }

          await batch.commit(noResult: true);
        }

        await txn.delete(
          _tblPlaylistsLegacy,
          where: 'account_id = ? AND category_id = ?',
          whereArgs: <Object?>[accountId, playlistId],
        );
      });

      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Enregistre ou met à jour un [XtreamAccount].
  Future<void> saveAccount(XtreamAccount account) async {
    await _db.insert(_tblAccounts, <String, Object?>{
      'account_id': account.id,
      'alias': account.alias,
      'endpoint': account.endpoint.toRawUrl(),
      'username': account.username,
      'status': account.status.name,
      'expiration': account.expirationDate?.millisecondsSinceEpoch,
      'created_at': account.createdAt.millisecondsSinceEpoch,
      'last_error': account.lastError,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Récupère tous les comptes IPTV persistés.
  Future<List<XtreamAccount>> getAccounts() async {
    final rows = await _db.query(_tblAccounts);
    return rows.map(_parseAccountRow).toList(growable: false);
  }

  /// Supprime un compte et ses playlists associées.
  Future<void> removeAccount(String id) async {
    await _db.delete(
      _tblAccounts,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _db.delete(
      _tblPlaylistItems,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _db.delete(
      _tblPlaylists,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _db.delete(
      _tblPlaylistsLegacy,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _db.delete(
      _tblEpisodes,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
  }

  // ============================================================================
  // Méthodes Stalker
  // ============================================================================

  Future<void> saveStalkerAccount(StalkerAccount account) async {
    await _db.insert(_tblStalkerAccounts, <String, Object?>{
      'account_id': account.id,
      'alias': account.alias,
      'endpoint': account.endpoint.toRawUrl(),
      'mac_address': account.macAddress,
      'username': account.username,
      'token': account.token,
      'status': account.status.name,
      'expiration': account.expirationDate?.millisecondsSinceEpoch,
      'created_at': account.createdAt.millisecondsSinceEpoch,
      'last_error': account.lastError,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<StalkerAccount>> getStalkerAccounts() async {
    final rows = await _db.query(_tblStalkerAccounts);
    return rows.map(_parseStalkerAccountRow).toList(growable: false);
  }

  Future<StalkerAccount?> getStalkerAccount(String id) async {
    final rows = await _db.query(
      _tblStalkerAccounts,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _parseStalkerAccountRow(rows.first);
  }

  Future<void> removeStalkerAccount(String id) async {
    await _db.delete(
      _tblStalkerAccounts,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    // Supprime aussi les playlists associées (elles utilisent le même account_id)
    await _db.delete(
      _tblPlaylistItems,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _db.delete(
      _tblPlaylists,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _db.delete(
      _tblPlaylistsLegacy,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _db.delete(
      _tblEpisodes,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
  }

  StalkerAccount _parseStalkerAccountRow(Map<String, Object?> row) {
    final String id = (row['account_id'] as String?) ?? '';
    final String alias = (row['alias'] as String?) ?? '';
    final String endpointRaw = (row['endpoint'] as String?) ?? '';
    final String macAddress = (row['mac_address'] as String?) ?? '';
    final String? username = row['username'] as String?;
    final String? token = row['token'] as String?;
    final String statusStr =
        (row['status'] as String?) ?? StalkerAccountStatus.pending.name;
    final int createdAtMs = (row['created_at'] as int?) ?? 0;
    final int? expirationMs = row['expiration'] as int?;
    final String? lastError = row['last_error'] as String?;

    final StalkerAccountStatus status = StalkerAccountStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => StalkerAccountStatus.pending,
    );

    return StalkerAccount(
      id: id,
      alias: alias,
      endpoint: StalkerEndpoint.parse(endpointRaw),
      macAddress: macAddress,
      username: username,
      token: token,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      expirationDate: expirationMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expirationMs)
          : null,
      lastError: lastError,
    );
  }

  /// Sauvegarde les playlists d'un compte (tables v2 normalisées).
  Future<void> savePlaylists(
    String accountId,
    List<XtreamPlaylist> playlists,
  ) async {
    final db = _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final playlist in playlists) {
      await db.transaction((txn) async {
        await txn.insert(_tblPlaylists, <String, Object?>{
          'account_id': accountId,
          'playlist_id': playlist.id,
          'title': playlist.title,
          'type': playlist.type.name,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        await txn.delete(
          _tblPlaylistItems,
          where: 'account_id = ? AND playlist_id = ?',
          whereArgs: <Object?>[accountId, playlist.id],
        );

        if (playlist.items.isNotEmpty) {
          var batch = txn.batch();
          const chunkSize = 400;

          for (var i = 0; i < playlist.items.length; i++) {
            final item = playlist.items[i];
            batch.insert(_tblPlaylistItems, <String, Object?>{
              'account_id': accountId,
              'playlist_id': playlist.id,
              'stream_id': item.streamId,
              'position': i,
              'title': item.title,
              'type': item.type.name,
              'poster': item.posterUrl,
              'tmdb_id': item.tmdbId,
              'container_extension': item.containerExtension,
              'rating': item.rating,
              'release_year': item.releaseYear,
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            if ((i + 1) % chunkSize == 0) {
              await batch.commit(noResult: true);
              batch = txn.batch();
            }
          }
          await batch.commit(noResult: true);
        }

        // Nettoyage best-effort de l'ancien format (évite de conserver de gros JSON).
        await txn.delete(
          _tblPlaylistsLegacy,
          where: 'account_id = ? AND category_id = ?',
          whereArgs: <Object?>[accountId, playlist.id],
        );
      });
    }
  }

  /// Récupère les playlists d'un compte (tables v2 normalisées).
  ///
  /// - `itemLimit` (optionnel) limite le nombre d’items par playlist.
  ///   Utile pour l’accueil (preview) afin de réduire I/O et mémoire.
  Future<List<XtreamPlaylist>> getPlaylists(
    String accountId, {
    int? itemLimit,
  }) async {
    await _ensureV2PlaylistsForAccount(accountId);

    final db = _db;
    final rows = await db.query(
      _tblPlaylists,
      columns: const ['playlist_id', 'title', 'type'],
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );

    final result = <XtreamPlaylist>[];
    for (final row in rows) {
      final playlistId = row['playlist_id'] as String?;
      final title = row['title'] as String?;
      final typeRaw = row['type'] as String?;
      if (playlistId == null || title == null || typeRaw == null) continue;

      final playlistType = _normalizePlaylistType(typeRaw);
      final items = (itemLimit != null && itemLimit <= 0)
          ? const <XtreamPlaylistItem>[]
          : await getPlaylistItems(
              accountId: accountId,
              playlistId: playlistId,
              categoryName: title,
              playlistType: playlistType,
              limit: itemLimit,
            );
      result.add(
        XtreamPlaylist(
          id: playlistId,
          accountId: accountId,
          title: title,
          type: playlistType,
          items: items,
        ),
      );
    }

    return result;
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

    final db = _db;
    final rows = await db.query(
      _tblPlaylistItems,
      columns: const [
        'stream_id',
        'title',
        'type',
        'poster',
        'tmdb_id',
        'container_extension',
        'rating',
        'release_year',
      ],
      where: 'account_id = ? AND playlist_id = ?',
      whereArgs: <Object?>[accountId, playlistId],
      orderBy: 'position ASC',
      limit: limit,
      offset: offset,
    );

    final items = <XtreamPlaylistItem>[];
    for (final row in rows) {
      final streamId = row['stream_id'] as int?;
      final title = row['title'] as String?;
      final typeRaw = row['type']?.toString();
      if (streamId == null || title == null) continue;

      final itemType = _normalizeItemType(
        (typeRaw ?? '').toLowerCase().trim(),
        playlistType,
      );

      items.add(
        XtreamPlaylistItem(
          accountId: accountId,
          categoryId: playlistId,
          categoryName: categoryName,
          streamId: streamId,
          title: title,
          type: itemType,
          overview: null,
          tmdbId: (row['tmdb_id'] as int?),
          posterUrl: row['poster'] as String?,
          containerExtension: row['container_extension'] as String?,
          rating: (row['rating'] as num?)?.toDouble(),
          releaseYear: row['release_year'] as int?,
        ),
      );
    }
    return items;
  }

  Future<List<XtreamPlaylistSettings>> getPlaylistSettings(
    String accountId,
  ) async {
    final db = _db;
    final rows = await db.query(
      _tblPlaylistSettings,
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );

    final out = <XtreamPlaylistSettings>[];
    for (final row in rows) {
      final playlistId = row['playlist_id'] as String?;
      final typeRaw = row['type'] as String?;
      final position = row['position'] as int?;
      final globalPosition = row['global_position'] as int?;
      final isVisibleNum = row['is_visible'] as int?;
      final updatedAtMs = row['updated_at'] as int?;
      if (playlistId == null ||
          typeRaw == null ||
          position == null ||
          isVisibleNum == null ||
          updatedAtMs == null) {
        continue;
      }

      final type = _normalizePlaylistType(typeRaw);
      out.add(
        XtreamPlaylistSettings(
          accountId: accountId,
          playlistId: playlistId,
          type: type,
          position: position,
          globalPosition: globalPosition ?? 0,
          isVisible: isVisibleNum == 1,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
        ),
      );
    }
    return out;
  }

  Future<void> upsertPlaylistSettings(XtreamPlaylistSettings settings) async {
    final db = _db;
    await db.insert(_tblPlaylistSettings, <String, Object?>{
      'account_id': settings.accountId,
      'playlist_id': settings.playlistId,
      'type': settings.type.name,
      'position': settings.position,
      'global_position': settings.globalPosition,
      'is_visible': settings.isVisible ? 1 : 0,
      'updated_at': settings.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertPlaylistSettingsBatch(
    List<XtreamPlaylistSettings> settings,
  ) async {
    if (settings.isEmpty) return;
    final db = _db;
    final batch = db.batch();
    for (final s in settings) {
      batch.insert(_tblPlaylistSettings, <String, Object?>{
        'account_id': s.accountId,
        'playlist_id': s.playlistId,
        'type': s.type.name,
        'position': s.position,
        'global_position': s.globalPosition,
        'is_visible': s.isVisible ? 1 : 0,
        'updated_at': s.updatedAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deletePlaylistSettingsNotIn({
    required String accountId,
    required Set<String> playlistIds,
  }) async {
    final db = _db;
    if (playlistIds.isEmpty) {
      await db.delete(
        _tblPlaylistSettings,
        where: 'account_id = ?',
        whereArgs: <Object?>[accountId],
      );
      return;
    }

    final placeholders = List.filled(playlistIds.length, '?').join(',');
    await db.delete(
      _tblPlaylistSettings,
      where: 'account_id = ? AND playlist_id NOT IN ($placeholders)',
      whereArgs: <Object?>[accountId, ...playlistIds],
    );
  }

  Future<void> setPlaylistVisibility({
    required String accountId,
    required String playlistId,
    required bool isVisible,
  }) async {
    final db = _db;
    await db.update(
      _tblPlaylistSettings,
      <String, Object?>{
        'is_visible': isVisible ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'account_id = ? AND playlist_id = ?',
      whereArgs: <Object?>[accountId, playlistId],
    );
  }

  Future<void> setAllPlaylistsVisibility({
    required String accountId,
    required XtreamPlaylistType type,
    required bool isVisible,
  }) async {
    final db = _db;
    await db.update(
      _tblPlaylistSettings,
      <String, Object?>{
        'is_visible': isVisible ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'account_id = ? AND type = ?',
      whereArgs: <Object?>[accountId, type.name],
    );
  }

  Future<void> reorderPlaylists({
    required String accountId,
    required XtreamPlaylistType type,
    required List<String> orderedPlaylistIds,
  }) async {
    final db = _db;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < orderedPlaylistIds.length; i++) {
      batch.update(
        _tblPlaylistSettings,
        <String, Object?>{'position': i, 'updated_at': now},
        where: 'account_id = ? AND playlist_id = ? AND type = ?',
        whereArgs: <Object?>[accountId, orderedPlaylistIds[i], type.name],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> reorderPlaylistsGlobal({
    required String accountId,
    required List<String> orderedPlaylistIds,
  }) async {
    final db = _db;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < orderedPlaylistIds.length; i++) {
      batch.update(
        _tblPlaylistSettings,
        <String, Object?>{'global_position': i, 'updated_at': now},
        where: 'account_id = ? AND playlist_id = ?',
        whereArgs: <Object?>[accountId, orderedPlaylistIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

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

    final where = StringBuffer('tmdb_id IS NOT NULL AND tmdb_id > 0');
    final args = <Object?>[];
    if (type != null) {
      where.write(' AND type = ?');
      args.add(type.name);
    }
    if (accountIds != null && accountIds.isNotEmpty) {
      where.write(' AND account_id IN (');
      where.write(List.filled(accountIdsResolved.length, '?').join(','));
      where.write(')');
      args.addAll(accountIdsResolved);
    }

    final db = _db;
    final rows = await db.query(
      _tblPlaylistItems,
      distinct: true,
      columns: const ['tmdb_id'],
      where: where.toString(),
      whereArgs: args,
    );

    final ids = <int>{};
    for (final row in rows) {
      final raw = row['tmdb_id'];
      final id = switch (raw) {
        final int v => v,
        final num v => v.toInt(),
        final String v => int.tryParse(v),
        _ => null,
      };
      if (id != null && id > 0) ids.add(id);
    }
    return ids;
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

    final where = StringBuffer('1 = 1');
    final args = <Object?>[];
    if (accountIds != null && accountIds.isNotEmpty) {
      where.write(' AND i.account_id IN (');
      where.write(List.filled(ids.length, '?').join(','));
      where.write(')');
      args.addAll(ids);
    }
    if (type != null) {
      where.write(' AND i.type = ?');
      args.add(type.name);
    }

    final db = _db;
    final rows = await db.rawQuery('''
      SELECT
        i.account_id AS account_id,
        i.playlist_id AS playlist_id,
        p.title AS category_name,
        p.type AS playlist_type,
        i.stream_id AS stream_id,
        i.title AS item_title,
        i.type AS item_type,
        i.poster AS poster,
        i.tmdb_id AS tmdb_id,
        i.container_extension AS container_extension,
        i.rating AS rating,
        i.release_year AS release_year
      FROM $_tblPlaylistItems i
      JOIN $_tblPlaylists p
        ON p.account_id = i.account_id
       AND p.playlist_id = i.playlist_id
      WHERE $where
      ORDER BY i.account_id, i.playlist_id, i.position
      ''', args);

    final items = <XtreamPlaylistItem>[];
    for (final row in rows) {
      final accountId = row['account_id']?.toString() ?? '';
      final playlistId = row['playlist_id']?.toString() ?? '';
      final categoryName = row['category_name']?.toString() ?? '';
      final streamId = row['stream_id'] as int?;
      final title = row['item_title']?.toString() ?? '';
      if (accountId.isEmpty || playlistId.isEmpty || streamId == null) continue;
      if (title.trim().isEmpty) continue;

      final playlistType = _normalizePlaylistType(
        row['playlist_type']?.toString(),
      );
      final itemType = _normalizeItemType(
        (row['item_type']?.toString() ?? '').toLowerCase().trim(),
        playlistType,
      );

      items.add(
        XtreamPlaylistItem(
          accountId: accountId,
          categoryId: playlistId,
          categoryName: categoryName.isEmpty ? playlistId : categoryName,
          streamId: streamId,
          title: title,
          type: itemType,
          overview: null,
          posterUrl: row['poster']?.toString(),
          containerExtension: row['container_extension']?.toString(),
          tmdbId: (row['tmdb_id'] as int?),
          rating: (row['rating'] as num?)?.toDouble(),
          releaseYear: row['release_year'] as int?,
        ),
      );
    }
    return items;
  }

  /// Indique si au moins un item de playlist est présent localement.
  ///
  /// Utilisé pour éviter d'arriver sur Home avant la première synchro IPTV.
  Future<bool> hasAnyPlaylistItems({Set<String>? accountIds}) async {
    // 🔧 FIX: Ne pas filtrer par type de compte (Xtream/Stalker)
    // Query directement la DB pour tous les accountIds fournis
    if (accountIds != null && accountIds.isNotEmpty) {
      // Pour les IDs fournis, query directement sans filtrer par type
      final db = _db;
      final where = 'account_id IN (${List.filled(accountIds.length, '?').join(',')})';
      final rows = await db.query(
        _tblPlaylistItems,
        columns: const ['account_id'],
        where: where,
        whereArgs: accountIds.toList(),
        limit: 1,
      );
      return rows.isNotEmpty;
    }

    // Sans accountIds spécifiques, checker tous les comptes (Xtream + Stalker)
    final db = _db;
    final rows = await db.query(
      _tblPlaylistItems,
      columns: const ['account_id'],
      limit: 1,
    );
    return rows.isNotEmpty;
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

    final db = _db;
    final like = '%$q%';
    final prefix = '$q%';
    final where = StringBuffer('''
        i.title IS NOT NULL
        AND i.title <> ''
        AND i.title LIKE ? COLLATE NOCASE
      ''');
    final args = <Object?>[like];
    if (accountIds != null && accountIds.isNotEmpty) {
      where.write(' AND i.account_id IN (');
      where.write(List.filled(ids.length, '?').join(','));
      where.write(')');
      args.addAll(ids);
    }

    final rows = await db.rawQuery(
      '''
      SELECT
        i.account_id AS account_id,
        i.playlist_id AS playlist_id,
        p.title AS category_name,
        p.type AS playlist_type,
        i.stream_id AS stream_id,
        i.title AS item_title,
        i.type AS item_type,
        i.poster AS poster,
        i.tmdb_id AS tmdb_id,
        i.container_extension AS container_extension,
        i.rating AS rating,
        i.release_year AS release_year
      FROM $_tblPlaylistItems i
      JOIN $_tblPlaylists p
        ON p.account_id = i.account_id
       AND p.playlist_id = i.playlist_id
      WHERE $where
      ORDER BY
        CASE WHEN i.title LIKE ? COLLATE NOCASE THEN 0 ELSE 1 END,
        LENGTH(i.title) ASC,
        i.title COLLATE NOCASE ASC
      LIMIT ?
      ''',
      <Object?>[...args, prefix, safeLimit],
    );

    final items = <XtreamPlaylistItem>[];
    for (final row in rows) {
      final accountId = row['account_id']?.toString() ?? '';
      final playlistId = row['playlist_id']?.toString() ?? '';
      final categoryName = row['category_name']?.toString() ?? '';
      final streamId = row['stream_id'] as int?;
      final title = row['item_title']?.toString() ?? '';
      if (accountId.isEmpty || playlistId.isEmpty || streamId == null) continue;
      if (title.trim().isEmpty) continue;

      final playlistType = _normalizePlaylistType(
        row['playlist_type']?.toString(),
      );
      final itemType = _normalizeItemType(
        (row['item_type']?.toString() ?? '').toLowerCase().trim(),
        playlistType,
      );

      items.add(
        XtreamPlaylistItem(
          accountId: accountId,
          categoryId: playlistId,
          categoryName: categoryName.isEmpty ? playlistId : categoryName,
          streamId: streamId,
          title: title,
          type: itemType,
          overview: null,
          posterUrl: row['poster']?.toString(),
          containerExtension: row['container_extension']?.toString(),
          tmdbId: (row['tmdb_id'] as int?),
          rating: (row['rating'] as num?)?.toDouble(),
          releaseYear: row['release_year'] as int?,
        ),
      );
    }
    return items;
  }

  /// Sauvegarde les épisodes d'une série
  Future<void> saveEpisodes({
    required String accountId,
    required int seriesId,
    required Map<int, Map<int, EpisodeData>>
    episodes, // Map<seasonNumber, Map<episodeNumber, EpisodeData>>
  }) async {
    final db = _db;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Supprimer les anciens épisodes de cette série
    batch.delete(
      _tblEpisodes,
      where: 'account_id = ? AND series_id = ?',
      whereArgs: <Object?>[accountId, seriesId],
    );

    // Ajouter les nouveaux épisodes
    for (final seasonEntry in episodes.entries) {
      final seasonNumber = seasonEntry.key;
      for (final episodeEntry in seasonEntry.value.entries) {
        final episodeNumber = episodeEntry.key;
        final episodeData = episodeEntry.value;
        batch.insert(_tblEpisodes, <String, Object?>{
          'account_id': accountId,
          'series_id': seriesId,
          'season_number': seasonNumber,
          'episode_number': episodeNumber,
          'episode_id': episodeData.episodeId,
          'extension': episodeData.extension,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    await batch.commit(noResult: true);
  }

  /// Récupère l'ID de l'épisode pour une série donnée
  Future<int?> getEpisodeId({
    required String accountId,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    final data = await getEpisodeData(
      accountId: accountId,
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    return data?.episodeId;
  }

  /// Récupère les données complètes de l'épisode (ID + extension)
  Future<EpisodeData?> getEpisodeData({
    required String accountId,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    final db = _db;
    final rows = await db.query(
      _tblEpisodes,
      columns: ['episode_id', 'extension'],
      where:
          'account_id = ? AND series_id = ? AND season_number = ? AND episode_number = ?',
      whereArgs: <Object?>[accountId, seriesId, seasonNumber, episodeNumber],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final episodeId = rows.first['episode_id'] as int?;
    final extension = rows.first['extension'] as String?;
    if (episodeId == null) return null;
    return EpisodeData(episodeId: episodeId, extension: extension);
  }

  /// Récupère toutes les saisons et épisodes d'une série depuis le cache local
  /// Retourne `Map<seasonNumber, Map<episodeNumber, EpisodeData>>`
  Future<Map<int, Map<int, EpisodeData>>> getAllEpisodesForSeries({
    required String accountId,
    required int seriesId,
  }) async {
    final db = _db;
    final rows = await db.query(
      _tblEpisodes,
      where: 'account_id = ? AND series_id = ?',
      whereArgs: <Object?>[accountId, seriesId],
      orderBy: 'season_number ASC, episode_number ASC',
    );

    final result = <int, Map<int, EpisodeData>>{};
    for (final row in rows) {
      final seasonNumber = row['season_number'] as int?;
      final episodeNumber = row['episode_number'] as int?;
      final episodeId = row['episode_id'] as int?;
      final extension = row['extension'] as String?;

      if (seasonNumber != null && episodeNumber != null && episodeId != null) {
        result.putIfAbsent(seasonNumber, () => <int, EpisodeData>{});
        result[seasonNumber]![episodeNumber] = EpisodeData(
          episodeId: episodeId,
          extension: extension,
        );
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  XtreamAccount _parseAccountRow(Map<String, Object?> row) {
    final String id = (row['account_id'] as String?) ?? '';
    final String alias = (row['alias'] as String?) ?? '';
    final String endpointRaw = (row['endpoint'] as String?) ?? '';
    final String username = (row['username'] as String?) ?? '';
    final String statusStr =
        (row['status'] as String?) ?? XtreamAccountStatus.pending.name;
    final int createdAtMs = (row['created_at'] as int?) ?? 0;
    final int? expirationMs = row['expiration'] as int?;
    final String? lastError = row['last_error'] as String?;

    final XtreamAccountStatus status = XtreamAccountStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => XtreamAccountStatus.pending,
    );

    return XtreamAccount(
      id: id,
      alias: alias,
      endpoint: XtreamEndpoint.parse(endpointRaw),
      username: username,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      expirationDate: expirationMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expirationMs)
          : null,
      lastError: lastError,
    );
  }

  Future<Set<String>> _resolveAccountIds(Set<String>? accountIds) async {
    final xtreamAccounts = await getAccounts();
    final stalkerAccounts = await getStalkerAccounts();
    final ids = <String>{
      ...xtreamAccounts.map((a) => a.id),
      ...stalkerAccounts.map((a) => a.id),
    };
    if (accountIds == null) {
      return ids;
    }
    if (accountIds.isEmpty) {
      return <String>{};
    }
    ids.removeWhere((id) => !accountIds.contains(id));
    return ids;
  }

  Map<String, dynamic>? _decodeMap(Object? raw) {
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        return null;
      }
      return null;
    }
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  List<dynamic> _asList(Object? v) {
    if (v is List) return List<dynamic>.from(v);
    return const <dynamic>[];
  }

  String? _asString(Object? v) => v?.toString();

  num? _asNum(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  Future<bool> _hasAnyRow(
    Database db, {
    required String table,
    required String where,
    required List<Object?> whereArgs,
  }) async {
    try {
      final exists = await db.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1;",
        [table],
      );
      if (exists.isEmpty) return false;

      final rows = await db.query(
        table,
        columns: const ['rowid'],
        where: where,
        whereArgs: whereArgs,
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  XtreamPlaylistType _normalizePlaylistType(String? raw) {
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

  XtreamPlaylistItemType _normalizeItemType(
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
