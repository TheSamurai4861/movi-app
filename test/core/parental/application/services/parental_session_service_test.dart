import 'dart:convert';

import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/parental/application/services/parental_session_service.dart';
import 'package:movi/src/core/storage/repositories/secure_storage_repository.dart';

import '../../../../support/fake_secure_storage_platform.dart';

void main() {
  late FlutterSecureStoragePlatform originalPlatform;
  late FakeSecureStoragePlatform fakePlatform;
  late ParentalSessionService service;

  setUp(() {
    originalPlatform = FlutterSecureStoragePlatform.instance;
    fakePlatform = FakeSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = fakePlatform;
    service = ParentalSessionService(SecureStorageRepository());
  });

  tearDown(() {
    FlutterSecureStoragePlatform.instance = originalPlatform;
  });

  test('drops a corrupted persisted session and returns null', () async {
    const storageKey = 'parental.unlock_session.profile-1';
    fakePlatform.data[storageKey] = '{invalid';

    final session = await service.getSession('profile-1');

    expect(session, isNull);
    expect(fakePlatform.data.containsKey(storageKey), isFalse);
  });

  test('loads a valid persisted session', () async {
    const storageKey = 'parental.unlock_session.profile-1';
    fakePlatform.data[storageKey] = jsonEncode(<String, dynamic>{
      'profile_id': 'profile-1',
      'expires_at': DateTime.now()
          .add(const Duration(minutes: 5))
          .toUtc()
          .toIso8601String(),
    });

    final session = await service.getSession('profile-1');

    expect(session, isNotNull);
    expect(session?.profileId, 'profile-1');
  });
}
