import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/library/application/models/sync_cursor.dart';

class CloudSyncCursorStore {
  CloudSyncCursorStore(this._storage);

  final SecureStorageRepository _storage;

  static const String _keyPrefix = 'cloud_sync.cursor.';

  String _key(String table, String profileId) => '$_keyPrefix$table.$profileId';

  Future<SyncCursor> read({
    required String table,
    required String profileId,
  }) async {
    final raw = await _storage.get(_key(table, profileId));
    if (raw == null) return SyncCursor.initial();

    final updatedAtRaw = raw['updated_at']?.toString();
    final id = raw['id']?.toString() ?? '';

    if (updatedAtRaw == null || updatedAtRaw.trim().isEmpty) {
      return SyncCursor.initial();
    }

    return SyncCursor(updatedAt: updatedAtRaw, id: id);
  }

  Future<void> write({
    required String table,
    required String profileId,
    required SyncCursor cursor,
  }) async {
    await _storage.put(
      key: _key(table, profileId),
      payload: {
        'updated_at': cursor.updatedAt,
        'id': cursor.id,
      },
    );
  }
}
