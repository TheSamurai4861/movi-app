import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/database/sqlite_database.dart';

final class TrackedSeriesRecord {
  const TrackedSeriesRecord({
    required this.seriesId,
    required this.userId,
    required this.title,
    this.poster,
    this.lastKnownSeason,
    this.lastKnownEpisode,
    this.lastKnownAirDate,
    this.lastCheckedAt,
    required this.hasNewEpisode,
    this.lastNotifiedSeason,
    this.lastNotifiedEpisode,
    this.lastNotifiedAt,
  });

  final String seriesId;
  final String userId;
  final String title;
  final Uri? poster;
  final int? lastKnownSeason;
  final int? lastKnownEpisode;
  final DateTime? lastKnownAirDate;
  final DateTime? lastCheckedAt;
  final bool hasNewEpisode;
  final int? lastNotifiedSeason;
  final int? lastNotifiedEpisode;
  final DateTime? lastNotifiedAt;

  factory TrackedSeriesRecord.fromMap(Map<String, Object?> map) {
    return TrackedSeriesRecord(
      seriesId: map['series_id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String? ?? '',
      poster: _parseTrackedSeriesUri(map['poster'] as String?),
      lastKnownSeason: map['last_known_season'] as int?,
      lastKnownEpisode: map['last_known_episode'] as int?,
      lastKnownAirDate: _parseTrackedSeriesDate(
        map['last_known_air_date'] as int?,
      ),
      lastCheckedAt: _parseTrackedSeriesDate(map['last_checked_at'] as int?),
      hasNewEpisode: (map['has_new_episode'] as int? ?? 0) == 1,
      lastNotifiedSeason: map['last_notified_season'] as int?,
      lastNotifiedEpisode: map['last_notified_episode'] as int?,
      lastNotifiedAt: _parseTrackedSeriesDate(map['last_notified_at'] as int?),
    );
  }
}

final class LatestEpisodeSnapshot {
  const LatestEpisodeSnapshot({
    required this.seasonNumber,
    required this.episodeNumber,
    this.airDate,
  });

  final int seasonNumber;
  final int episodeNumber;
  final DateTime? airDate;
}

final class SeriesTrackingRefreshOutcome {
  const SeriesTrackingRefreshOutcome({
    required this.record,
    required this.latestEpisode,
    required this.hasNewEpisode,
    required this.shouldNotify,
  });

  final TrackedSeriesRecord record;
  final LatestEpisodeSnapshot latestEpisode;
  final bool hasNewEpisode;
  final bool shouldNotify;
}

class SeriesTrackingLocalRepository {
  Future<Database> get _db async => LocalDatabase.instance();

  Future<TrackedSeriesRecord?> getTrackedSeries(
    String seriesId, {
    required String userId,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'tracked_series',
      where: 'series_id = ? AND user_id = ?',
      whereArgs: [seriesId, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TrackedSeriesRecord.fromMap(rows.first);
  }

  Future<List<TrackedSeriesRecord>> readAllTrackedSeries({
    required String userId,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'tracked_series',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return rows.map(TrackedSeriesRecord.fromMap).toList(growable: false);
  }

  Future<bool> isTracked(String seriesId, {required String userId}) async {
    final db = await _db;
    final rows = await db.query(
      'tracked_series',
      columns: const ['series_id'],
      where: 'series_id = ? AND user_id = ?',
      whereArgs: [seriesId, userId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> trackSeries({
    required String seriesId,
    required String userId,
    required String title,
    Uri? poster,
    LatestEpisodeSnapshot? latestEpisode,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('tracked_series', {
      'series_id': seriesId,
      'user_id': userId,
      'title': title,
      'poster': poster?.toString(),
      'last_known_season': latestEpisode?.seasonNumber,
      'last_known_episode': latestEpisode?.episodeNumber,
      'last_known_air_date': latestEpisode?.airDate?.millisecondsSinceEpoch,
      'last_checked_at': now,
      'has_new_episode': 0,
      'last_notified_season': null,
      'last_notified_episode': null,
      'last_notified_at': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> untrackSeries(String seriesId, {required String userId}) async {
    final db = await _db;
    await db.delete(
      'tracked_series',
      where: 'series_id = ? AND user_id = ?',
      whereArgs: [seriesId, userId],
    );
  }

  Future<SeriesTrackingRefreshOutcome?> updateLatestEpisodeSnapshot({
    required String seriesId,
    required String userId,
    required LatestEpisodeSnapshot latestEpisode,
  }) async {
    final db = await _db;
    final current = await getTrackedSeries(seriesId, userId: userId);
    if (current == null) return null;

    final hasNewEpisode = _isEpisodeAfter(
      seasonNumber: latestEpisode.seasonNumber,
      episodeNumber: latestEpisode.episodeNumber,
      previousSeasonNumber: current.lastKnownSeason,
      previousEpisodeNumber: current.lastKnownEpisode,
    );

    final alreadyNotifiedForLatest =
        current.lastNotifiedSeason == latestEpisode.seasonNumber &&
        current.lastNotifiedEpisode == latestEpisode.episodeNumber;
    final shouldNotify = hasNewEpisode && !alreadyNotifiedForLatest;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'tracked_series',
      {
        'last_known_season': latestEpisode.seasonNumber,
        'last_known_episode': latestEpisode.episodeNumber,
        'last_known_air_date': latestEpisode.airDate?.millisecondsSinceEpoch,
        'last_checked_at': now,
        'has_new_episode': hasNewEpisode
            ? 1
            : current.hasNewEpisode
            ? 1
            : 0,
        'last_notified_season': shouldNotify
            ? latestEpisode.seasonNumber
            : current.lastNotifiedSeason,
        'last_notified_episode': shouldNotify
            ? latestEpisode.episodeNumber
            : current.lastNotifiedEpisode,
        'last_notified_at': shouldNotify
            ? now
            : current.lastNotifiedAt?.millisecondsSinceEpoch,
      },
      where: 'series_id = ? AND user_id = ?',
      whereArgs: [seriesId, userId],
    );

    final updated = await getTrackedSeries(seriesId, userId: userId);
    if (updated == null) return null;

    return SeriesTrackingRefreshOutcome(
      record: updated,
      latestEpisode: latestEpisode,
      hasNewEpisode: hasNewEpisode,
      shouldNotify: shouldNotify,
    );
  }

  Future<void> markNewEpisodeSeen(
    String seriesId, {
    required String userId,
  }) async {
    final db = await _db;
    await db.update(
      'tracked_series',
      {
        'has_new_episode': 0,
        'last_checked_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'series_id = ? AND user_id = ?',
      whereArgs: [seriesId, userId],
    );
  }

  static bool _isEpisodeAfter({
    required int seasonNumber,
    required int episodeNumber,
    required int? previousSeasonNumber,
    required int? previousEpisodeNumber,
  }) {
    if (previousSeasonNumber == null || previousEpisodeNumber == null) {
      return false;
    }
    if (seasonNumber > previousSeasonNumber) return true;
    if (seasonNumber < previousSeasonNumber) return false;
    return episodeNumber > previousEpisodeNumber;
  }
}

DateTime? _parseTrackedSeriesDate(int? value) {
  if (value == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(value);
}

Uri? _parseTrackedSeriesUri(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return Uri.tryParse(raw);
}
