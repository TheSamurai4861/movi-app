import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:movi/src/core/storage/repositories/secure_payload_store.dart';
import 'package:movi/src/core/storage/storage_failures.dart';

class SecureStorageRepository implements SecurePayloadStore {
  SecureStorageRepository([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> put({
    required String key,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _storage.write(key: key, value: jsonEncode(payload));
    } catch (error) {
      throw StorageException(
        StorageWriteFailure(
          'Secure storage write failed for ${_storageKeyContext(key)}',
        ),
        error,
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> get(String key) async {
    final raw = await _read(key);
    if (raw == null) return null;
    return _decodePayload(key, raw);
  }

  Future<List<String>> listKeysByPrefix(String prefix) async {
    final all = await _readAll();
    return all.keys.where((k) => k.startsWith(prefix)).toList(growable: false);
  }

  Future<Map<String, Map<String, dynamic>>> listValues({
    String? prefix,
    bool skipCorrupted = true,
  }) async {
    final all = await _readAll();
    final entries = prefix == null
        ? all.entries
        : all.entries.where((e) => e.key.startsWith(prefix));
    final result = <String, Map<String, dynamic>>{};
    for (final entry in entries) {
      try {
        result[entry.key] = _decodePayload(entry.key, entry.value);
      } on StorageException {
        if (!skipCorrupted) rethrow;
      }
    }
    return result;
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (error) {
      throw StorageException(
        StorageWriteFailure(
          'Secure storage delete failed for ${_storageKeyContext(key)}',
        ),
        error,
      );
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (error) {
      throw StorageException(
        StorageReadFailure(
          'Secure storage read failed for ${_storageKeyContext(key)}',
        ),
        error,
      );
    }
  }

  Future<Map<String, String>> _readAll() async {
    try {
      return await _storage.readAll();
    } catch (error) {
      throw StorageException(
        const StorageReadFailure('Secure storage bulk read failed'),
        error,
      );
    }
  }

  Map<String, dynamic> _decodePayload(String key, String raw) {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw StorageException(
        StorageCorruptedPayloadFailure(
          'Secure storage payload is not valid JSON for '
          '${_storageKeyContext(key)}',
        ),
        error,
      );
    }

    if (decoded is! Map) {
      throw StorageException(
        StorageCorruptedPayloadFailure(
          'Secure storage payload is not a JSON object for '
          '${_storageKeyContext(key)}',
        ),
      );
    }

    try {
      return Map<String, dynamic>.from(decoded);
    } catch (error) {
      throw StorageException(
        StorageCorruptedPayloadFailure(
          'Secure storage payload contains unsupported values for '
          '${_storageKeyContext(key)}',
        ),
        error,
      );
    }
  }

  String _storageKeyContext(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      return '<empty-key>';
    }
    if (trimmed.length <= 32) {
      return trimmed;
    }
    return '${trimmed.substring(0, 20)}...${trimmed.substring(trimmed.length - 8)}';
  }
}
