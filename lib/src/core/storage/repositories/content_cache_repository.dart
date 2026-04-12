import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/services/cache_policy.dart';

class ContentCacheEntry {
  const ContentCacheEntry({
    required this.key,
    required this.type,
    required this.payload,
    required this.updatedAt,
  });

  final String key;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
}

class ContentCacheRepository {
  ContentCacheRepository(this._db);

  final Database _db;
  Future<void> _writeQueue = Future.value();

  Future<T> _runWrite<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final next = _writeQueue.then((_) async {
      try {
        final result = await _retryLocked(action);
        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    _writeQueue = next.catchError((_) {});
    return completer.future;
  }

  Future<T> _retryLocked<T>(Future<T> Function() action) async {
    const maxRetries = 3;
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } on DatabaseException catch (error) {
        if (!_isDatabaseLocked(error) || attempt >= maxRetries) {
          rethrow;
        }
        attempt += 1;
        await Future.delayed(Duration(milliseconds: 40 * attempt));
      }
    }
  }

  Future<void> put({
    required String key,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    await _runWrite(() {
      return _db.insert('content_cache', {
        'cache_key': key,
        'cache_type': type,
        'payload': jsonEncode(payload),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<Map<String, dynamic>?> get(String key, {CachePolicy? policy}) async {
    final entry = await getEntry(key);
    if (entry == null) return null;
    final updatedAt = entry.updatedAt;
    if (policy != null && policy.isExpired(updatedAt)) {
      await _runWrite(() {
        return _db.delete(
          'content_cache',
          where: 'cache_key = ?',
          whereArgs: [key],
        );
      });
      return null;
    }
    return entry.payload;
  }

  Future<Map<String, dynamic>?> getWithPolicy(
    String key,
    CachePolicy policy,
  ) async {
    return get(key, policy: policy);
  }

  Future<ContentCacheEntry?> getEntry(String key) async {
    final rows = await _db.query(
      'content_cache',
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ContentCacheEntry(
      key: row['cache_key'] as String,
      type: row['cache_type'] as String,
      payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  Future<void> clearType(String type) async {
    await _runWrite(() {
      return _db.delete(
        'content_cache',
        where: 'cache_type = ?',
        whereArgs: [type],
      );
    });
  }

  Future<void> remove(String key) async {
    await _runWrite(() {
      return _db.delete(
        'content_cache',
        where: 'cache_key = ?',
        whereArgs: [key],
      );
    });
  }

  bool _isDatabaseLocked(DatabaseException error) {
    final message = error.toString().toLowerCase();
    return message.contains('database is locked');
  }
}
