import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/storage.dart';

class PlaylistsSyncApplier {
  const PlaylistsSyncApplier(this._db);

  final Database _db;

  Future<void> upsertHeader({
    required String userId,
    required String playlistId,
    required String title,
    String? description,
    Uri? cover,
    required bool isPublic,
    required bool isPinned,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) async {
    await _db.insert(
      'playlists',
      {
        'playlist_id': playlistId,
        'title': title,
        'description': description,
        'cover': cover?.toString(),
        'owner': userId,
        'is_public': isPublic ? 1 : 0,
        'is_pinned': isPinned ? 1 : 0,
        'created_at': createdAtUtc.toLocal().millisecondsSinceEpoch,
        'updated_at': updatedAtUtc.toLocal().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceItems({
    required String playlistId,
    required List<PlaylistItemRow> items,
    required DateTime updatedAtUtc,
  }) async {
    final updatedAtMs = updatedAtUtc.toLocal().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      await txn.delete(
        'playlist_items',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );

      final batch = txn.batch();
      final normalized = List<PlaylistItemRow>.from(items)
        ..sort((a, b) => a.position.compareTo(b.position));

      for (var i = 0; i < normalized.length; i++) {
        final item = normalized[i];
        final pos = item.position <= 0 ? i + 1 : item.position;
        batch.insert(
          'playlist_items',
          {
            'playlist_id': playlistId,
            'position': pos,
            'content_id': item.reference.id,
            'content_type': item.reference.type.name,
            'title': item.reference.title.value,
            'poster': item.reference.poster?.toString(),
            'year': item.reference.year,
            'runtime': item.runtime?.inSeconds,
            'notes': item.notes,
            'added_at': item.addedAt.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      batch.update(
        'playlists',
        {'updated_at': updatedAtMs},
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );

      await batch.commit(noResult: true);
    });
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _db.transaction((txn) async {
      await txn.delete(
        'playlist_items',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      await txn.delete(
        'playlists',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
    });
  }
}

