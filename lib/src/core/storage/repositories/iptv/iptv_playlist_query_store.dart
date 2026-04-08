import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/repositories/iptv/iptv_playlist_store.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_storage_tables.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

/// Read-only queries over normalized IPTV playlists and playlist items.
class IptvPlaylistQueryStore {
  IptvPlaylistQueryStore(
    this._db, {
    required PlaylistTypeNormalizer normalizePlaylistType,
    required PlaylistItemTypeNormalizer normalizeItemType,
  }) : _normalizePlaylistType = normalizePlaylistType,
       _normalizeItemType = normalizeItemType;

  final Database _db;
  final PlaylistTypeNormalizer _normalizePlaylistType;
  final PlaylistItemTypeNormalizer _normalizeItemType;

  Future<Set<int>> getAvailableTmdbIds({
    required String ownerId,
    XtreamPlaylistItemType? type,
    Set<String>? accountIds,
  }) async {
    if (accountIds != null && accountIds.isEmpty) return <int>{};

    final where = StringBuffer(
      'owner_id = ? AND tmdb_id IS NOT NULL AND tmdb_id > 0',
    );
    final args = <Object?>[ownerId];
    if (type != null) {
      where.write(' AND type = ?');
      args.add(type.name);
    }
    if (accountIds != null && accountIds.isNotEmpty) {
      where.write(' AND account_id IN (');
      where.write(List.filled(accountIds.length, '?').join(','));
      where.write(')');
      args.addAll(accountIds);
    }

    final rows = await _db.query(
      IptvStorageTables.playlistItems,
      distinct: true,
      columns: const ['tmdb_id'],
      where: where.toString(),
      whereArgs: args,
    );

    final ids = <int>{};
    for (final row in rows) {
      final raw = row['tmdb_id'];
      final id = switch (raw) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      };
      if (id != null && id > 0) ids.add(id);
    }
    return ids;
  }

  Future<List<XtreamPlaylistItem>> getAllPlaylistItems({
    required String ownerId,
    Set<String>? accountIds,
    XtreamPlaylistItemType? type,
  }) async {
    if (accountIds != null && accountIds.isEmpty) {
      return const <XtreamPlaylistItem>[];
    }

    final where = StringBuffer('i.owner_id = ?');
    final args = <Object?>[ownerId];
    if (accountIds != null && accountIds.isNotEmpty) {
      where.write(' AND i.account_id IN (');
      where.write(List.filled(accountIds.length, '?').join(','));
      where.write(')');
      args.addAll(accountIds);
    }
    if (type != null) {
      where.write(' AND i.type = ?');
      args.add(type.name);
    }

    final rows = await _db.rawQuery('''
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
      FROM ${IptvStorageTables.playlistItems} i
      JOIN ${IptvStorageTables.playlists} p
        ON p.owner_id = i.owner_id
       AND p.account_id = i.account_id
       AND p.playlist_id = i.playlist_id
      WHERE $where
      ORDER BY i.account_id, i.playlist_id, i.position
      ''', args);

    return rows
        .map(_mapJoinedPlaylistItemRow)
        .whereType<XtreamPlaylistItem>()
        .toList(growable: false);
  }

  Future<bool> hasAnyPlaylistItems({
    required String ownerId,
    Set<String>? accountIds,
  }) async {
    if (accountIds != null && accountIds.isNotEmpty) {
      final where =
          'owner_id = ? AND account_id IN (${List.filled(accountIds.length, '?').join(',')})';
      final rows = await _db.query(
        IptvStorageTables.playlistItems,
        columns: const ['account_id'],
        where: where,
        whereArgs: <Object?>[ownerId, ...accountIds],
        limit: 1,
      );
      return rows.isNotEmpty;
    }

    final rows = await _db.query(
      IptvStorageTables.playlistItems,
      columns: const ['account_id'],
      where: 'owner_id = ?',
      whereArgs: <Object?>[ownerId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<XtreamPlaylistItem>> searchItems(
    String query, {
    required String ownerId,
    int limit = 500,
    Set<String>? accountIds,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const <XtreamPlaylistItem>[];

    final safeLimit = limit <= 0 ? 0 : limit;
    if (safeLimit == 0) return const <XtreamPlaylistItem>[];
    if (accountIds != null && accountIds.isEmpty) {
      return const <XtreamPlaylistItem>[];
    }

    final like = '%$trimmedQuery%';
    final prefix = '$trimmedQuery%';
    final where = StringBuffer('''
        i.owner_id = ?
        AND
        i.title IS NOT NULL
        AND i.title <> ''
        AND i.title LIKE ? COLLATE NOCASE
      ''');
    final args = <Object?>[ownerId, like];
    if (accountIds != null && accountIds.isNotEmpty) {
      where.write(' AND i.account_id IN (');
      where.write(List.filled(accountIds.length, '?').join(','));
      where.write(')');
      args.addAll(accountIds);
    }

    final rows = await _db.rawQuery(
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
      FROM ${IptvStorageTables.playlistItems} i
      JOIN ${IptvStorageTables.playlists} p
        ON p.owner_id = i.owner_id
       AND p.account_id = i.account_id
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

    return rows
        .map(_mapJoinedPlaylistItemRow)
        .whereType<XtreamPlaylistItem>()
        .toList(growable: false);
  }

  XtreamPlaylistItem? _mapJoinedPlaylistItemRow(Map<String, Object?> row) {
    final accountId = row['account_id']?.toString() ?? '';
    final playlistId = row['playlist_id']?.toString() ?? '';
    final categoryName = row['category_name']?.toString() ?? '';
    final streamId = row['stream_id'] as int?;
    final title = row['item_title']?.toString() ?? '';
    if (accountId.isEmpty || playlistId.isEmpty || streamId == null) {
      return null;
    }
    if (title.trim().isEmpty) return null;

    final playlistType = _normalizePlaylistType(
      row['playlist_type']?.toString(),
    );
    final itemType = _normalizeItemType(
      (row['item_type']?.toString() ?? '').toLowerCase().trim(),
      playlistType,
    );

    return XtreamPlaylistItem(
      accountId: accountId,
      categoryId: playlistId,
      categoryName: categoryName.isEmpty ? playlistId : categoryName,
      streamId: streamId,
      title: title,
      type: itemType,
      overview: null,
      posterUrl: row['poster']?.toString(),
      containerExtension: row['container_extension']?.toString(),
      tmdbId: row['tmdb_id'] as int?,
      rating: (row['rating'] as num?)?.toDouble(),
      releaseYear: row['release_year'] as int?,
    );
  }
}
