import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class SyncOutboxItem {
  const SyncOutboxItem({
    required this.id,
    required this.userId,
    required this.entity,
    required this.entityKey,
    required this.operation,
    required this.createdAt,
    this.payload,
  });

  final int id;
  final String userId;
  final String entity;
  final String entityKey;
  final String operation;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;
}

/// Lightweight outbox for local-first sync.
///
/// Stores pending operations in SQLite to later push to Supabase (or any remote).
class SyncOutboxRepository {
  const SyncOutboxRepository(this._db);

  final Database _db;

  static const String _table = 'sync_outbox';

  Future<void> enqueue({
    required String userId,
    required String entity,
    required String entityKey,
    required String operation,
    Map<String, dynamic>? payload,
  }) async {
    await _db.insert(_table, {
      'user_id': userId,
      'entity': entity,
      'entity_key': entityKey,
      'op': operation,
      'payload': payload == null ? null : jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<SyncOutboxItem>> listPending({
    required String userId,
    int limit = 200,
  }) async {
    final rows = await _db.query(
      _table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
      limit: limit,
    );

    return rows.map((row) {
      Map<String, dynamic>? payload;
      final raw = row['payload'] as String?;
      if (raw != null && raw.isNotEmpty) {
        try {
          payload = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {
          payload = null;
        }
      }

      return SyncOutboxItem(
        id: row['id'] as int,
        userId: row['user_id'] as String,
        entity: row['entity'] as String,
        entityKey: row['entity_key'] as String,
        operation: row['op'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
        payload: payload,
      );
    }).toList(growable: false);
  }

  Future<void> delete(int id) async {
    await _db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

