import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageRepository {
  SecureStorageRepository([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> put({
    required String key,
    required Map<String, dynamic> payload,
  }) async {
    await _storage.write(key: key, value: jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> get(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<String>> listKeysByPrefix(String prefix) async {
    final all = await _storage.readAll();
    return all.keys.where((k) => k.startsWith(prefix)).toList(growable: false);
  }

  Future<Map<String, Map<String, dynamic>>> listValues({String? prefix}) async {
    final all = await _storage.readAll();
    final entries = prefix == null
        ? all.entries
        : all.entries.where((e) => e.key.startsWith(prefix));
    final result = <String, Map<String, dynamic>>{};
    for (final entry in entries) {
      try {
        result[entry.key] = jsonDecode(entry.value) as Map<String, dynamic>;
      } catch (_) {
        // Ignore malformed entries to avoid crashing callers.
      }
    }
    return result;
  }

  Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }
}
