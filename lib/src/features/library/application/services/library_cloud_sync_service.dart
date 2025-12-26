import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/library/application/models/sync_cursor.dart';
import 'package:movi/src/features/library/application/services/cloud_sync_cursor_store.dart';
import 'package:movi/src/features/library/application/services/history_sync_applier.dart';
import 'package:movi/src/features/library/application/services/playlists_sync_applier.dart';
import 'package:movi/src/features/library/application/services/watchlist_sync_applier.dart';
import 'package:movi/src/features/library/data/datasources/supabase_favorites_sync_data_source.dart';
import 'package:movi/src/features/library/data/datasources/supabase_history_sync_data_source.dart';
import 'package:movi/src/features/library/data/datasources/supabase_playlists_sync_data_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class LibraryCloudSyncService {
  LibraryCloudSyncService({
    required SecureStorageRepository secureStorage,
    required SyncOutboxRepository outbox,
    required Database db,
    required PlaylistLocalRepository playlistLocal,
  }) : _cursorStore = CloudSyncCursorStore(secureStorage),
       _outbox = outbox,
       _watchlistApplier = WatchlistSyncApplier(db),
       _historyApplier = HistorySyncApplier(db),
       _playlistsApplier = PlaylistsSyncApplier(db),
       _playlistLocal = playlistLocal;

  static const String tableFavorites = 'favorites';
  static const String tableHistory = 'history';
  static const String tablePlaylists = 'playlists';

  final CloudSyncCursorStore _cursorStore;
  final SyncOutboxRepository _outbox;
  final WatchlistSyncApplier _watchlistApplier;
  final HistorySyncApplier _historyApplier;
  final PlaylistsSyncApplier _playlistsApplier;
  final PlaylistLocalRepository _playlistLocal;

  Future<void> syncAll({
    required SupabaseClient client,
    required String profileId,
    bool Function()? shouldCancel,
  }) async {
    await _pushOutbox(client: client, profileId: profileId, shouldCancel: shouldCancel);
    await _pullFavorites(client: client, profileId: profileId, shouldCancel: shouldCancel);
    await _pullHistory(client: client, profileId: profileId, shouldCancel: shouldCancel);
    await _pullPlaylists(client: client, profileId: profileId, shouldCancel: shouldCancel);
  }

  // ---------------------------------------------------------------------------
  // PUSH (local -> remote)
  // ---------------------------------------------------------------------------

  Future<void> _pushOutbox({
    required SupabaseClient client,
    required String profileId,
    bool Function()? shouldCancel,
  }) async {
    final favorites = SupabaseFavoritesSyncDataSource(client);
    final playlists = SupabasePlaylistsSyncDataSource(client);

    while (true) {
      if (shouldCancel?.call() == true) return;

      final pending = await _outbox.listPending(userId: profileId, limit: 200);
      if (pending.isEmpty) return;

      for (final item in pending) {
        if (shouldCancel?.call() == true) return;

        try {
          if (item.entity == 'watchlist') {
            await _pushWatchlistItem(favorites, profileId, item);
            await _outbox.delete(item.id);
            continue;
          }
          if (item.entity == 'playlist') {
            await _pushPlaylistItem(playlists, profileId, item);
            await _outbox.delete(item.id);
            continue;
          }

          // Unknown entity -> drop defensively to avoid blocking the queue.
          await _outbox.delete(item.id);
        } catch (e, st) {
          assert(() {
            debugPrint('[LibraryCloudSyncService] push failed: $e\n$st');
            return true;
          }());
          // Stop on first error to keep ordering; retry later.
          return;
        }
      }
    }
  }

  Future<void> _pushWatchlistItem(
    SupabaseFavoritesSyncDataSource favorites,
    String profileId,
    SyncOutboxItem item,
  ) async {
    final payload = item.payload ?? const <String, dynamic>{};
    final type = payload['content_type']?.toString();
    final id = payload['content_id']?.toString();

    if (type == null || type.isEmpty || id == null || id.isEmpty) {
      throw StateError('Invalid watchlist outbox payload.');
    }

    if (item.operation == 'delete') {
      final deletedAtRaw = payload['deleted_at']?.toString();
      final deletedAt = deletedAtRaw == null
          ? DateTime.now().toUtc()
          : DateTime.tryParse(deletedAtRaw)?.toUtc() ?? DateTime.now().toUtc();

      await favorites.softDelete(
        profileId: profileId,
        mediaType: type,
        mediaId: id,
        deletedAtUtc: deletedAt,
      );
      return;
    }

    if (item.operation == 'upsert') {
      final title = payload['title']?.toString() ?? id;
      final poster = payload['poster']?.toString();
      final year = (payload['year'] as num?)?.toInt();

      await favorites.upsert(
        profileId: profileId,
        mediaType: type,
        mediaId: id,
        title: title,
        poster: poster,
        year: year,
      );
      return;
    }

    throw StateError('Unknown watchlist operation: ${item.operation}');
  }

  Future<void> _pushPlaylistItem(
    SupabasePlaylistsSyncDataSource playlists,
    String profileId,
    SyncOutboxItem item,
  ) async {
    final payload = item.payload ?? const <String, dynamic>{};
    final localId = payload['playlist_id']?.toString() ?? item.entityKey;
    if (localId.trim().isEmpty) {
      throw StateError('Invalid playlist outbox payload.');
    }

    if (item.operation == 'delete') {
      final deletedAtRaw = payload['deleted_at']?.toString();
      final deletedAt = deletedAtRaw == null
          ? DateTime.now().toUtc()
          : DateTime.tryParse(deletedAtRaw)?.toUtc() ?? DateTime.now().toUtc();

      await playlists.softDeletePlaylist(
        profileId: profileId,
        localId: localId,
        deletedAtUtc: deletedAt,
      );
      return;
    }

    if (item.operation != 'changed') {
      throw StateError('Unknown playlist operation: ${item.operation}');
    }

    final detail = await _playlistLocal.getPlaylist(localId);
    if (detail == null) {
      // Playlist no longer exists locally; nothing to push.
      return;
    }

    final remoteId = await playlists.upsertPlaylist(
      profileId: profileId,
      localId: localId,
      name: detail.header.title,
      description: detail.header.description,
      cover: detail.header.cover?.toString(),
      isPinned: detail.header.isPinned,
      isPublic: detail.header.isPublic,
    );

    final items = <SupabasePlaylistItemRow>[];
    for (final item in detail.items) {
      items.add(
        SupabasePlaylistItemRow(
          contentId: item.reference.id,
          contentType: item.reference.type.name,
          title: item.reference.title.value,
          position: item.position <= 0 ? 0 : item.position,
          addedAtUtc: item.addedAt.toUtc(),
          poster: item.reference.poster?.toString(),
          year: item.reference.year,
          runtimeSeconds: item.runtime?.inSeconds,
          notes: item.notes,
        ),
      );
    }

    // Normalize positions client-side (1..N) for deterministic ordering.
    for (var i = 0; i < items.length; i++) {
      items[i] = SupabasePlaylistItemRow(
        contentId: items[i].contentId,
        contentType: items[i].contentType,
        title: items[i].title,
        position: i + 1,
        addedAtUtc: items[i].addedAtUtc,
        poster: items[i].poster,
        year: items[i].year,
        runtimeSeconds: items[i].runtimeSeconds,
        notes: items[i].notes,
      );
    }

    await playlists.replacePlaylistItems(
      profileId: profileId,
      playlistId: remoteId,
      items: items,
    );
  }

  // ---------------------------------------------------------------------------
  // PULL (remote -> local)
  // ---------------------------------------------------------------------------

  Future<void> _pullFavorites({
    required SupabaseClient client,
    required String profileId,
    bool Function()? shouldCancel,
  }) async {
    final ds = SupabaseFavoritesSyncDataSource(client);
    var cursor = await _cursorStore.read(table: tableFavorites, profileId: profileId);

    while (true) {
      if (shouldCancel?.call() == true) return;

      final page = await ds.listNextPage(
        profileId: profileId,
        cursor: cursor,
        limit: 200,
      );
      if (page.isEmpty) return;

      for (final row in page) {
        if (shouldCancel?.call() == true) return;

        final type = _parseContentType(row.mediaType);
        if (type == null) continue;

        if (row.deletedAtUtc != null) {
          await _watchlistApplier.remove(
            userId: profileId,
            contentId: row.mediaId,
            type: type,
          );
        } else {
          final title = row.title?.trim().isNotEmpty == true
              ? row.title!.trim()
              : row.mediaId;
          final poster = row.poster == null ? null : Uri.tryParse(row.poster!);

          await _watchlistApplier.upsert(
            userId: profileId,
            contentId: row.mediaId,
            type: type,
            title: title,
            poster: poster,
            addedAtUtc: row.updatedAtUtc,
          );
        }

        cursor = SyncCursor(updatedAt: row.updatedAt, id: row.id);
      }

      await _cursorStore.write(table: tableFavorites, profileId: profileId, cursor: cursor);

      if (page.length < 200) return;
    }
  }

  Future<void> _pullHistory({
    required SupabaseClient client,
    required String profileId,
    bool Function()? shouldCancel,
  }) async {
    final ds = SupabaseHistorySyncDataSource(client);
    var cursor = await _cursorStore.read(table: tableHistory, profileId: profileId);

    while (true) {
      if (shouldCancel?.call() == true) return;

      final page = await ds.listNextPage(
        profileId: profileId,
        cursor: cursor,
        limit: 200,
      );
      if (page.isEmpty) return;

      for (final row in page) {
        if (shouldCancel?.call() == true) return;

        final type = _parseContentType(row.mediaType);
        if (type == null) continue;

        if (row.deletedAtUtc != null) {
          await _historyApplier.remove(
            userId: profileId,
            contentId: row.mediaId,
            type: type,
          );
        } else {
          final title = row.title?.trim().isNotEmpty == true
              ? row.title!.trim()
              : row.mediaId;
          final poster = row.poster == null ? null : Uri.tryParse(row.poster!);

          await _historyApplier.upsertRemote(
            userId: profileId,
            contentId: row.mediaId,
            type: type,
            title: title,
            poster: poster,
            lastPlayedAtUtc: row.watchedAtUtc,
            lastPositionSeconds: row.lastPositionSeconds,
            durationSeconds: row.durationSeconds,
            season: row.season,
            episode: row.episode,
          );
        }

        cursor = SyncCursor(updatedAt: row.updatedAt, id: row.id);
      }

      await _cursorStore.write(table: tableHistory, profileId: profileId, cursor: cursor);

      if (page.length < 200) return;
    }
  }

  Future<void> _pullPlaylists({
    required SupabaseClient client,
    required String profileId,
    bool Function()? shouldCancel,
  }) async {
    final ds = SupabasePlaylistsSyncDataSource(client);
    var cursor = await _cursorStore.read(table: tablePlaylists, profileId: profileId);

    while (true) {
      if (shouldCancel?.call() == true) return;

      final page = await ds.listNextPage(profileId: profileId, cursor: cursor, limit: 200);
      if (page.isEmpty) return;

      for (final row in page) {
        if (shouldCancel?.call() == true) return;

        if (row.deletedAtUtc != null) {
          await _playlistsApplier.deletePlaylist(row.localId);
        } else {
          await _playlistsApplier.upsertHeader(
            userId: profileId,
            playlistId: row.localId,
            title: row.name,
            description: row.description,
            cover: row.cover == null ? null : Uri.tryParse(row.cover!),
            isPublic: row.isPublic,
            isPinned: row.isPinned,
            createdAtUtc: row.createdAtUtc,
            updatedAtUtc: row.updatedAtUtc,
          );

          final items = await ds.listPlaylistItems(playlistId: row.id);
          final localItems = items.map((i) {
            final type = _parseContentType(i.contentType) ?? ContentType.movie;
            return PlaylistItemRow(
              position: i.position,
              reference: ContentReference(
                id: i.contentId,
                title: MediaTitle(i.title),
                type: type,
                poster: i.poster == null ? null : Uri.tryParse(i.poster!),
                year: i.year,
              ),
              runtime: i.runtimeSeconds == null
                  ? null
                  : Duration(seconds: i.runtimeSeconds!),
              notes: i.notes,
              addedAt: i.addedAtUtc,
            );
          }).toList(growable: false);

          await _playlistsApplier.replaceItems(
            playlistId: row.localId,
            items: localItems,
            updatedAtUtc: row.updatedAtUtc,
          );
        }

        cursor = SyncCursor(updatedAt: row.updatedAt, id: row.id);
      }

      await _cursorStore.write(table: tablePlaylists, profileId: profileId, cursor: cursor);

      if (page.length < 200) return;
    }
  }

  ContentType? _parseContentType(String raw) {
    for (final t in ContentType.values) {
      if (t.name == raw) return t;
    }
    return null;
  }
}
