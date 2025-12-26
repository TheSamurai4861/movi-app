// ignore_for_file: dead_code, unnecessary_type_check

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/features/library/application/models/sync_cursor.dart';

class SupabasePlaylistRow {
  const SupabasePlaylistRow({
    required this.id,
    required this.localId,
    required this.name,
    required this.updatedAt,
    required this.createdAtUtc,
    required this.isPinned,
    required this.isPublic,
    this.description,
    this.cover,
    this.deletedAtUtc,
  });

  final String id; // remote uuid
  final String localId; // local playlist_id
  final String name;
  final String updatedAt; // raw server updated_at
  final DateTime createdAtUtc;
  final bool isPinned;
  final bool isPublic;
  final String? description;
  final String? cover;
  final DateTime? deletedAtUtc;

  DateTime get updatedAtUtc => DateTime.parse(updatedAt).toUtc();
}

class SupabasePlaylistItemRow {
  const SupabasePlaylistItemRow({
    required this.contentId,
    required this.contentType,
    required this.title,
    required this.position,
    required this.addedAtUtc,
    this.poster,
    this.year,
    this.runtimeSeconds,
    this.notes,
  });

  final String contentId;
  final String contentType;
  final String title;
  final int position;
  final DateTime addedAtUtc;
  final String? poster;
  final int? year;
  final int? runtimeSeconds;
  final String? notes;
}

/// Sync datasource for `public.playlists` + `public.playlist_items`.
///
/// This uses a mapping `local_id` to keep local playlist identifiers stable
/// across devices while letting Supabase own the primary key (uuid).
///
/// Expected columns (playlists):
/// - id uuid
/// - profile_id uuid
/// - local_id text
/// - name text
/// - description text
/// - cover text
/// - is_pinned bool
/// - is_public bool
/// - created_at timestamptz
/// - updated_at timestamptz (server-managed)
/// - deleted_at timestamptz (nullable)
///
/// Expected columns (playlist_items):
/// - id uuid
/// - profile_id uuid
/// - playlist_id uuid
/// - content_id text
/// - content_type text
/// - title text
/// - poster text
/// - year int
/// - runtime_seconds int
/// - notes text
/// - position int
/// - added_at timestamptz
/// - updated_at timestamptz (server-managed)
/// - deleted_at timestamptz (nullable)
class SupabasePlaylistsSyncDataSource {
  SupabasePlaylistsSyncDataSource(this._client);

  final SupabaseClient _client;

  static const String _playlistsTable = 'playlists';
  static const String _itemsTable = 'playlist_items';

  Future<List<SupabasePlaylistRow>> listNextPage({
    required String profileId,
    required SyncCursor cursor,
    int limit = 200,
  }) async {
    final cursorId = cursor.id.trim();
    final updatedAtRaw = cursor.updatedAt;

    if (cursorId.isNotEmpty) {
      final rows = await _client
          .from(_playlistsTable)
          .select(
            'id,local_id,name,description,cover,is_pinned,is_public,created_at,updated_at,deleted_at',
          )
          .eq('profile_id', profileId)
          .eq('updated_at', updatedAtRaw)
          .gt('id', cursorId)
          .order('id', ascending: true)
          .limit(limit);

      final parsed = _parsePlaylistRows(rows);
      if (parsed.isNotEmpty) return parsed;
    }

    final rows = await _client
        .from(_playlistsTable)
        .select(
          'id,local_id,name,description,cover,is_pinned,is_public,created_at,updated_at,deleted_at',
        )
        .eq('profile_id', profileId)
        .gt('updated_at', updatedAtRaw)
        .order('updated_at', ascending: true)
        .order('id', ascending: true)
        .limit(limit);

    return _parsePlaylistRows(rows);
  }

  Future<String> upsertPlaylist({
    required String profileId,
    required String localId,
    required String name,
    String? description,
    String? cover,
    required bool isPinned,
    required bool isPublic,
  }) async {
    final row = await _client
        .from(_playlistsTable)
        .upsert(
          <String, Object?>{
            'profile_id': profileId,
            'local_id': localId,
            'name': name,
            'description': description,
            'cover': cover,
            'is_pinned': isPinned,
            'is_public': isPublic,
            'deleted_at': null,
          },
          onConflict: 'profile_id,local_id',
        )
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<void> softDeletePlaylist({
    required String profileId,
    required String localId,
    required DateTime deletedAtUtc,
  }) async {
    await _client.from(_playlistsTable).update(<String, Object?>{
      'deleted_at': deletedAtUtc.toIso8601String(),
    }).match(<String, Object>{
      'profile_id': profileId,
      'local_id': localId,
    });
  }

  Future<void> replacePlaylistItems({
    required String profileId,
    required String playlistId,
    required List<SupabasePlaylistItemRow> items,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    // Tombstone existing items, then upsert current ones (deleted_at = null).
    await _client.from(_itemsTable).update(<String, Object?>{
      'deleted_at': now,
    }).match(<String, Object>{
      'playlist_id': playlistId,
    });

    for (final item in items) {
      await _client.from(_itemsTable).upsert(
        <String, Object?>{
          'profile_id': profileId,
          'playlist_id': playlistId,
          'content_id': item.contentId,
          'content_type': item.contentType,
          'title': item.title,
          'poster': item.poster,
          'year': item.year,
          'runtime_seconds': item.runtimeSeconds,
          'notes': item.notes,
          'position': item.position,
          'added_at': item.addedAtUtc.toIso8601String(),
          'deleted_at': null,
        },
        onConflict: 'playlist_id,content_type,content_id',
      );
    }
  }

  Future<List<SupabasePlaylistItemRow>> listPlaylistItems({
    required String playlistId,
  }) async {
    final rows = await _client
        .from(_itemsTable)
        .select(
          'content_id,content_type,title,poster,year,runtime_seconds,notes,position,added_at,deleted_at',
        )
        .eq('playlist_id', playlistId)
        .isFilter('deleted_at', null)
        .order('position', ascending: true);

    if (rows is! List) return const [];
    final out = <SupabasePlaylistItemRow>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;

      final contentId = row['content_id']?.toString();
      final contentType = row['content_type']?.toString();
      final title = row['title']?.toString();
      final position = (row['position'] as num?)?.toInt();
      final addedAtRaw = row['added_at']?.toString();
      final addedAt = addedAtRaw == null
          ? null
          : DateTime.tryParse(addedAtRaw)?.toUtc();

      if (contentId == null ||
          contentId.isEmpty ||
          contentType == null ||
          contentType.isEmpty ||
          title == null ||
          title.isEmpty ||
          position == null ||
          addedAt == null) {
        continue;
      }

      out.add(
        SupabasePlaylistItemRow(
          contentId: contentId,
          contentType: contentType,
          title: title,
          position: position,
          addedAtUtc: addedAt,
          poster: row['poster']?.toString(),
          year: (row['year'] as num?)?.toInt(),
          runtimeSeconds: (row['runtime_seconds'] as num?)?.toInt(),
          notes: row['notes']?.toString(),
        ),
      );
    }
    return out;
  }

  List<SupabasePlaylistRow> _parsePlaylistRows(dynamic rows) {
    if (rows is! List) return const [];

    final out = <SupabasePlaylistRow>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;

      final id = row['id']?.toString();
      final localId = row['local_id']?.toString();
      final name = row['name']?.toString();
      final updatedAtRaw = row['updated_at']?.toString();
      final createdAtRaw = row['created_at']?.toString();
      final createdAt = createdAtRaw == null
          ? null
          : DateTime.tryParse(createdAtRaw)?.toUtc();

      if (id == null ||
          id.isEmpty ||
          localId == null ||
          localId.isEmpty ||
          name == null ||
          name.isEmpty ||
          updatedAtRaw == null ||
          updatedAtRaw.isEmpty ||
          createdAt == null) {
        continue;
      }

      final deletedAtRaw = row['deleted_at']?.toString();
      final deletedAt = deletedAtRaw == null
          ? null
          : DateTime.tryParse(deletedAtRaw)?.toUtc();

      out.add(
        SupabasePlaylistRow(
          id: id,
          localId: localId,
          name: name,
          description: row['description']?.toString(),
          cover: row['cover']?.toString(),
          isPinned: row['is_pinned'] == true || row['is_pinned'] == 1,
          isPublic: row['is_public'] == true || row['is_public'] == 1,
          createdAtUtc: createdAt,
          updatedAt: updatedAtRaw,
          deletedAtUtc: deletedAt,
        ),
      );
    }
    return out;
  }
}
