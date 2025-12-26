import 'package:sqflite/sqflite.dart';

import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class WatchlistSyncApplier {
  const WatchlistSyncApplier(this._db);

  final Database _db;

  Future<void> upsert({
    required String userId,
    required String contentId,
    required ContentType type,
    required String title,
    Uri? poster,
    required DateTime addedAtUtc,
  }) async {
    await _db.insert(
      'watchlist',
      {
        'content_id': contentId,
        'content_type': type.name,
        'title': title,
        'poster': poster?.toString(),
        'added_at': addedAtUtc.toLocal().millisecondsSinceEpoch,
        'user_id': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove({
    required String userId,
    required String contentId,
    required ContentType type,
  }) async {
    await _db.delete(
      'watchlist',
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: [contentId, type.name, userId],
    );
  }
}

