import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movi/src/core/app_update/data/models/app_update_remote_response.dart';

class AppUpdateCacheDataSource {
  AppUpdateCacheDataSource._({
    required FlutterSecureStorage storage,
    required String storageKey,
  }) : _storage = storage,
       _storageKey = storageKey;

  static const String defaultStorageKey = 'app_update.cached_decision';

  static Future<AppUpdateCacheDataSource> create({
    FlutterSecureStorage? storage,
    String storageKey = defaultStorageKey,
  }) async {
    return AppUpdateCacheDataSource._(
      storage: storage ?? const FlutterSecureStorage(),
      storageKey: storageKey,
    );
  }

  final FlutterSecureStorage _storage;
  final String _storageKey;

  Future<AppUpdateRemoteResponse?> read() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = AppUpdateRemoteResponse.decodeJsonMap(raw);
      return AppUpdateRemoteResponse.fromCacheJson(decoded);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> write(AppUpdateRemoteResponse response) {
    return _storage.write(
      key: _storageKey,
      value: jsonEncode(response.toCacheJson()),
    );
  }

  Future<void> clear() => _storage.delete(key: _storageKey);
}
