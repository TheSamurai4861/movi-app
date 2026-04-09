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

  /// Returns the canonical resume state for a series.
  ///
  /// With the current SQLite schema, a series is stored in a single history row.
  /// This method makes that contract explicit.
  Future<HistoryEntry?> getSeriesResumeState(String seriesId, {String userId});

  /// Returns the history entry for a content.
  ///
  /// For series, `season` and `episode` are only an opportunistic filter against
  /// the canonical series row already stored locally. They do not address a
  /// dedicated per-episode history row.
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
    final now = (playedAt ?? DateTime.now()).millisecondsSinceEpoch;
    final updateCount = await _db.rawUpdate(
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
      <Object?>[
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
      await _db.insert('history', <String, Object?>{
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
  Future<void> remove(
    String contentId,
    ContentType type, {
    String userId = 'default',
  }) async {
    await _db.delete(
      'history',
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: <Object?>[contentId, type.name, userId],
    );
  }

  @override
  Future<List<HistoryEntry>> readAll(
    ContentType type, {
    String userId = 'default',
  }) async {
    final rows = await _db.query(
      'history',
      where: 'content_type = ? AND user_id = ?',
      whereArgs: <Object?>[type.name, userId],
      orderBy: 'last_played_at DESC',
    );
    return rows
        .map((row) => _mapRowToHistoryEntry(row, type: type))
        .toList(growable: false);
  }

  @override
  Future<HistoryEntry?> getSeriesResumeState(
    String seriesId, {
    String userId = 'default',
  }) {
    return _queryCanonicalEntry(
      contentId: seriesId,
      type: ContentType.series,
      userId: userId,
    );
  }

  @override
  Future<HistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String userId = 'default',
  }) async {
    final entry = await _queryCanonicalEntry(
      contentId: contentId,
      type: type,
      userId: userId,
    );
    if (entry == null) {
      return null;
    }

    if (type == ContentType.series &&
        season != null &&
        episode != null &&
        (entry.season != season || entry.episode != episode)) {
      return null;
    }

    return entry;
  }

  Future<HistoryEntry?> _queryCanonicalEntry({
    required String contentId,
    required ContentType type,
    required String userId,
  }) async {
    final rows = await _db.query(
      'history',
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: <Object?>[contentId, type.name, userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapRowToHistoryEntry(rows.first, type: type);
  }

  HistoryEntry _mapRowToHistoryEntry(
    Map<String, Object?> row, {
    required ContentType type,
  }) {
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
