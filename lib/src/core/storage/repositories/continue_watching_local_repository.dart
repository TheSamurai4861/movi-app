import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/database/sqlite_database.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class ContinueWatchingEntry {
  const ContinueWatchingEntry({
    required this.contentId,
    required this.type,
    required this.title,
    this.poster,
    required this.position,
    this.duration,
    this.season,
    this.episode,
    required this.updatedAt,
  });

  final String contentId;
  final ContentType type;
  final String title;
  final Uri? poster;
  final Duration position;
  final Duration? duration;
  final int? season;
  final int? episode;
  final DateTime updatedAt;
}

abstract class ContinueWatchingLocalRepository {
  Future<void> upsert(ContinueWatchingEntry entry);
  Future<void> remove(String contentId, ContentType type);
  Future<List<ContinueWatchingEntry>> readAll(ContentType type);
}

class ContinueWatchingLocalRepositoryImpl
    implements ContinueWatchingLocalRepository {
  const ContinueWatchingLocalRepositoryImpl();

  Future<Database> get _db => LocalDatabase.instance();

  @override
  Future<void> upsert(ContinueWatchingEntry entry) async {
    final db = await _db;
    await db.insert('continue_watching', {
      'content_id': entry.contentId,
      'content_type': entry.type.name,
      'title': entry.title,
      'poster': entry.poster?.toString(),
      'position': entry.position.inSeconds,
      'duration': entry.duration?.inSeconds,
      'season': entry.season,
      'episode': entry.episode,
      'updated_at': entry.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> remove(String contentId, ContentType type) async {
    final db = await _db;
    await db.delete(
      'continue_watching',
      where: 'content_id = ? AND content_type = ?',
      whereArgs: [contentId, type.name],
    );
  }

  @override
  Future<List<ContinueWatchingEntry>> readAll(ContentType type) async {
    final db = await _db;
    final rows = await db.query(
      'continue_watching',
      where: 'content_type = ?',
      whereArgs: [type.name],
      orderBy: 'updated_at DESC',
    );
    return rows
        .map(
          (row) => ContinueWatchingEntry(
            contentId: row['content_id'] as String,
            type: type,
            title: row['title'] as String,
            poster:
                row['poster'] != null && (row['poster'] as String).isNotEmpty
                ? Uri.tryParse(row['poster'] as String)
                : null,
            position: Duration(seconds: (row['position'] as int)),
            duration: row['duration'] != null
                ? Duration(seconds: row['duration'] as int)
                : null,
            season: row['season'] as int?,
            episode: row['episode'] as int?,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              row['updated_at'] as int,
            ),
          ),
        )
        .toList();
  }
}
