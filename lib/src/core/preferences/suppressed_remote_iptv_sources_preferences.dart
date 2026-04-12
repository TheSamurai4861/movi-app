import 'package:movi/src/core/storage/repositories/secure_storage_repository.dart';

/// Device-local suppression list for remote IPTV sources that were deleted
/// locally but not yet confirmed deleted from the cloud.
///
/// The bootstrap uses this store to avoid silently rehydrating the same remote
/// `local_id` back into local storage after reconnect.
class SuppressedRemoteIptvSourcesPreferences {
  const SuppressedRemoteIptvSourcesPreferences({
    required SecureStorageRepository storage,
    this.storageKey = defaultStorageKey,
  }) : _storage = storage;

  static const String defaultStorageKey =
      'prefs.suppressed_remote_iptv_sources';

  final SecureStorageRepository _storage;
  final String storageKey;

  Future<Set<String>> readSuppressedLocalIds({
    required String accountId,
  }) async {
    final normalizedAccountId = _normalize(accountId);
    if (normalizedAccountId == null) {
      return <String>{};
    }

    final accounts = await _readAccounts();
    return Set<String>.from(accounts[normalizedAccountId] ?? const <String>{});
  }

  Future<void> suppress({
    required String accountId,
    required String localId,
  }) async {
    final normalizedAccountId = _normalize(accountId);
    final normalizedLocalId = _normalize(localId);
    if (normalizedAccountId == null || normalizedLocalId == null) {
      return;
    }

    final accounts = await _readAccounts();
    final ids = Set<String>.from(
      accounts[normalizedAccountId] ?? const <String>{},
    )..add(normalizedLocalId);
    accounts[normalizedAccountId] = ids;
    await _writeAccounts(accounts);
  }

  Future<void> clear({
    required String accountId,
    required String localId,
  }) async {
    final normalizedAccountId = _normalize(accountId);
    final normalizedLocalId = _normalize(localId);
    if (normalizedAccountId == null || normalizedLocalId == null) {
      return;
    }

    final accounts = await _readAccounts();
    final ids = Set<String>.from(
      accounts[normalizedAccountId] ?? const <String>{},
    )..remove(normalizedLocalId);
    if (ids.isEmpty) {
      accounts.remove(normalizedAccountId);
    } else {
      accounts[normalizedAccountId] = ids;
    }
    await _writeAccounts(accounts);
  }

  Future<void> retainOnlyRemoteMatches({
    required String accountId,
    required Set<String> remoteLocalIds,
  }) async {
    final normalizedAccountId = _normalize(accountId);
    if (normalizedAccountId == null) {
      return;
    }

    final normalizedRemoteIds = remoteLocalIds
        .map(_normalize)
        .whereType<String>()
        .toSet();

    final accounts = await _readAccounts();
    final current = Set<String>.from(
      accounts[normalizedAccountId] ?? const <String>{},
    );
    final retained = current.intersection(normalizedRemoteIds);

    if (retained.length == current.length) {
      return;
    }

    if (retained.isEmpty) {
      accounts.remove(normalizedAccountId);
    } else {
      accounts[normalizedAccountId] = retained;
    }
    await _writeAccounts(accounts);
  }

  Future<Map<String, Set<String>>> _readAccounts() async {
    final payload = await _storage.get(storageKey);
    if (payload == null) {
      return <String, Set<String>>{};
    }

    final rawAccounts = payload['accounts'];
    if (rawAccounts is! Map) {
      return <String, Set<String>>{};
    }

    final result = <String, Set<String>>{};
    for (final entry in rawAccounts.entries) {
      final accountId = _normalize(entry.key.toString());
      if (accountId == null) {
        continue;
      }

      final rawIds = entry.value;
      if (rawIds is! List) {
        continue;
      }

      final ids = rawIds
          .map((value) => _normalize(value?.toString()))
          .whereType<String>()
          .toSet();
      if (ids.isNotEmpty) {
        result[accountId] = ids;
      }
    }
    return result;
  }

  Future<void> _writeAccounts(Map<String, Set<String>> accounts) async {
    if (accounts.isEmpty) {
      await _storage.remove(storageKey);
      return;
    }

    final payload = <String, dynamic>{
      'accounts': accounts.map((accountId, ids) {
        final sortedIds = ids.toList(growable: false)..sort();
        return MapEntry(accountId, sortedIds);
      }),
    };
    await _storage.put(key: storageKey, payload: payload);
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
