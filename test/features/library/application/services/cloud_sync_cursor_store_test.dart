import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/storage/repositories/secure_storage_repository.dart';
import 'package:movi/src/features/library/application/models/sync_cursor.dart';
import 'package:movi/src/features/library/application/services/cloud_sync_cursor_store.dart';

import '../../../../support/fake_secure_storage_platform.dart';

void main() {
  late FlutterSecureStoragePlatform originalPlatform;
  late FakeSecureStoragePlatform fakePlatform;
  late CloudSyncCursorStore store;

  setUp(() {
    originalPlatform = FlutterSecureStoragePlatform.instance;
    fakePlatform = FakeSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = fakePlatform;
    store = CloudSyncCursorStore(SecureStorageRepository());
  });

  tearDown(() {
    FlutterSecureStoragePlatform.instance = originalPlatform;
  });

  test('returns the initial cursor and clears invalid persisted payloads',
      () async {
    const storageKey = 'cloud_sync.cursor.history.profile-1';
    fakePlatform.data[storageKey] = '{"id":"42"}';

    final cursor = await store.read(table: 'history', profileId: 'profile-1');

    expect(cursor.updatedAt, SyncCursor.initial().updatedAt);
    expect(cursor.id, SyncCursor.initial().id);
    expect(fakePlatform.data.containsKey(storageKey), isFalse);
  });

  test('reads a valid persisted cursor', () async {
    fakePlatform.data['cloud_sync.cursor.history.profile-1'] =
        '{"updated_at":"2026-04-02T10:00:00.000Z","id":"42"}';

    final cursor = await store.read(table: 'history', profileId: 'profile-1');

    expect(cursor.updatedAt, '2026-04-02T10:00:00.000Z');
    expect(cursor.id, '42');
  });
}
