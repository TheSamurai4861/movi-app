import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/database/sqlite_database.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class WatchlistEntry {
  const WatchlistEntry({
    required this.contentId,
    required this.type,
    required this.title,
    this.poster,
    required this.addedAt,
    this.userId = 'default',
  });

  final String contentId;
  final ContentType type;
  final String title;
  final Uri? poster;
  final DateTime addedAt;
  final String userId;
}

abstract class WatchlistLocalRepository {
  Future<bool> exists(String contentId, ContentType type, {String? userId});
  Future<void> upsert(WatchlistEntry entry);
  Future<void> remove(String contentId, ContentType type, {String? userId});
  Future<List<WatchlistEntry>> readAll(ContentType type, {String? userId});
}

class WatchlistLocalRepositoryImpl implements WatchlistLocalRepository {
  const WatchlistLocalRepositoryImpl();

  Future<Database> get _db => LocalDatabase.instance();

  @override
  Future<bool> exists(
    String contentId,
    ContentType type, {
    String? userId,
  }) async {
    final db = await _db;
    final userIdValue = userId ?? 'default';
    final rows = await db.query(
      'watchlist',
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: [contentId, type.name, userIdValue],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<WatchlistEntry>> readAll(
    ContentType type, {
    String? userId,
  }) async {
    final db = await _db;
    final userIdValue = userId ?? 'default';
    final rows = await db.query(
      'watchlist',
      where: 'content_type = ? AND user_id = ?',
      whereArgs: [type.name, userIdValue],
      orderBy: 'added_at DESC',
    );
    return rows
        .map(
          (row) => WatchlistEntry(
            contentId: row['content_id'] as String,
            type: type,
            title: row['title'] as String,
            poster:
                row['poster'] != null && (row['poster'] as String).isNotEmpty
                ? Uri.tryParse(row['poster'] as String)
                : null,
            addedAt: DateTime.fromMillisecondsSinceEpoch(
              row['added_at'] as int,
            ),
            userId: row['user_id'] as String? ?? 'default',
          ),
        )
        .toList();
  }

  @override
  Future<void> remove(
    String contentId,
    ContentType type, {
    String? userId,
  }) async {
    final db = await _db;
    final userIdValue = userId ?? 'default';
    await db.delete(
      'watchlist',
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: [contentId, type.name, userIdValue],
    );
  }

  @override
  Future<void> upsert(WatchlistEntry entry) async {
    final db = await _db;
    await db.insert('watchlist', {
      'content_id': entry.contentId,
      'content_type': entry.type.name,
      'title': entry.title,
      'poster': entry.poster?.toString(),
      'added_at': entry.addedAt.millisecondsSinceEpoch,
      'user_id': entry.userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
