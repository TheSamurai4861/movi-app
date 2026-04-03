import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'package:movi/src/core/storage/storage.dart';

final class DiagnosticIdentityHasher {
  DiagnosticIdentityHasher(this._secureStorage);

  final SecurePayloadStore _secureStorage;

  static const String _storageKey = 'diagnostics.identity_salt.v1';

  Future<String> hashId(String raw) async {
    final salt = await _getOrCreateSalt();
    final bytes = utf8.encode('$salt::$raw');
    return sha256.convert(bytes).toString();
  }

  Future<String> _getOrCreateSalt() async {
    try {
      final existing = await _secureStorage.get(_storageKey);
      final salt = existing?['salt'];
      if (salt is String && salt.isNotEmpty) return salt;
      if (existing != null) {
        await _safeRemoveCorruptedSalt();
      }
    } on StorageException catch (error) {
      _debug('read_invalid_salt', error);
      await _safeRemoveCorruptedSalt();
    }

    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    final salt = base64UrlEncode(bytes);
    try {
      await _secureStorage.put(key: _storageKey, payload: <String, dynamic>{
        'salt': salt,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });
    } on StorageException catch (error) {
      _debug('persist_generated_salt_failed', error);
    }
    return salt;
  }

  Future<void> _safeRemoveCorruptedSalt() async {
    try {
      await _secureStorage.remove(_storageKey);
    } on StorageException catch (error) {
      _debug('remove_corrupted_salt_failed', error);
    }
  }

  void _debug(String action, StorageException error) {
    assert(() {
      debugPrint('[DiagnosticIdentityHasher] $action: $error');
      return true;
    }());
  }
}

