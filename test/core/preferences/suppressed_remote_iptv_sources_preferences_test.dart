import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/preferences/suppressed_remote_iptv_sources_preferences.dart';
import 'package:movi/src/core/storage/repositories/secure_storage_repository.dart';

void main() {
  test('stores suppressed remote local ids per account', () async {
    final storage = _FakeSecureStorageRepository();
    final prefs = SuppressedRemoteIptvSourcesPreferences(storage: storage);

    await prefs.suppress(accountId: 'user-a', localId: 'source-1');
    await prefs.suppress(accountId: 'user-a', localId: 'source-2');
    await prefs.suppress(accountId: 'user-b', localId: 'source-9');

    expect(
      await prefs.readSuppressedLocalIds(accountId: 'user-a'),
      {'source-1', 'source-2'},
    );
    expect(
      await prefs.readSuppressedLocalIds(accountId: 'user-b'),
      {'source-9'},
    );
  });

  test('clears a suppressed source and prunes ids absent from remote rows', () async {
    final storage = _FakeSecureStorageRepository();
    final prefs = SuppressedRemoteIptvSourcesPreferences(storage: storage);

    await prefs.suppress(accountId: 'user-a', localId: 'source-1');
    await prefs.suppress(accountId: 'user-a', localId: 'source-2');
    await prefs.clear(accountId: 'user-a', localId: 'source-1');

    expect(
      await prefs.readSuppressedLocalIds(accountId: 'user-a'),
      {'source-2'},
    );

    await prefs.retainOnlyRemoteMatches(
      accountId: 'user-a',
      remoteLocalIds: {'source-3'},
    );

    expect(
      await prefs.readSuppressedLocalIds(accountId: 'user-a'),
      isEmpty,
    );
  });
}

final class _FakeSecureStorageRepository extends SecureStorageRepository {
  _FakeSecureStorageRepository();

  final Map<String, Map<String, dynamic>> _store = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> get(String key) async {
    final value = _store[key];
    if (value == null) {
      return null;
    }
    return Map<String, dynamic>.from(value);
  }

  @override
  Future<void> put({
    required String key,
    required Map<String, dynamic> payload,
  }) async {
    _store[key] = Map<String, dynamic>.from(payload);
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }
}
