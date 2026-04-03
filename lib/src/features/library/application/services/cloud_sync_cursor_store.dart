import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/library/application/models/sync_cursor.dart';

class CloudSyncCursorStore {
  CloudSyncCursorStore(this._storage);

  final SecurePayloadStore _storage;

  static const String _keyPrefix = 'cloud_sync.cursor.';

  String _key(String table, String profileId) => '$_keyPrefix$table.$profileId';

  Future<SyncCursor> read({
    required String table,
    required String profileId,
  }) async {
    final storageKey = _key(table, profileId);
    Map<String, dynamic>? raw;
    try {
      raw = await _storage.get(storageKey);
    } on StorageException {
      await _safeRemove(storageKey);
      return SyncCursor.initial();
    }
    if (raw == null) return SyncCursor.initial();

    final updatedAtRaw = raw['updated_at'];
    final updatedAt = updatedAtRaw is String ? updatedAtRaw.trim() : '';
    final id = raw['id']?.toString() ?? '';

    if (updatedAt.isEmpty) {
      await _safeRemove(storageKey);
      return SyncCursor.initial();
    }

    return SyncCursor(updatedAt: updatedAt, id: id);
  }

  Future<void> write({
    required String table,
    required String profileId,
    required SyncCursor cursor,
  }) async {
    await _storage.put(
      key: _key(table, profileId),
      payload: {'updated_at': cursor.updatedAt, 'id': cursor.id},
    );
  }

  Future<void> _safeRemove(String storageKey) async {
    try {
      await _storage.remove(storageKey);
    } on StorageException {
      // Keep fail-safe behavior even if cleanup itself is unavailable.
    }
  }
}
