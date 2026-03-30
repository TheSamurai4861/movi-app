import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/repositories/iptv/iptv_storage_tables.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

typedef PlaylistTypeNormalizer = XtreamPlaylistType Function(String? rawValue);
typedef PlaylistItemTypeNormalizer =
    XtreamPlaylistItemType Function(
      String rawValue,
      XtreamPlaylistType playlistType,
    );

/// Persists normalized IPTV playlists and migrates the legacy payload table.
class IptvPlaylistStore {
  IptvPlaylistStore(
    this._db, {
    required PlaylistTypeNormalizer normalizePlaylistType,
    required PlaylistItemTypeNormalizer normalizeItemType,
  }) : _normalizePlaylistType = normalizePlaylistType,
       _normalizeItemType = normalizeItemType;

  final Database _db;
  final PlaylistTypeNormalizer _normalizePlaylistType;
  final PlaylistItemTypeNormalizer _normalizeItemType;

  Future<void> migrateLegacyPlaylistsForAccount(String accountId) async {
    final legacyHasAny = await _hasAnyRow(
      table: IptvStorageTables.playlistsLegacy,
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );
    if (!legacyHasAny) return;

    final legacyRows = await _db.query(
      IptvStorageTables.playlistsLegacy,
      columns: const ['category_id', 'updated_at'],
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );
    if (legacyRows.isEmpty) return;

    for (final row in legacyRows) {
      final playlistId = row['category_id'] as String?;
      if (playlistId == null || playlistId.isEmpty) continue;

      final payloadRow = await _db.query(
        IptvStorageTables.playlistsLegacy,
        columns: const ['payload'],
        where: 'account_id = ? AND category_id = ?',
        whereArgs: <Object?>[accountId, playlistId],
        limit: 1,
      );
      if (payloadRow.isEmpty) continue;

      final payload = _decodeMap(payloadRow.first['payload']);
      if (payload == null) continue;

      final title = _asString(payload['title']) ?? '';
      final playlistType = _normalizePlaylistType(_asString(payload['type']));
      final updatedAt =
          (row['updated_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
      final itemsList = _asList(payload['items']);

      await _db.transaction((txn) async {
        await txn.insert(
          IptvStorageTables.playlists,
          <String, Object?>{
            'account_id': accountId,
            'playlist_id': playlistId,
            'title': title,
            'type': playlistType.name,
            'updated_at': updatedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.delete(
          IptvStorageTables.playlistItems,
          where: 'account_id = ? AND playlist_id = ?',
          whereArgs: <Object?>[accountId, playlistId],
        );

        if (itemsList.isNotEmpty) {
          var batch = txn.batch();
          const chunkSize = 400;
          var position = 0;

          for (final raw in itemsList) {
            if (raw is! Map) continue;
            final map = Map<String, dynamic>.from(raw);

            final streamId = _asNum(map['streamId'])?.toInt();
            final itemTitle = _asString(map['title']) ?? '';
            if (streamId == null || itemTitle.isEmpty) continue;

            final rawType = (_asString(map['type']) ?? '').toLowerCase().trim();
            final itemType = _normalizeItemType(rawType, playlistType);

            batch.insert(
              IptvStorageTables.playlistItems,
              <String, Object?>{
                'account_id': accountId,
                'playlist_id': playlistId,
                'stream_id': streamId,
                'position': position++,
                'title': itemTitle,
                'type': itemType.name,
                'poster': _asString(map['poster']),
                'tmdb_id': _asNum(map['tmdbId'])?.toInt(),
                'container_extension': _asString(map['containerExtension']),
                'rating': _asNum(map['rating'])?.toDouble(),
                'release_year': _asNum(map['releaseYear'])?.toInt(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            if (position % chunkSize == 0) {
              await batch.commit(noResult: true);
              batch = txn.batch();
            }
          }

          await batch.commit(noResult: true);
        }

        await txn.delete(
          IptvStorageTables.playlistsLegacy,
          where: 'account_id = ? AND category_id = ?',
          whereArgs: <Object?>[accountId, playlistId],
        );
      });

      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> savePlaylists(
    String accountId,
    List<XtreamPlaylist> playlists,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final playlist in playlists) {
      await _db.transaction((txn) async {
        await txn.insert(
          IptvStorageTables.playlists,
          <String, Object?>{
            'account_id': accountId,
            'playlist_id': playlist.id,
            'title': playlist.title,
            'type': playlist.type.name,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.delete(
          IptvStorageTables.playlistItems,
          where: 'account_id = ? AND playlist_id = ?',
          whereArgs: <Object?>[accountId, playlist.id],
        );

        if (playlist.items.isNotEmpty) {
          var batch = txn.batch();
          const chunkSize = 400;

          for (var index = 0; index < playlist.items.length; index++) {
            final item = playlist.items[index];
            batch.insert(
              IptvStorageTables.playlistItems,
              <String, Object?>{
                'account_id': accountId,
                'playlist_id': playlist.id,
                'stream_id': item.streamId,
                'position': index,
                'title': item.title,
                'type': item.type.name,
                'poster': item.posterUrl,
                'tmdb_id': item.tmdbId,
                'container_extension': item.containerExtension,
                'rating': item.rating,
                'release_year': item.releaseYear,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            if ((index + 1) % chunkSize == 0) {
              await batch.commit(noResult: true);
              batch = txn.batch();
            }
          }

          await batch.commit(noResult: true);
        }

        await txn.delete(
          IptvStorageTables.playlistsLegacy,
          where: 'account_id = ? AND category_id = ?',
          whereArgs: <Object?>[accountId, playlist.id],
        );
      });
    }
  }

  Future<List<XtreamPlaylist>> getPlaylists(
    String accountId, {
    int? itemLimit,
  }) async {
    final rows = await _db.query(
      IptvStorageTables.playlists,
      columns: const ['playlist_id', 'title', 'type'],
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );

    final playlists = <XtreamPlaylist>[];
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

      playlists.add(
        XtreamPlaylist(
          id: playlistId,
          accountId: accountId,
          title: title,
          type: playlistType,
          items: items,
        ),
      );
    }

    return playlists;
  }

  Future<List<XtreamPlaylistItem>> getPlaylistItems({
    required String accountId,
    required String playlistId,
    required String categoryName,
    required XtreamPlaylistType playlistType,
    int? limit,
    int? offset,
  }) async {
    final rows = await _db.query(
      IptvStorageTables.playlistItems,
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
          tmdbId: row['tmdb_id'] as int?,
          posterUrl: row['poster'] as String?,
          containerExtension: row['container_extension'] as String?,
          rating: (row['rating'] as num?)?.toDouble(),
          releaseYear: row['release_year'] as int?,
        ),
      );
    }

    return items;
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

  List<dynamic> _asList(Object? value) {
    if (value is List) return List<dynamic>.from(value);
    return const <dynamic>[];
  }

  String? _asString(Object? value) => value?.toString();

  num? _asNum(Object? value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  Future<bool> _hasAnyRow({
    required String table,
    required String where,
    required List<Object?> whereArgs,
  }) async {
    try {
      final exists = await _db.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1;",
        [table],
      );
      if (exists.isEmpty) return false;

      final rows = await _db.query(
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
}
