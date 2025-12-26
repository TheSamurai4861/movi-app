import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/features/library/application/models/sync_cursor.dart';

class SupabaseFavoriteRow {
  const SupabaseFavoriteRow({
    required this.id,
    required this.mediaType,
    required this.mediaId,
    required this.updatedAt,
    this.title,
    this.poster,
    this.year,
    this.deletedAtUtc,
  });

  final String id;
  final String mediaType;
  final String mediaId;
  final String updatedAt;
  final String? title;
  final String? poster;
  final int? year;
  final DateTime? deletedAtUtc;

  DateTime get updatedAtUtc => DateTime.parse(updatedAt).toUtc();
}

/// Sync datasource for `public.favorites`.
///
/// Expected columns (minimum):
/// - id uuid
/// - profile_id uuid
/// - media_type text
/// - media_id text
/// - updated_at timestamptz (server-managed)
/// - deleted_at timestamptz (nullable, server-managed)
/// Optional columns for better UX:
/// - title text, poster text, year int
class SupabaseFavoritesSyncDataSource {
  SupabaseFavoritesSyncDataSource(this._client);

  final SupabaseClient _client;

  static const String _table = 'favorites';

  Future<List<SupabaseFavoriteRow>> listNextPage({
    required String profileId,
    required SyncCursor cursor,
    int limit = 200,
  }) async {
    final cursorId = cursor.id.trim();
    final updatedAtRaw = cursor.updatedAt;

    // 1) Same timestamp, id > cursor.id
    if (cursorId.isNotEmpty) {
      final rows = await _client
          .from(_table)
          .select(
            'id,media_type,media_id,title,poster,year,updated_at,deleted_at',
          )
          .eq('profile_id', profileId)
          .eq('updated_at', updatedAtRaw)
          .gt('id', cursorId)
          .order('id', ascending: true)
          .limit(limit);

      final parsed = _parseRows(rows);
      if (parsed.isNotEmpty) return parsed;
    }

    // 2) Next timestamps
    final rows = await _client
        .from(_table)
        .select('id,media_type,media_id,title,poster,year,updated_at,deleted_at')
        .eq('profile_id', profileId)
        .gt('updated_at', updatedAtRaw)
        .order('updated_at', ascending: true)
        .order('id', ascending: true)
        .limit(limit);

    return _parseRows(rows);
  }

  Future<void> upsert({
    required String profileId,
    required String mediaType,
    required String mediaId,
    required String title,
    String? poster,
    int? year,
  }) async {
    await _client.from(_table).upsert(
      <String, Object?>{
        'profile_id': profileId,
        'media_type': mediaType,
        'media_id': mediaId,
        'title': title,
        'poster': poster,
        'year': year,
        'deleted_at': null,
      },
      onConflict: 'profile_id,media_type,media_id',
    );
  }

  Future<void> softDelete({
    required String profileId,
    required String mediaType,
    required String mediaId,
    required DateTime deletedAtUtc,
  }) async {
    await _client.from(_table).update(<String, Object?>{
      'deleted_at': deletedAtUtc.toIso8601String(),
    }).match(<String, Object>{
      'profile_id': profileId,
      'media_type': mediaType,
      'media_id': mediaId,
    });
  }

  List<SupabaseFavoriteRow> _parseRows(dynamic rows) {
    if (rows is! List) return const [];

    final out = <SupabaseFavoriteRow>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;

      final id = row['id']?.toString();
      final mediaType = row['media_type']?.toString();
      final mediaId = row['media_id']?.toString();
      final updatedAtRaw = row['updated_at']?.toString();

      if (id == null ||
          id.isEmpty ||
          mediaType == null ||
          mediaType.isEmpty ||
          mediaId == null ||
          mediaId.isEmpty ||
          updatedAtRaw == null ||
          updatedAtRaw.isEmpty) {
        continue;
      }

      final deletedAtRaw = row['deleted_at']?.toString();
      final deletedAt = deletedAtRaw == null
          ? null
          : DateTime.tryParse(deletedAtRaw)?.toUtc();

      out.add(
        SupabaseFavoriteRow(
          id: id,
          mediaType: mediaType,
          mediaId: mediaId,
          title: row['title']?.toString(),
          poster: row['poster']?.toString(),
          year: (row['year'] as num?)?.toInt(),
          updatedAt: updatedAtRaw,
          deletedAtUtc: deletedAt,
        ),
      );
    }
    return out;
  }
}
