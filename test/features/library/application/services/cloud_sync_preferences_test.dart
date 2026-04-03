import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/storage/repositories/secure_storage_repository.dart';
import 'package:movi/src/features/library/application/services/cloud_sync_preferences.dart';

import '../../../../support/fake_secure_storage_platform.dart';

void main() {
  late FlutterSecureStoragePlatform originalPlatform;
  late FakeSecureStoragePlatform fakePlatform;

  setUp(() {
    originalPlatform = FlutterSecureStoragePlatform.instance;
    fakePlatform = FakeSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = fakePlatform;
  });

  tearDown(() {
    FlutterSecureStoragePlatform.instance = originalPlatform;
  });

  test('falls back to enabled when persisted preference payload is invalid',
      () async {
    const storageKey = 'prefs.cloud_sync.auto_sync_enabled';
    fakePlatform.data[storageKey] = '{"value":"yes"}';

    final preferences = await CloudSyncPreferences.create(
      storage: SecureStorageRepository(),
    );
    addTearDown(preferences.dispose);

    expect(preferences.userWantsAutoSync, isTrue);
    expect(fakePlatform.data.containsKey(storageKey), isFalse);
  });

  test('loads a persisted false preference', () async {
    fakePlatform.data['prefs.cloud_sync.auto_sync_enabled'] = '{"value":false}';

    final preferences = await CloudSyncPreferences.create(
      storage: SecureStorageRepository(),
    );
    addTearDown(preferences.dispose);

    expect(preferences.userWantsAutoSync, isFalse);
  });
}
