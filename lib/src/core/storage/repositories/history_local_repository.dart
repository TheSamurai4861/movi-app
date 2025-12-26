import 'package:sqflite/sqflite.dart';

import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.contentId,
    required this.type,
    required this.title,
    this.poster,
    required this.lastPlayedAt,
    required this.playCount,
    this.lastPosition,
    this.duration,
    this.season,
    this.episode,
    this.userId = 'default',
  });

  final String contentId;
  final ContentType type;
  final String title;
  final Uri? poster;
  final DateTime lastPlayedAt;
  final int playCount;
  final Duration? lastPosition;
  final Duration? duration;
  final int? season;
  final int? episode;
  final String userId;
}

abstract class HistoryLocalRepository {
  Future<void> upsertPlay({
    required String contentId,
    required ContentType type,
    required String title,
    Uri? poster,
    DateTime? playedAt,
    Duration? position,
    Duration? duration,
    int? season,
    int? episode,
    String userId,
  });

  Future<void> remove(String contentId, ContentType type, {String userId});
  Future<List<HistoryEntry>> readAll(ContentType type, {String userId});
  Future<HistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String userId,
  });
}

class HistoryLocalRepositoryImpl implements HistoryLocalRepository {
  HistoryLocalRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<void> upsertPlay({
    required String contentId,
    required ContentType type,
    required String title,
    Uri? poster,
    DateTime? playedAt,
    Duration? position,
    Duration? duration,
    int? season,
    int? episode,
    String userId = 'default',
  }) async {
    final db = _db;
    // Try to update existing row (increment play_count)
    final now = (playedAt ?? DateTime.now()).millisecondsSinceEpoch;
    final updateCount = await db.rawUpdate(
      '''
      UPDATE history
      SET last_played_at = ?,
          play_count = play_count + 1,
          last_position = COALESCE(?, last_position),
          duration = COALESCE(?, duration),
          season = COALESCE(?, season),
          episode = COALESCE(?, episode),
          poster = COALESCE(?, poster),
          title = COALESCE(?, title)
      WHERE content_id = ? AND content_type = ? AND user_id = ?
      ''',
      [
        now,
        position?.inSeconds,
        duration?.inSeconds,
        season,
        episode,
        poster?.toString(),
        title,
        contentId,
        type.name,
        userId,
      ],
    );

    if (updateCount == 0) {
      await db.insert('history', {
        'content_id': contentId,
        'content_type': type.name,
        'title': title,
        'poster': poster?.toString(),
        'last_played_at': now,
        'play_count': 1,
        'last_position': position?.inSeconds,
        'duration': duration?.inSeconds,
        'season': season,
        'episode': episode,
        'user_id': userId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  @override
  Future<void> remove(String contentId, ContentType type, {String userId = 'default'}) async {
    final db = _db;
    await db.delete(
      'history',
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: [contentId, type.name, userId],
    );
  }

  @override
  Future<List<HistoryEntry>> readAll(ContentType type, {String userId = 'default'}) async {
    final db = _db;
    final rows = await db.query(
      'history',
      where: 'content_type = ? AND user_id = ?',
      whereArgs: [type.name, userId],
      orderBy: 'last_played_at DESC',
    );
    return rows
        .map(
          (row) => HistoryEntry(
            contentId: row['content_id'] as String,
            type: type,
            title: row['title'] as String,
            poster:
                row['poster'] != null && (row['poster'] as String).isNotEmpty
                ? Uri.tryParse(row['poster'] as String)
                : null,
            lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(
              row['last_played_at'] as int,
            ),
            playCount: (row['play_count'] as int?) ?? 1,
            lastPosition: row['last_position'] != null
                ? Duration(seconds: row['last_position'] as int)
                : null,
            duration: row['duration'] != null
                ? Duration(seconds: row['duration'] as int)
                : null,
            season: row['season'] as int?,
            episode: row['episode'] as int?,
            userId: (row['user_id'] as String?) ?? 'default',
          ),
        )
        .toList();
  }

  @override
  Future<HistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String userId = 'default',
  }) async {
    final db = _db;
    String where = 'content_id = ? AND content_type = ? AND user_id = ?';
    List<Object?> whereArgs = [contentId, type.name, userId];

    // Pour les séries, on peut filtrer par saison et épisode si fournis
    if (season != null && episode != null) {
      where += ' AND season = ? AND episode = ?';
      whereArgs.addAll([season, episode]);
    }

    final rows = await db.query(
      'history',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    return HistoryEntry(
      contentId: row['content_id'] as String,
      type: type,
      title: row['title'] as String,
      poster: row['poster'] != null && (row['poster'] as String).isNotEmpty
          ? Uri.tryParse(row['poster'] as String)
          : null,
      lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(
        row['last_played_at'] as int,
      ),
      playCount: (row['play_count'] as int?) ?? 1,
      lastPosition: row['last_position'] != null
          ? Duration(seconds: row['last_position'] as int)
          : null,
      duration: row['duration'] != null
          ? Duration(seconds: row['duration'] as int)
          : null,
      season: row['season'] as int?,
      episode: row['episode'] as int?,
      userId: (row['user_id'] as String?) ?? 'default',
    );
  }
}
