import 'package:sqflite/sqflite.dart';

import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class HistorySyncApplier {
  const HistorySyncApplier(this._db);

  final Database _db;

  Future<void> upsertRemote({
    required String userId,
    required String contentId,
    required ContentType type,
    required String title,
    Uri? poster,
    required DateTime lastPlayedAtUtc,
    int? lastPositionSeconds,
    int? durationSeconds,
    int? season,
    int? episode,
  }) async {
    final lastPlayedAtMs = lastPlayedAtUtc.toLocal().millisecondsSinceEpoch;

    final updateCount = await _db.rawUpdate(
      '''
      UPDATE history
      SET title = COALESCE(?, title),
          poster = COALESCE(?, poster),
          last_played_at = ?,
          last_position = COALESCE(?, last_position),
          duration = COALESCE(?, duration),
          season = COALESCE(?, season),
          episode = COALESCE(?, episode)
      WHERE content_id = ? AND content_type = ? AND user_id = ?
      ''',
      [
        title,
        poster?.toString(),
        lastPlayedAtMs,
        lastPositionSeconds,
        durationSeconds,
        season,
        episode,
        contentId,
        type.name,
        userId,
      ],
    );

    if (updateCount == 0) {
      await _db.insert(
        'history',
        {
          'content_id': contentId,
          'content_type': type.name,
          'title': title,
          'poster': poster?.toString(),
          'last_played_at': lastPlayedAtMs,
          'play_count': 1,
          'last_position': lastPositionSeconds,
          'duration': durationSeconds,
          'season': season,
          'episode': episode,
          'user_id': userId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> remove({
    required String userId,
    required String contentId,
    required ContentType type,
  }) async {
    await _db.delete(
      'history',
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: [contentId, type.name, userId],
    );
  }
}

