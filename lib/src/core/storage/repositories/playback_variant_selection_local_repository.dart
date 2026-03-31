import 'package:sqflite/sqflite.dart';

import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

final class PlaybackVariantSelectionLocalRepository {
  PlaybackVariantSelectionLocalRepository(this._db);

  final Database _db;

  Future<String?> getSelectedVariantId(
    String contentId,
    ContentType contentType, {
    String userId = 'default',
  }) async {
    final rows = await _db.query(
      'playback_variant_selection',
      columns: const <String>['variant_id'],
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: <Object?>[contentId, contentType.name, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['variant_id'] as String?;
  }

  Future<void> upsertSelectedVariantId({
    required String contentId,
    required ContentType contentType,
    required String variantId,
    String userId = 'default',
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.insert(
      'playback_variant_selection',
      <String, Object?>{
        'content_id': contentId,
        'content_type': contentType.name,
        'variant_id': variantId,
        'updated_at': now,
        'user_id': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeSelection(
    String contentId,
    ContentType contentType, {
    String userId = 'default',
  }) {
    return _db.delete(
      'playback_variant_selection',
      where: 'content_id = ? AND content_type = ? AND user_id = ?',
      whereArgs: <Object?>[contentId, contentType.name, userId],
    );
  }
}

