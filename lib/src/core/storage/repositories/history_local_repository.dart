import 'package:sqflite/sqflite.dart';

import '../../storage/database/sqlite_database.dart';
import '../../../shared/domain/value_objects/content_reference.dart';

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
  });

  Future<void> remove(String contentId, ContentType type);
  Future<List<HistoryEntry>> readAll(ContentType type);
}

class HistoryLocalRepositoryImpl implements HistoryLocalRepository {
  const HistoryLocalRepositoryImpl();

  Future<Database> get _db => LocalDatabase.instance();

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
  }) async {
    final db = await _db;
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
      WHERE content_id = ? AND content_type = ?
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
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  @override
  Future<void> remove(String contentId, ContentType type) async {
    final db = await _db;
    await db.delete(
      'history',
      where: 'content_id = ? AND content_type = ?',
      whereArgs: [contentId, type.name],
    );
  }

  @override
  Future<List<HistoryEntry>> readAll(ContentType type) async {
    final db = await _db;
    final rows = await db.query(
      'history',
      where: 'content_type = ?',
      whereArgs: [type.name],
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
          ),
        )
        .toList();
  }
}
