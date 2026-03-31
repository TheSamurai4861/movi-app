import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:movi/src/core/storage/storage.dart';

final class DiagnosticIdentityHasher {
  DiagnosticIdentityHasher(this._secureStorage);

  final SecureStorageRepository _secureStorage;

  static const String _storageKey = 'diagnostics.identity_salt.v1';

  Future<String> hashId(String raw) async {
    final salt = await _getOrCreateSalt();
    final bytes = utf8.encode('$salt::$raw');
    return sha256.convert(bytes).toString();
  }

  Future<String> _getOrCreateSalt() async {
    final existing = await _secureStorage.get(_storageKey);
    final s = existing?['salt'] as String?;
    if (s != null && s.isNotEmpty) return s;

    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    final salt = base64UrlEncode(bytes);
    await _secureStorage.put(key: _storageKey, payload: <String, dynamic>{
      'salt': salt,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    return salt;
  }
}

