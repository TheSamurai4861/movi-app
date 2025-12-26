import 'package:sqflite/sqflite.dart';

import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/core/storage/repositories/sync_outbox_repository.dart';

class PlaylistHeader {
  const PlaylistHeader({
    required this.id,
    required this.title,
    this.description,
    this.cover,
    required this.owner,
    required this.isPublic,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final Uri? cover;
  final String owner;
  final bool isPublic;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PlaylistItemRow {
  const PlaylistItemRow({
    required this.position,
    required this.reference,
    this.runtime,
    this.notes,
    required this.addedAt,
  });

  final int position;
  final ContentReference reference;
  final Duration? runtime;
  final String? notes;
  final DateTime addedAt;
}

class PlaylistDetailRow {
  const PlaylistDetailRow({required this.header, required this.items});
  final PlaylistHeader header;
  final List<PlaylistItemRow> items;
}

class PlaylistLocalRepository {
  PlaylistLocalRepository({
    required Database db,
    SyncOutboxRepository? outbox,
  }) : _db = db,
       _outbox = outbox;

  final Database _db;
  final SyncOutboxRepository? _outbox;

  Future<void> createPlaylist(PlaylistHeader header) async {
    await upsertHeader(header);
  }

  Future<void> upsertHeader(PlaylistHeader header) async {
    final db = _db;
    await db.insert('playlists', {
      'playlist_id': header.id,
      'title': header.title,
      'description': header.description,
      'cover': header.cover?.toString(),
      'owner': header.owner,
      'is_public': header.isPublic ? 1 : 0,
      'is_pinned': header.isPinned ? 1 : 0,
      'created_at': header.createdAt.millisecondsSinceEpoch,
      'updated_at': header.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await _outbox?.enqueue(
      userId: header.owner,
      entity: 'playlist',
      entityKey: header.id,
      operation: 'changed',
      payload: {
        'playlist_id': header.id,
        'updated_at': header.updatedAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> renamePlaylist(String playlistId, String newTitle) async {
    final db = _db;
    final now = DateTime.now();
    await db.update(
      'playlists',
      {'title': newTitle, 'updated_at': now.millisecondsSinceEpoch},
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    await _enqueuePlaylistChanged(playlistId, updatedAt: now);
  }

  Future<void> setOwner(String playlistId, String owner) async {
    final db = _db;
    final now = DateTime.now();
    await db.update(
      'playlists',
      {'owner': owner, 'updated_at': now.millisecondsSinceEpoch},
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    await _enqueuePlaylistChanged(playlistId, updatedAt: now, ownerOverride: owner);
  }

  Future<void> setPinned(String playlistId, bool isPinned) async {
    final db = _db;
    final now = DateTime.now();
    await db.update(
      'playlists',
      {
        'is_pinned': isPinned ? 1 : 0,
        'updated_at': now.millisecondsSinceEpoch,
      },
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    await _enqueuePlaylistChanged(playlistId, updatedAt: now);
  }

  Future<void> deletePlaylist(String playlistId) async {
    final db = _db;
    final owner = await _getPlaylistOwnerOrNull(playlistId);
    final batch = db.batch();
    batch.delete(
      'playlist_items',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    batch.delete(
      'playlists',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    await batch.commit(noResult: true);

    if (owner != null) {
      await _outbox?.enqueue(
        userId: owner,
        entity: 'playlist',
        entityKey: playlistId,
        operation: 'delete',
        payload: {
          'playlist_id': playlistId,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }
  }

  Future<void> addItem(String playlistId, PlaylistItemRow item) async {
    final db = _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedAt = DateTime.now();
    
    // Utiliser une transaction pour garantir la cohérence
    await db.transaction((txn) async {
      // Calculer la position : utiliser MAX(position) + 1 si position non fournie
      int position = item.position;
      if (position == 0 || position < 0) {
        // Récupérer la position maximale actuelle
        final maxPositionResult = await txn.rawQuery(
          'SELECT MAX(position) as max_pos FROM playlist_items WHERE playlist_id = ?',
          [playlistId],
        );
        final maxPos = maxPositionResult.first['max_pos'] as int?;
        position = (maxPos ?? 0) + 1;
      }
      
      // Ajouter l'item
      final values = <String, Object?>{
        'playlist_id': playlistId,
        'position': position,
        'content_id': item.reference.id,
        'content_type': item.reference.type.name,
        'title': item.reference.title.value,
        'poster': item.reference.poster?.toString(),
        'year': item.reference.year,
        'runtime': item.runtime?.inSeconds,
        'notes': item.notes,
        'added_at': item.addedAt.millisecondsSinceEpoch,
      };

      try {
        await txn.insert(
          'playlist_items',
          values,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } on DatabaseException catch (e) {
        // Défensif: si la DB a été créée sans la colonne `year`, on retente sans.
        final msg = e.toString().toLowerCase();
        if (msg.contains('playlist_items') &&
            msg.contains('no column named year')) {
          values.remove('year');
          await txn.insert(
            'playlist_items',
            values,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          rethrow;
        }
      }
      
      // Mettre à jour le updated_at de la playlist
      await txn.update(
        'playlists',
        {'updated_at': now},
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
    });

    await _enqueuePlaylistChanged(playlistId, updatedAt: updatedAt);
  }

  Future<void> removeItem(String playlistId, int position) async {
    final db = _db;
    final updatedAt = DateTime.now();
    await db.delete(
      'playlist_items',
      where: 'playlist_id = ? AND position = ?',
      whereArgs: [playlistId, position],
    );
    await db.update(
      'playlists',
      {'updated_at': updatedAt.millisecondsSinceEpoch},
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    await _enqueuePlaylistChanged(playlistId, updatedAt: updatedAt);
  }

  Future<void> reorderItem(
    String playlistId, {
    required int fromPosition,
    required int toPosition,
  }) async {
    final db = _db;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'playlist_items',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
        orderBy: 'position ASC',
      );
      if (rows.isEmpty) return;
      final items = rows.toList();
      final fromIndex = items.indexWhere((r) => r['position'] == fromPosition);
      if (fromIndex == -1) return;
      var toIndex = items.indexWhere((r) => r['position'] == toPosition);
      if (toIndex == -1) {
        // if target not existing, clamp to end
        toIndex = items.length - 1;
      }
      final moved = items.removeAt(fromIndex);
      items.insert(toIndex, moved);
      // Avoid UNIQUE constraint collisions by shifting all positions temporarily
      await txn.rawUpdate(
        'UPDATE playlist_items SET position = position + 1000000 WHERE playlist_id = ?',
        [playlistId],
      );
      // Re-number positions starting at 1
      final batch = txn.batch();
      for (var i = 0; i < items.length; i++) {
        final pos = i + 1;
        batch.update(
          'playlist_items',
          {'position': pos},
          where: 'playlist_id = ? AND content_id = ? AND content_type = ?',
          whereArgs: [
            playlistId,
            items[i]['content_id'],
            items[i]['content_type'],
          ],
        );
      }
      await batch.commit(noResult: true);
    });

    await _enqueuePlaylistChanged(playlistId, updatedAt: DateTime.now());
  }

  Future<PlaylistDetailRow?> getPlaylist(String playlistId) async {
    final db = _db;
    final headers = await db.query(
      'playlists',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      limit: 1,
    );
    if (headers.isEmpty) return null;
    final h = headers.first;
    final header = PlaylistHeader(
      id: h['playlist_id'] as String,
      title: h['title'] as String,
      description: h['description'] as String?,
      cover: (h['cover'] as String?) != null
          ? Uri.tryParse(h['cover'] as String)
          : null,
      owner: h['owner'] as String,
      isPublic: (h['is_public'] as int) == 1,
      isPinned: (h['is_pinned'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(h['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(h['updated_at'] as int),
    );
    final rows = await db.query(
      'playlist_items',
      where: 'playlist_id = ? ',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );
    final items = rows
        .map(
          (r) => PlaylistItemRow(
            position: r['position'] as int,
            reference: ContentReference(
              id: r['content_id'] as String,
              title: MediaTitle(r['title'] as String),
              type: ContentType.values.firstWhere(
                (t) => t.name == (r['content_type'] as String),
              ),
              poster: (r['poster'] as String?) != null
                  ? Uri.tryParse(r['poster'] as String)
                  : null,
              year: r['year'] as int?,
            ),
            runtime: r['runtime'] != null
                ? Duration(seconds: r['runtime'] as int)
                : null,
            notes: r['notes'] as String?,
            addedAt: DateTime.fromMillisecondsSinceEpoch(r['added_at'] as int),
          ),
        )
        .toList();
    return PlaylistDetailRow(header: header, items: items);
  }

  Future<void> _enqueuePlaylistChanged(
    String playlistId, {
    required DateTime updatedAt,
    String? ownerOverride,
  }) async {
    final outbox = _outbox;
    if (outbox == null) return;

    final owner = ownerOverride ?? await _getPlaylistOwnerOrNull(playlistId);
    if (owner == null || owner.trim().isEmpty) return;

    await outbox.enqueue(
      userId: owner,
      entity: 'playlist',
      entityKey: playlistId,
      operation: 'changed',
      payload: {
        'playlist_id': playlistId,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<String?> _getPlaylistOwnerOrNull(String playlistId) async {
    try {
      final db = _db;
      final rows = await db.query(
        'playlists',
        columns: const ['owner'],
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final owner = rows.first['owner'] as String?;
      return owner?.trim().isEmpty == true ? null : owner;
    } catch (_) {
      return null;
    }
  }

  Future<List<PlaylistHeader>> getUserPlaylists(String owner) async {
    final db = _db;
    final rows = await db.query(
      'playlists',
      where: 'owner = ?',
      whereArgs: [owner],
      orderBy: 'updated_at DESC',
    );
    return rows
        .map(
          (h) => PlaylistHeader(
            id: h['playlist_id'] as String,
            title: h['title'] as String,
            description: h['description'] as String?,
            cover: (h['cover'] as String?) != null
                ? Uri.tryParse(h['cover'] as String)
                : null,
            owner: h['owner'] as String,
            isPublic: (h['is_public'] as int) == 1,
            isPinned: (h['is_pinned'] as int? ?? 0) == 1,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              h['created_at'] as int,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              h['updated_at'] as int,
            ),
          ),
        )
        .toList();
  }

  Future<List<PlaylistHeader>> searchByTitle(String query) async {
    final db = _db;
    final rows = await db.query(
      'playlists',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'updated_at DESC',
    );
    return rows
        .map(
          (h) => PlaylistHeader(
            id: h['playlist_id'] as String,
            title: h['title'] as String,
            description: h['description'] as String?,
            cover: (h['cover'] as String?) != null
                ? Uri.tryParse(h['cover'] as String)
                : null,
            owner: h['owner'] as String,
            isPublic: (h['is_public'] as int) == 1,
            isPinned: (h['is_pinned'] as int? ?? 0) == 1,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              h['created_at'] as int,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              h['updated_at'] as int,
            ),
          ),
        )
        .toList();
  }

  Future<List<PlaylistHeader>> getMostRecentlyUpdated(int limit) async {
    final db = _db;
    final rows = await db.query(
      'playlists',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows
        .map(
          (h) => PlaylistHeader(
            id: h['playlist_id'] as String,
            title: h['title'] as String,
            description: h['description'] as String?,
            cover: (h['cover'] as String?) != null
                ? Uri.tryParse(h['cover'] as String)
                : null,
            owner: h['owner'] as String,
            isPublic: (h['is_public'] as int) == 1,
            isPinned: (h['is_pinned'] as int? ?? 0) == 1,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              h['created_at'] as int,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              h['updated_at'] as int,
            ),
          ),
        )
        .toList();
  }

  Future<void> normalizePositions(String playlistId) async {
    final db = _db;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'playlist_items',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
        orderBy: 'position ASC',
      );
      if (rows.isEmpty) return;
      await txn.rawUpdate(
        'UPDATE playlist_items SET position = position + 1000000 WHERE playlist_id = ?',
        [playlistId],
      );
      final batch = txn.batch();
      for (var i = 0; i < rows.length; i++) {
        final pos = i + 1;
        batch.update(
          'playlist_items',
          {'position': pos},
          where: 'playlist_id = ? AND content_id = ? AND content_type = ?',
          whereArgs: [playlistId, rows[i]['content_id'], rows[i]['content_type']],
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
