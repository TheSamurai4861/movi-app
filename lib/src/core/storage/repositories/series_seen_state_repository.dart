import 'package:sqflite/sqflite.dart';

final class SeriesSeenState {
  const SeriesSeenState({
    required this.seriesId,
    required this.userId,
    required this.markedAt,
    this.seasonNumber,
    this.episodeNumber,
  });

  final String seriesId;
  final String userId;
  final DateTime markedAt;
  final int? seasonNumber;
  final int? episodeNumber;

  factory SeriesSeenState.fromMap(Map<String, Object?> map) {
    return SeriesSeenState(
      seriesId: map['series_id'] as String,
      userId: map['user_id'] as String? ?? 'default',
      markedAt: DateTime.fromMillisecondsSinceEpoch(map['marked_at'] as int),
      seasonNumber: map['season'] as int?,
      episodeNumber: map['episode'] as int?,
    );
  }
}

abstract class SeriesSeenStateRepository {
  Future<void> markSeen({
    required String seriesId,
    required String userId,
    int? seasonNumber,
    int? episodeNumber,
    DateTime? markedAt,
  });

  Future<void> clearSeen(String seriesId, {required String userId});

  Future<SeriesSeenState?> getSeenState(
    String seriesId, {
    required String userId,
  });
}

class SeriesSeenStateRepositoryImpl implements SeriesSeenStateRepository {
  SeriesSeenStateRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<void> markSeen({
    required String seriesId,
    required String userId,
    int? seasonNumber,
    int? episodeNumber,
    DateTime? markedAt,
  }) async {
    await _db.insert('series_seen_state', <String, Object?>{
      'series_id': seriesId,
      'user_id': userId,
      'marked_at': (markedAt ?? DateTime.now()).millisecondsSinceEpoch,
      'season': seasonNumber,
      'episode': episodeNumber,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> clearSeen(String seriesId, {required String userId}) async {
    await _db.delete(
      'series_seen_state',
      where: 'series_id = ? AND user_id = ?',
      whereArgs: <Object?>[seriesId, userId],
    );
  }

  @override
  Future<SeriesSeenState?> getSeenState(
    String seriesId, {
    required String userId,
  }) async {
    final rows = await _db.query(
      'series_seen_state',
      where: 'series_id = ? AND user_id = ?',
      whereArgs: <Object?>[seriesId, userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return SeriesSeenState.fromMap(rows.first);
  }
}
