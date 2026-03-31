# Snapshot de dossier

**Dossier analysé :** `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories`

## Arborescence

```text
repositories/
├── iptv/
│   ├── iptv_account_store.dart
│   ├── iptv_episode_data.dart
│   ├── iptv_episode_store.dart
│   ├── iptv_playlist_query_store.dart
│   ├── iptv_playlist_settings_store.dart
│   ├── iptv_playlist_store.dart
│   └── iptv_storage_tables.dart
├── content_cache_repository.dart
├── continue_watching_local_repository.dart
├── history_local_repository.dart
├── iptv_local_repository.dart
├── playlist_local_repository.dart
├── secure_storage_repository.dart
├── sync_outbox_repository.dart
└── watchlist_local_repository.dart
```

## Snapshots des fichiers

## content_cache_repository.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\content_cache_repository.dart`
- Taille : `3052` octets

```text
import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/services/cache_policy.dart';

class ContentCacheRepository {
  ContentCacheRepository(this._db);

  final Database _db;
  Future<void> _writeQueue = Future.value();

  Future<T> _runWrite<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final next = _writeQueue.then((_) async {
      try {
        final result = await _retryLocked(action);
        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    _writeQueue = next.catchError((_) {});
    return completer.future;
  }

  Future<T> _retryLocked<T>(Future<T> Function() action) async {
    const maxRetries = 3;
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } on DatabaseException catch (error) {
        if (!_isDatabaseLocked(error) || attempt >= maxRetries) {
          rethrow;
        }
        attempt += 1;
        await Future.delayed(Duration(milliseconds: 40 * attempt));
      }
    }
  }

  Future<void> put({
    required String key,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    await _runWrite(() {
      return _db.insert('content_cache', {
        'cache_key': key,
        'cache_type': type,
        'payload': jsonEncode(payload),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<Map<String, dynamic>?> get(String key, {CachePolicy? policy}) async {
    final rows = await _db.query(
      'content_cache',
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      rows.first['updated_at'] as int,
    );
    if (policy != null && policy.isExpired(updatedAt)) {
      await _runWrite(() {
        return _db.delete(
          'content_cache',
          where: 'cache_key = ?',
          whereArgs: [key],
        );
      });
      return null;
    }
    return jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;

[... snapshot tronqué ...]
```

## continue_watching_local_repository.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\continue_watching_local_repository.dart`
- Taille : `3340` octets

```text
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class ContinueWatchingEntry {
  const ContinueWatchingEntry({
    required this.contentId,
    required this.type,
    required this.title,
    this.poster,
    required this.position,
    this.duration,
    this.season,
    this.episode,
    required this.updatedAt,
    this.userId = 'default',
  });

  final String contentId;
  final ContentType type;
  final String title;
  final Uri? poster;
  final Duration position;
  final Duration? duration;
  final int? season;
  final int? episode;
  final DateTime updatedAt;
  final String userId;
}

abstract class ContinueWatchingLocalRepository {
  Future<void> upsert(ContinueWatchingEntry entry);
  Future<void> remove(String contentId, ContentType type, {String userId});
  Future<List<ContinueWatchingEntry>> readAll(
    ContentType type, {
    String userId,
  });
}

class ContinueWatchingLocalRepositoryImpl
    implements ContinueWatchingLocalRepository {
  ContinueWatchingLocalRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<void> upsert(ContinueWatchingEntry entry) async {
    final db = _db;
    await db.insert('continue_watching', {
      'content_id': entry.contentId,
      'content_type': entry.type.name,
      'title': entry.title,
      'poster': entry.poster?.toString(),
      'position': entry.position.inSeconds,
      'duration': entry.duration?.inSeconds,
      'season': entry.season,
      'episode': entry.episode,
      'updated_at': entry.updatedAt.millisecondsSinceEpoch,
      'user_id': entry.userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> remove(
    String contentId,
    ContentType type, {
    String userId = 'default',
  }) async {
    final db = _db;
    await db.delete(
      'continue_watching',
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: [contentId, type.name, userId],
    );
  }

  @override
  Future<List<ContinueWatchingEntry>> readAll(
    ContentType type, {
    String userId = 'default',

[... snapshot tronqué ...]
```

## history_local_repository.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\history_local_repository.dart`
- Taille : `6481` octets

```text
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

[... snapshot tronqué ...]
```

## iptv_local_repository.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\iptv_local_repository.dart`
- Taille : `12177` octets

```text
export 'package:movi/src/core/storage/repositories/iptv/iptv_episode_data.dart';

import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/repositories/iptv/iptv_account_store.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_episode_data.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_episode_store.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_playlist_query_store.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_playlist_settings_store.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_playlist_store.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_settings.dart';

/// Repository local pour la persistance des comptes et playlists IPTV.
/// Implémentation basée sur `sqflite` avec conversions typées et garde-fous.
class IptvLocalRepository {
  IptvLocalRepository(Database db)
    : _accountStore = IptvAccountStore(db),
      _episodeStore = IptvEpisodeStore(db),
      _playlistStore = IptvPlaylistStore(
        db,
        normalizePlaylistType: _normalizePlaylistType,
        normalizeItemType: _normalizeItemType,
      ),
      _playlistQueryStore = IptvPlaylistQueryStore(
        db,
        normalizePlaylistType: _normalizePlaylistType,
        normalizeItemType: _normalizeItemType,
      ),
      _playlistSettingsStore = IptvPlaylistSettingsStore(
        db,
        normalize: _normalizePlaylistType,
      );
  final IptvAccountStore _accountStore;
  final IptvEpisodeStore _episodeStore;
  final IptvPlaylistStore _playlistStore;
  final IptvPlaylistQueryStore _playlistQueryStore;
  final IptvPlaylistSettingsStore _playlistSettingsStore;

  final Map<String, Future<void>> _v2MigrationByAccount =
      <String, Future<void>>{};

  Future<void> _ensureV2PlaylistsForAccount(String accountId) {
    final existing = _v2MigrationByAccount[accountId];
    if (existing != null) return existing;
    final future = _playlistStore.migrateLegacyPlaylistsForAccount(accountId);
    _v2MigrationByAccount[accountId] = future;
    return future.whenComplete(() {
      _v2MigrationByAccount.remove(accountId);
    });
  }

  /// Enregistre ou met à jour un [XtreamAccount].
  Future<void> saveAccount(XtreamAccount account) =>
      _accountStore.saveAccount(account);

  /// Récupère tous les comptes IPTV persistés.
  Future<List<XtreamAccount>> getAccounts() => _accountStore.getAccounts();

  /// Supprime un compte et ses playlists associées.
  Future<void> removeAccount(String id) => _accountStore.removeAccount(id);

  // ============================================================================
  // Méthodes Stalker
  // ============================================================================

  Future<void> saveStalkerAccount(StalkerAccount account) =>
      _accountStore.saveStalkerAccount(account);

  Future<List<StalkerAccount>> getStalkerAccounts() =>
      _accountStore.getStalkerAccounts();

  Future<StalkerAccount?> getStalkerAccount(String id) =>
      _accountStore.getStalkerAccount(id);

  Future<void> removeStalkerAccount(String id) =>
      _accountStore.removeStalkerAccount(id);

[... snapshot tronqué ...]
```

## playlist_local_repository.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\playlist_local_repository.dart`
- Taille : `16085` octets

```text
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/core/storage/repositories/sync_outbox_repository.dart';

class PlaylistHeader {
  const PlaylistHeader({
    required this.id,
    required this.title,
    this.description,
    this.cover,
    required this.owner,
    required this.isPublic,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final Uri? cover;
  final String owner;
  final bool isPublic;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PlaylistItemRow {
  const PlaylistItemRow({
    required this.position,
    required this.reference,
    this.runtime,
    this.notes,
    required this.addedAt,
  });

  final int position;
  final ContentReference reference;
  final Duration? runtime;
  final String? notes;
  final DateTime addedAt;
}

class PlaylistDetailRow {
  const PlaylistDetailRow({required this.header, required this.items});
  final PlaylistHeader header;
  final List<PlaylistItemRow> items;
}

class PlaylistLocalRepository {
  PlaylistLocalRepository({required Database db, SyncOutboxRepository? outbox})
    : _db = db,
      _outbox = outbox;

  final Database _db;
  final SyncOutboxRepository? _outbox;

  Future<void> createPlaylist(PlaylistHeader header) async {
    await upsertHeader(header);
  }

  Future<void> upsertHeader(PlaylistHeader header) async {
    final db = _db;
    await db.insert('playlists', {
      'playlist_id': header.id,
      'title': header.title,
      'description': header.description,
      'cover': header.cover?.toString(),
      'owner': header.owner,
      'is_public': header.isPublic ? 1 : 0,
      'is_pinned': header.isPinned ? 1 : 0,
      'created_at': header.createdAt.millisecondsSinceEpoch,
      'updated_at': header.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await _outbox?.enqueue(
      userId: header.owner,

[... snapshot tronqué ...]
```

## secure_storage_repository.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\secure_storage_repository.dart`
- Taille : `1512` octets

```text
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageRepository {
  SecureStorageRepository([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> put({
    required String key,
    required Map<String, dynamic> payload,
  }) async {
    await _storage.write(key: key, value: jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> get(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<String>> listKeysByPrefix(String prefix) async {
    final all = await _storage.readAll();
    return all.keys.where((k) => k.startsWith(prefix)).toList(growable: false);
  }

  Future<Map<String, Map<String, dynamic>>> listValues({String? prefix}) async {
    final all = await _storage.readAll();
    final entries = prefix == null
        ? all.entries
        : all.entries.where((e) => e.key.startsWith(prefix));
    final result = <String, Map<String, dynamic>>{};
    for (final entry in entries) {
      try {
        result[entry.key] = jsonDecode(entry.value) as Map<String, dynamic>;
      } catch (_) {
        // Ignore malformed entries to avoid crashing callers.
      }
    }
    return result;
  }

  Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }
}
```

## sync_outbox_repository.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\sync_outbox_repository.dart`
- Taille : `2481` octets

```text
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class SyncOutboxItem {
  const SyncOutboxItem({
    required this.id,
    required this.userId,
    required this.entity,
    required this.entityKey,
    required this.operation,
    required this.createdAt,
    this.payload,
  });

  final int id;
  final String userId;
  final String entity;
  final String entityKey;
  final String operation;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;
}

/// Lightweight outbox for local-first sync.
///
/// Stores pending operations in SQLite to later push to Supabase (or any remote).
class SyncOutboxRepository {
  const SyncOutboxRepository(this._db);

  final Database _db;

  static const String _table = 'sync_outbox';

  Future<void> enqueue({
    required String userId,
    required String entity,
    required String entityKey,
    required String operation,
    Map<String, dynamic>? payload,
  }) async {
    await _db.insert(_table, {
      'user_id': userId,
      'entity': entity,
      'entity_key': entityKey,
      'op': operation,
      'payload': payload == null ? null : jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<SyncOutboxItem>> listPending({
    required String userId,
    int limit = 200,
  }) async {
    final rows = await _db.query(
      _table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
      limit: limit,
    );

    return rows
        .map((row) {
          Map<String, dynamic>? payload;
          final raw = row['payload'] as String?;
          if (raw != null && raw.isNotEmpty) {
            try {
              payload = jsonDecode(raw) as Map<String, dynamic>;
            } catch (_) {
              payload = null;
            }
          }

          return SyncOutboxItem(
            id: row['id'] as int,
            userId: row['user_id'] as String,
            entity: row['entity'] as String,
            entityKey: row['entity_key'] as String,

[... snapshot tronqué ...]
```

## watchlist_local_repository.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\watchlist_local_repository.dart`
- Taille : `4134` octets

```text
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/core/storage/repositories/sync_outbox_repository.dart';

class WatchlistEntry {
  const WatchlistEntry({
    required this.contentId,
    required this.type,
    required this.title,
    this.poster,
    required this.addedAt,
    this.userId = 'default',
  });

  final String contentId;
  final ContentType type;
  final String title;
  final Uri? poster;
  final DateTime addedAt;
  final String userId;
}

abstract class WatchlistLocalRepository {
  Future<bool> exists(String contentId, ContentType type, {String? userId});
  Future<void> upsert(WatchlistEntry entry);
  Future<void> remove(String contentId, ContentType type, {String? userId});
  Future<List<WatchlistEntry>> readAll(ContentType type, {String? userId});
}

class WatchlistLocalRepositoryImpl implements WatchlistLocalRepository {
  WatchlistLocalRepositoryImpl({
    required Database db,
    SyncOutboxRepository? outbox,
  }) : _db = db,
       _outbox = outbox;

  final Database _db;
  final SyncOutboxRepository? _outbox;

  @override
  Future<bool> exists(
    String contentId,
    ContentType type, {
    String? userId,
  }) async {
    final db = _db;
    final userIdValue = userId ?? 'default';
    final rows = await db.query(
      'watchlist',
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: [contentId, type.name, userIdValue],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<WatchlistEntry>> readAll(
    ContentType type, {
    String? userId,
  }) async {
    final db = _db;
    final userIdValue = userId ?? 'default';
    final rows = await db.query(
      'watchlist',
      where: 'content_type = ? AND user_id = ?',
      whereArgs: [type.name, userIdValue],
      orderBy: 'added_at DESC',
    );
    return rows
        .map(
          (row) => WatchlistEntry(
            contentId: row['content_id'] as String,
            type: type,
            title: row['title'] as String,
            poster:
                row['poster'] != null && (row['poster'] as String).isNotEmpty
                ? Uri.tryParse(row['poster'] as String)
                : null,

[... snapshot tronqué ...]
```

## iptv/iptv_account_store.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\iptv\iptv_account_store.dart`
- Taille : `7087` octets

```text
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_storage_tables.dart';

/// Persists IPTV account records and their account-scoped cleanup.
///
/// The public repository keeps its existing API, while this store isolates the
/// raw SQLite mapping logic for Xtream and Stalker accounts.
class IptvAccountStore {
  IptvAccountStore(this._db);

  final Database _db;

  Future<void> saveAccount(XtreamAccount account) async {
    await _db.insert(IptvStorageTables.accounts, <String, Object?>{
      'account_id': account.id,
      'alias': account.alias,
      'endpoint': account.endpoint.toRawUrl(),
      'username': account.username,
      'status': account.status.name,
      'expiration': account.expirationDate?.millisecondsSinceEpoch,
      'created_at': account.createdAt.millisecondsSinceEpoch,
      'last_error': account.lastError,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<XtreamAccount>> getAccounts() async {
    final rows = await _db.query(IptvStorageTables.accounts);
    return rows.map(_parseAccountRow).toList(growable: false);
  }

  Future<void> removeAccount(String id) async {
    await _db.delete(
      IptvStorageTables.accounts,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _deleteAssociatedAccountData(id);
  }

  Future<void> saveStalkerAccount(StalkerAccount account) async {
    await _db.insert(
      IptvStorageTables.stalkerAccounts,
      <String, Object?>{
        'account_id': account.id,
        'alias': account.alias,
        'endpoint': account.endpoint.toRawUrl(),
        'mac_address': account.macAddress,
        'username': account.username,
        'token': account.token,
        'status': account.status.name,
        'expiration': account.expirationDate?.millisecondsSinceEpoch,
        'created_at': account.createdAt.millisecondsSinceEpoch,
        'last_error': account.lastError,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StalkerAccount>> getStalkerAccounts() async {
    final rows = await _db.query(IptvStorageTables.stalkerAccounts);
    return rows.map(_parseStalkerAccountRow).toList(growable: false);
  }

  Future<StalkerAccount?> getStalkerAccount(String id) async {
    final rows = await _db.query(
      IptvStorageTables.stalkerAccounts,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _parseStalkerAccountRow(rows.first);
  }

  Future<void> removeStalkerAccount(String id) async {

[... snapshot tronqué ...]
```

## iptv/iptv_episode_data.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\iptv\iptv_episode_data.dart`
- Taille : `368` octets

```text
/// Cached IPTV episode identifier along with its optional container extension.
///
/// This value object is reused by TV enrichment and stream URL resolution when
/// a series episode can be resolved from local storage.
class EpisodeData {
  const EpisodeData({required this.episodeId, this.extension});

  final int episodeId;
  final String? extension;
}
```

## iptv/iptv_episode_store.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\iptv\iptv_episode_store.dart`
- Taille : `3709` octets

```text
import 'package:sqflite/sqflite.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_episode_data.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_storage_tables.dart';

/// Persists the episode cache used for IPTV series resolution.
class IptvEpisodeStore {
  IptvEpisodeStore(this._db);

  final Database _db;

  Future<void> saveEpisodes({
    required String accountId,
    required int seriesId,
    required Map<int, Map<int, EpisodeData>> episodes,
  }) async {
    final batch = _db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    batch.delete(
      IptvStorageTables.episodes,
      where: 'account_id = ? AND series_id = ?',
      whereArgs: <Object?>[accountId, seriesId],
    );

    for (final seasonEntry in episodes.entries) {
      final seasonNumber = seasonEntry.key;
      for (final episodeEntry in seasonEntry.value.entries) {
        final episodeNumber = episodeEntry.key;
        final episodeData = episodeEntry.value;
        batch.insert(IptvStorageTables.episodes, <String, Object?>{
          'account_id': accountId,
          'series_id': seriesId,
          'season_number': seasonNumber,
          'episode_number': episodeNumber,
          'episode_id': episodeData.episodeId,
          'extension': episodeData.extension,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    await batch.commit(noResult: true);
  }

  Future<int?> getEpisodeId({
    required String accountId,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    final data = await getEpisodeData(
      accountId: accountId,
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    return data?.episodeId;
  }

  Future<EpisodeData?> getEpisodeData({
    required String accountId,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    final rows = await _db.query(
      IptvStorageTables.episodes,
      columns: const ['episode_id', 'extension'],
      where:
          'account_id = ? AND series_id = ? AND season_number = ? AND episode_number = ?',
      whereArgs: <Object?>[accountId, seriesId, seasonNumber, episodeNumber],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final episodeId = rows.first['episode_id'] as int?;
    final extension = rows.first['extension'] as String?;
    if (episodeId == null) return null;


[... snapshot tronqué ...]
```

## iptv/iptv_playlist_query_store.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\iptv\iptv_playlist_query_store.dart`
- Taille : `7483` octets

```text
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/repositories/iptv/iptv_playlist_store.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_storage_tables.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

/// Read-only queries over normalized IPTV playlists and playlist items.
class IptvPlaylistQueryStore {
  IptvPlaylistQueryStore(
    this._db, {
    required PlaylistTypeNormalizer normalizePlaylistType,
    required PlaylistItemTypeNormalizer normalizeItemType,
  }) : _normalizePlaylistType = normalizePlaylistType,
       _normalizeItemType = normalizeItemType;

  final Database _db;
  final PlaylistTypeNormalizer _normalizePlaylistType;
  final PlaylistItemTypeNormalizer _normalizeItemType;

  Future<Set<int>> getAvailableTmdbIds({
    XtreamPlaylistItemType? type,
    Set<String>? accountIds,
  }) async {
    if (accountIds != null && accountIds.isEmpty) return <int>{};

    final where = StringBuffer('tmdb_id IS NOT NULL AND tmdb_id > 0');
    final args = <Object?>[];
    if (type != null) {
      where.write(' AND type = ?');
      args.add(type.name);
    }
    if (accountIds != null && accountIds.isNotEmpty) {
      where.write(' AND account_id IN (');
      where.write(List.filled(accountIds.length, '?').join(','));
      where.write(')');
      args.addAll(accountIds);
    }

    final rows = await _db.query(
      IptvStorageTables.playlistItems,
      distinct: true,
      columns: const ['tmdb_id'],
      where: where.toString(),
      whereArgs: args,
    );

    final ids = <int>{};
    for (final row in rows) {
      final raw = row['tmdb_id'];
      final id = switch (raw) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      };
      if (id != null && id > 0) ids.add(id);
    }
    return ids;
  }

  Future<List<XtreamPlaylistItem>> getAllPlaylistItems({
    Set<String>? accountIds,
    XtreamPlaylistItemType? type,
  }) async {
    if (accountIds != null && accountIds.isEmpty) {
      return const <XtreamPlaylistItem>[];
    }

    final where = StringBuffer('1 = 1');
    final args = <Object?>[];
    if (accountIds != null && accountIds.isNotEmpty) {
      where.write(' AND i.account_id IN (');
      where.write(List.filled(accountIds.length, '?').join(','));
      where.write(')');
      args.addAll(accountIds);
    }
    if (type != null) {
      where.write(' AND i.type = ?');
      args.add(type.name);
    }

[... snapshot tronqué ...]
```

## iptv/iptv_playlist_settings_store.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\iptv\iptv_playlist_settings_store.dart`
- Taille : `6104` octets

```text
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/repositories/iptv/iptv_storage_tables.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_settings.dart';

typedef PlaylistTypeNormalizer = XtreamPlaylistType Function(String? rawValue);

/// Persists the display settings associated with IPTV playlists.
///
/// The store intentionally keeps raw SQLite details away from the public
/// repository while preserving the current settings semantics.
class IptvPlaylistSettingsStore {
  IptvPlaylistSettingsStore(
    this._db, {
    required PlaylistTypeNormalizer normalize,
  }) : _normalizePlaylistType = normalize;

  final Database _db;
  final PlaylistTypeNormalizer _normalizePlaylistType;

  Future<List<XtreamPlaylistSettings>> getPlaylistSettings(
    String accountId,
  ) async {
    final rows = await _db.query(
      IptvStorageTables.playlistSettings,
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );

    final settings = <XtreamPlaylistSettings>[];
    for (final row in rows) {
      final playlistId = row['playlist_id'] as String?;
      final typeRaw = row['type'] as String?;
      final position = row['position'] as int?;
      final globalPosition = row['global_position'] as int?;
      final isVisibleNum = row['is_visible'] as int?;
      final updatedAtMs = row['updated_at'] as int?;
      if (playlistId == null ||
          typeRaw == null ||
          position == null ||
          isVisibleNum == null ||
          updatedAtMs == null) {
        continue;
      }

      settings.add(
        XtreamPlaylistSettings(
          accountId: accountId,
          playlistId: playlistId,
          type: _normalizePlaylistType(typeRaw),
          position: position,
          globalPosition: globalPosition ?? 0,
          isVisible: isVisibleNum == 1,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
        ),
      );
    }

    return settings;
  }

  Future<void> upsertPlaylistSettings(XtreamPlaylistSettings settings) async {
    await _db.insert(
      IptvStorageTables.playlistSettings,
      _toRow(settings),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertPlaylistSettingsBatch(
    List<XtreamPlaylistSettings> settings,
  ) async {
    if (settings.isEmpty) return;

    final batch = _db.batch();
    for (final settingsEntry in settings) {
      batch.insert(
        IptvStorageTables.playlistSettings,
        _toRow(settingsEntry),

[... snapshot tronqué ...]
```

## iptv/iptv_playlist_store.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\iptv\iptv_playlist_store.dart`
- Taille : `11445` octets

```text
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/repositories/iptv/iptv_storage_tables.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

typedef PlaylistTypeNormalizer = XtreamPlaylistType Function(String? rawValue);
typedef PlaylistItemTypeNormalizer =
    XtreamPlaylistItemType Function(
      String rawValue,
      XtreamPlaylistType playlistType,
    );

/// Persists normalized IPTV playlists and migrates the legacy payload table.
class IptvPlaylistStore {
  IptvPlaylistStore(
    this._db, {
    required PlaylistTypeNormalizer normalizePlaylistType,
    required PlaylistItemTypeNormalizer normalizeItemType,
  }) : _normalizePlaylistType = normalizePlaylistType,
       _normalizeItemType = normalizeItemType;

  final Database _db;
  final PlaylistTypeNormalizer _normalizePlaylistType;
  final PlaylistItemTypeNormalizer _normalizeItemType;

  Future<void> migrateLegacyPlaylistsForAccount(String accountId) async {
    final legacyHasAny = await _hasAnyRow(
      table: IptvStorageTables.playlistsLegacy,
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );
    if (!legacyHasAny) return;

    final legacyRows = await _db.query(
      IptvStorageTables.playlistsLegacy,
      columns: const ['category_id', 'updated_at'],
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );
    if (legacyRows.isEmpty) return;

    for (final row in legacyRows) {
      final playlistId = row['category_id'] as String?;
      if (playlistId == null || playlistId.isEmpty) continue;

      final payloadRow = await _db.query(
        IptvStorageTables.playlistsLegacy,
        columns: const ['payload'],
        where: 'account_id = ? AND category_id = ?',
        whereArgs: <Object?>[accountId, playlistId],
        limit: 1,
      );
      if (payloadRow.isEmpty) continue;

      final payload = _decodeMap(payloadRow.first['payload']);
      if (payload == null) continue;

      final title = _asString(payload['title']) ?? '';
      final playlistType = _normalizePlaylistType(_asString(payload['type']));
      final updatedAt =
          (row['updated_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
      final itemsList = _asList(payload['items']);

      await _db.transaction((txn) async {
        await txn.insert(
          IptvStorageTables.playlists,
          <String, Object?>{
            'account_id': accountId,
            'playlist_id': playlistId,
            'title': title,
            'type': playlistType.name,
            'updated_at': updatedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.delete(

[... snapshot tronqué ...]
```

## iptv/iptv_storage_tables.dart

- Chemin absolu : `C:\Users\berny\DEV\Flutter\movi\lib\src\core\storage\repositories\iptv\iptv_storage_tables.dart`
- Taille : `699` octets

```text
/// Centralizes the SQLite table names used by the IPTV local persistence layer.
///
/// Keeping these identifiers in one place avoids string drift when the
/// repository is decomposed into smaller collaborators.
final class IptvStorageTables {
  const IptvStorageTables._();

  static const String accounts = 'iptv_accounts';
  static const String stalkerAccounts = 'stalker_accounts';
  static const String playlistsLegacy = 'iptv_playlists';
  static const String playlists = 'iptv_playlists_v2';
  static const String playlistItems = 'iptv_playlist_items_v2';
  static const String episodes = 'iptv_episodes';
  static const String playlistSettings = 'iptv_playlist_settings';
}
```
