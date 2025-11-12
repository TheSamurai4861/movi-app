import 'dart:convert';
import 'dart:math';

import 'package:movi/src/core/storage/storage.dart';

abstract class CredentialsVault {
  Future<void> storePassword(String accountId, String password);
  Future<String?> readPassword(String accountId);
  Future<void> removePassword(String accountId);
}

class CredentialsVaultImpl implements CredentialsVault {
  CredentialsVaultImpl(this._cache);

  final ContentCacheRepository _cache;

  static const _keyCacheKey = 'credentials_vault_key';
  static const _keyCacheType = 'security';

  Future<List<int>> _ensureKey() async {
    final existing = await _cache.get(_keyCacheKey);
    if (existing != null) {
      final b64 = existing['k'] as String?;
      if (b64 != null && b64.isNotEmpty) {
        return base64Decode(b64);
      }
    }
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    await _cache.put(
      key: _keyCacheKey,
      type: _keyCacheType,
      payload: {'k': base64Encode(bytes)},
    );
    return bytes;
  }

  String _encrypt(String plain, List<int> key) {
    final data = utf8.encode(plain);
    final out = List<int>.generate(
      data.length,
      (i) => data[i] ^ key[i % key.length],
      growable: false,
    );
    return base64Encode(out);
  }

  String _decrypt(String cipherB64, List<int> key) {
    final data = base64Decode(cipherB64);
    final out = List<int>.generate(
      data.length,
      (i) => data[i] ^ key[i % key.length],
      growable: false,
    );
    return utf8.decode(out);
  }

  @override
  Future<void> storePassword(String accountId, String password) async {
    final key = await _ensureKey();
    final enc = _encrypt(password, key);
    await _cache.put(
      key: 'secret_pw_$accountId',
      type: 'secret',
      payload: {'v': enc},
    );
  }

  @override
  Future<String?> readPassword(String accountId) async {
    final payload = await _cache.get('secret_pw_$accountId');
    if (payload == null) return null;
    final v = payload['v'] as String?;
    if (v == null || v.isEmpty) return null;
    final key = await _ensureKey();
    return _decrypt(v, key);
  }

  @override
  Future<void> removePassword(String accountId) async {
    // Clear by writing empty payload to avoid leaving stale entries.
    await _cache.put(
      key: 'secret_pw_$accountId',
      type: 'secret',
      payload: {'v': ''},
    );
  }
}
