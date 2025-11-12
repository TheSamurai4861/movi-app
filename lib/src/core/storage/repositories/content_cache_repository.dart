import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/database/sqlite_database.dart';
import 'package:movi/src/core/storage/services/cache_policy.dart';

class ContentCacheRepository {
  Future<Database> get _db => LocalDatabase.instance();

  Future<void> put({
    required String key,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _db;
    await db.insert('content_cache', {
      'cache_key': key,
      'cache_type': type,
      'payload': jsonEncode(payload),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> get(String key) async {
    final db = await _db;
    final rows = await db.query(
      'content_cache',
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getWithPolicy(
    String key,
    CachePolicy policy,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'content_cache',
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      rows.first['updated_at'] as int,
    );
    if (policy.isExpired(updatedAt)) {
      await db.delete(
        'content_cache',
        where: 'cache_key = ?',
        whereArgs: [key],
      );
      return null;
    }
    return jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
  }

  Future<void> clearType(String type) async {
    final db = await _db;
    await db.delete(
      'content_cache',
      where: 'cache_type = ?',
      whereArgs: [type],
    );
  }
}
