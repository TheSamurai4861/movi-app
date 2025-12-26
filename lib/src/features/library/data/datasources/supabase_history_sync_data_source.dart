import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/features/library/application/models/sync_cursor.dart';

class SupabaseHistoryRow {
  const SupabaseHistoryRow({
    required this.id,
    required this.mediaType,
    required this.mediaId,
    required this.updatedAt,
    required this.watchedAtUtc,
    this.progress,
    this.title,
    this.poster,
    this.lastPositionSeconds,
    this.durationSeconds,
    this.season,
    this.episode,
    this.deletedAtUtc,
  });

  final String id;
  final String mediaType;
  final String mediaId;
  final String updatedAt;
  final DateTime watchedAtUtc;

  final double? progress;
  final String? title;
  final String? poster;
  final int? lastPositionSeconds;
  final int? durationSeconds;
  final int? season;
  final int? episode;
  final DateTime? deletedAtUtc;

  DateTime get updatedAtUtc => DateTime.parse(updatedAt).toUtc();
}

/// Sync datasource for `public.history` used by Continue Watching / playback history.
///
/// Expected columns (minimum):
/// - id uuid
/// - profile_id uuid
/// - media_type text
/// - media_id text
/// - watched_at timestamptz
/// - progress double precision
/// - updated_at timestamptz (server-managed)
/// Optional:
/// - last_position_seconds int
/// - duration_seconds int
/// - title text, poster text
/// - season int, episode int
/// - deleted_at timestamptz
class SupabaseHistorySyncDataSource {
  SupabaseHistorySyncDataSource(this._client);

  final SupabaseClient _client;

  static const String _table = 'history';

  Future<List<SupabaseHistoryRow>> listNextPage({
    required String profileId,
    required SyncCursor cursor,
    int limit = 200,
  }) async {
    final cursorId = cursor.id.trim();
    final updatedAtRaw = cursor.updatedAt;

    if (cursorId.isNotEmpty) {
      final rows = await _client
          .from(_table)
          .select(
            'id,media_type,media_id,watched_at,progress,title,poster,'
            'last_position_seconds,duration_seconds,season,episode,updated_at,deleted_at',
          )
          .eq('profile_id', profileId)
          .eq('updated_at', updatedAtRaw)
          .gt('id', cursorId)
          .order('id', ascending: true)
          .limit(limit);

      final parsed = _parseRows(rows);
      if (parsed.isNotEmpty) return parsed;
    }

    final rows = await _client
        .from(_table)
        .select(
          'id,media_type,media_id,watched_at,progress,title,poster,'
          'last_position_seconds,duration_seconds,season,episode,updated_at,deleted_at',
        )
        .eq('profile_id', profileId)
        .gt('updated_at', updatedAtRaw)
        .order('updated_at', ascending: true)
        .order('id', ascending: true)
        .limit(limit);

    return _parseRows(rows);
  }

  List<SupabaseHistoryRow> _parseRows(dynamic rows) {
    if (rows is! List) return const [];

    final out = <SupabaseHistoryRow>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;

      final id = row['id']?.toString();
      final mediaType = row['media_type']?.toString();
      final mediaId = row['media_id']?.toString();
      final updatedAtRaw = row['updated_at']?.toString();
      final watchedAtRaw = row['watched_at']?.toString();

      final watchedAt = watchedAtRaw == null
          ? null
          : DateTime.tryParse(watchedAtRaw)?.toUtc();

      if (id == null ||
          id.isEmpty ||
          mediaType == null ||
          mediaType.isEmpty ||
          mediaId == null ||
          mediaId.isEmpty ||
          updatedAtRaw == null ||
          updatedAtRaw.isEmpty ||
          watchedAt == null) {
        continue;
      }

      final deletedAtRaw = row['deleted_at']?.toString();
      final deletedAt = deletedAtRaw == null
          ? null
          : DateTime.tryParse(deletedAtRaw)?.toUtc();

      out.add(
        SupabaseHistoryRow(
          id: id,
          mediaType: mediaType,
          mediaId: mediaId,
          updatedAt: updatedAtRaw,
          watchedAtUtc: watchedAt,
          progress: (row['progress'] as num?)?.toDouble(),
          title: row['title']?.toString(),
          poster: row['poster']?.toString(),
          lastPositionSeconds: (row['last_position_seconds'] as num?)?.toInt(),
          durationSeconds: (row['duration_seconds'] as num?)?.toInt(),
          season: (row['season'] as num?)?.toInt(),
          episode: (row['episode'] as num?)?.toInt(),
          deletedAtUtc: deletedAt,
        ),
      );
    }
    return out;
  }
}

