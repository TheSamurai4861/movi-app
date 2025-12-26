import 'package:sqflite/sqflite.dart';

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
    this.userId = 'default',
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
  final String userId;
}

abstract class ContinueWatchingLocalRepository {
  Future<void> upsert(ContinueWatchingEntry entry);
  Future<void> remove(String contentId, ContentType type, {String userId});
  Future<List<ContinueWatchingEntry>> readAll(ContentType type, {String userId});
}

class ContinueWatchingLocalRepositoryImpl
    implements ContinueWatchingLocalRepository {
  ContinueWatchingLocalRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<void> upsert(ContinueWatchingEntry entry) async {
    final db = _db;
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
      'user_id': entry.userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> remove(String contentId, ContentType type, {String userId = 'default'}) async {
    final db = _db;
    await db.delete(
      'continue_watching',
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: [contentId, type.name, userId],
    );
  }

  @override
  Future<List<ContinueWatchingEntry>> readAll(ContentType type, {String userId = 'default'}) async {
    final db = _db;
    final rows = await db.query(
      'continue_watching',
      where: 'content_type = ? AND user_id = ?',
      whereArgs: [type.name, userId],
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
            userId: (row['user_id'] as String?) ?? 'default',
          ),
        )
        .toList();
  }
}
