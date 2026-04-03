import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/storage/repositories/secure_storage_repository.dart';
import 'package:movi/src/core/storage/storage_failures.dart';

import '../../../support/fake_secure_storage_platform.dart';

void main() {
  late FlutterSecureStoragePlatform originalPlatform;
  late FakeSecureStoragePlatform fakePlatform;
  late SecureStorageRepository repository;

  setUp(() {
    originalPlatform = FlutterSecureStoragePlatform.instance;
    fakePlatform = FakeSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = fakePlatform;
    repository = SecureStorageRepository();
  });

  tearDown(() {
    FlutterSecureStoragePlatform.instance = originalPlatform;
  });

  test('reads a valid JSON object payload', () async {
    fakePlatform.data['prefs.valid'] = '{"value":true,"count":1}';

    final payload = await repository.get('prefs.valid');

    expect(payload, <String, dynamic>{'value': true, 'count': 1});
  });

  test('throws a corruption failure for non-object JSON payloads', () async {
    fakePlatform.data['prefs.invalid'] = '["unexpected"]';

    await expectLater(
      repository.get('prefs.invalid'),
      throwsA(
        isA<StorageException>().having(
          (error) => error.failure.code,
          'failure.code',
          StorageFailureCode.corruptedPayload,
        ),
      ),
    );
  });

  test('skips corrupted entries when listing values by default', () async {
    fakePlatform.data['prefs.valid'] = '{"value":true}';
    fakePlatform.data['prefs.invalid'] = '{invalid';

    final values = await repository.listValues(prefix: 'prefs.');

    expect(values, <String, Map<String, dynamic>>{
      'prefs.valid': <String, dynamic>{'value': true},
    });
  });

  test('wraps platform read failures in a storage exception', () async {
    fakePlatform.readError = StateError('read failed');

    await expectLater(
      repository.get('prefs.any'),
      throwsA(
        isA<StorageException>().having(
          (error) => error.failure.code,
          'failure.code',
          StorageFailureCode.read,
        ),
      ),
    );
  });
}
