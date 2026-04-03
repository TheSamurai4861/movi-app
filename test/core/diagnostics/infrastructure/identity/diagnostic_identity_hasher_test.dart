import 'dart:convert';

import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/diagnostics/infrastructure/identity/diagnostic_identity_hasher.dart';
import 'package:movi/src/core/storage/repositories/secure_storage_repository.dart';

import '../../../../support/fake_secure_storage_platform.dart';

void main() {
  late FlutterSecureStoragePlatform originalPlatform;
  late FakeSecureStoragePlatform fakePlatform;
  late DiagnosticIdentityHasher hasher;

  setUp(() {
    originalPlatform = FlutterSecureStoragePlatform.instance;
    fakePlatform = FakeSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = fakePlatform;
    hasher = DiagnosticIdentityHasher(SecureStorageRepository());
  });

  tearDown(() {
    FlutterSecureStoragePlatform.instance = originalPlatform;
  });

  test('regenerates and persists a new salt when stored payload is invalid',
      () async {
    const storageKey = 'diagnostics.identity_salt.v1';
    fakePlatform.data[storageKey] = jsonEncode(<String, dynamic>{
      'salt': '',
      'createdAt': '2026-04-02T00:00:00.000Z',
    });

    final first = await hasher.hashId('account-123');
    final second = await hasher.hashId('account-123');
    final storedPayload = jsonDecode(fakePlatform.data[storageKey]!)
        as Map<String, dynamic>;

    expect(first, isNotEmpty);
    expect(second, first);
    expect(storedPayload['salt'], isA<String>());
    expect((storedPayload['salt'] as String), isNotEmpty);
  });
}
