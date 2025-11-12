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
  });

  final String contentId;
  final ContentType type;
  final String title;
  final Uri? poster;
  final DateTime addedAt;
}

abstract class WatchlistLocalRepository {
  Future<bool> exists(String contentId, ContentType type);
  Future<void> upsert(WatchlistEntry entry);
  Future<void> remove(String contentId, ContentType type);
  Future<List<WatchlistEntry>> readAll(ContentType type);
}

class WatchlistLocalRepositoryImpl implements WatchlistLocalRepository {
  const WatchlistLocalRepositoryImpl();

  Future<Database> get _db => LocalDatabase.instance();

  @override
  Future<bool> exists(String contentId, ContentType type) async {
    final db = await _db;
    final rows = await db.query(
      'watchlist',
      where: 'content_id = ? AND content_type = ?',
      whereArgs: [contentId, type.name],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<WatchlistEntry>> readAll(ContentType type) async {
    final db = await _db;
    final rows = await db.query(
      'watchlist',
      where: 'content_type = ?',
      whereArgs: [type.name],
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
          ),
        )
        .toList();
  }

  @override
  Future<void> remove(String contentId, ContentType type) async {
    final db = await _db;
    await db.delete(
      'watchlist',
      where: 'content_id = ? AND content_type = ?',
      whereArgs: [contentId, type.name],
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
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
