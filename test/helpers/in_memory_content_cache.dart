import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/core/storage/services/cache_policy.dart';

class InMemoryContentCacheRepository extends ContentCacheRepository {
  final Map<String, Map<String, dynamic>> _store = {};
  final Map<String, DateTime> _timestamps = {};

  @override
  Future<void> clearType(String type) async {
    final keys = _store.keys.where((key) => key.contains(type)).toList();
    for (final key in keys) {
      _store.remove(key);
      _timestamps.remove(key);
    }
  }

  @override
  Future<Map<String, dynamic>?> get(String key) async => _store[key];

  @override
  Future<Map<String, dynamic>?> getWithPolicy(String key, CachePolicy policy) async {
    final updatedAt = _timestamps[key];
    if (updatedAt == null) return null;
    if (policy.isExpired(updatedAt)) {
      _store.remove(key);
      _timestamps.remove(key);
      return null;
    }
    return _store[key];
  }

  @override
  Future<void> put({required String key, required String type, required Map<String, dynamic> payload}) async {
    _store[key] = payload;
    _timestamps[key] = DateTime.now();
  }
}
