import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/repositories/iptv/iptv_storage_tables.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_settings.dart';

typedef PlaylistTypeNormalizer = XtreamPlaylistType Function(String? rawValue);

/// Persists the display settings associated with IPTV playlists.
///
/// The store intentionally keeps raw SQLite details away from the public
/// repository while preserving the current settings semantics.
class IptvPlaylistSettingsStore {
  IptvPlaylistSettingsStore(
    this._db, {
    required PlaylistTypeNormalizer normalize,
  }) : _normalizePlaylistType = normalize;

  final Database _db;
  final PlaylistTypeNormalizer _normalizePlaylistType;

  Future<List<XtreamPlaylistSettings>> getPlaylistSettings(
    String accountId,
  ) async {
    final rows = await _db.query(
      IptvStorageTables.playlistSettings,
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );

    final settings = <XtreamPlaylistSettings>[];
    for (final row in rows) {
      final playlistId = row['playlist_id'] as String?;
      final typeRaw = row['type'] as String?;
      final position = row['position'] as int?;
      final globalPosition = row['global_position'] as int?;
      final isVisibleNum = row['is_visible'] as int?;
      final updatedAtMs = row['updated_at'] as int?;
      if (playlistId == null ||
          typeRaw == null ||
          position == null ||
          isVisibleNum == null ||
          updatedAtMs == null) {
        continue;
      }

      settings.add(
        XtreamPlaylistSettings(
          accountId: accountId,
          playlistId: playlistId,
          type: _normalizePlaylistType(typeRaw),
          position: position,
          globalPosition: globalPosition ?? 0,
          isVisible: isVisibleNum == 1,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
        ),
      );
    }

    return settings;
  }

  Future<void> upsertPlaylistSettings(XtreamPlaylistSettings settings) async {
    await _db.insert(
      IptvStorageTables.playlistSettings,
      _toRow(settings),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertPlaylistSettingsBatch(
    List<XtreamPlaylistSettings> settings,
  ) async {
    if (settings.isEmpty) return;

    final batch = _db.batch();
    for (final settingsEntry in settings) {
      batch.insert(
        IptvStorageTables.playlistSettings,
        _toRow(settingsEntry),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> deletePlaylistSettingsNotIn({
    required String accountId,
    required Set<String> playlistIds,
  }) async {
    if (playlistIds.isEmpty) {
      await _db.delete(
        IptvStorageTables.playlistSettings,
        where: 'account_id = ?',
        whereArgs: <Object?>[accountId],
      );
      return;
    }

    final placeholders = List.filled(playlistIds.length, '?').join(',');
    await _db.delete(
      IptvStorageTables.playlistSettings,
      where: 'account_id = ? AND playlist_id NOT IN ($placeholders)',
      whereArgs: <Object?>[accountId, ...playlistIds],
    );
  }

  Future<void> setPlaylistVisibility({
    required String accountId,
    required String playlistId,
    required bool isVisible,
  }) async {
    await _db.update(
      IptvStorageTables.playlistSettings,
      <String, Object?>{
        'is_visible': isVisible ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'account_id = ? AND playlist_id = ?',
      whereArgs: <Object?>[accountId, playlistId],
    );
  }

  Future<void> setAllPlaylistsVisibility({
    required String accountId,
    required XtreamPlaylistType type,
    required bool isVisible,
  }) async {
    await _db.update(
      IptvStorageTables.playlistSettings,
      <String, Object?>{
        'is_visible': isVisible ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'account_id = ? AND type = ?',
      whereArgs: <Object?>[accountId, type.name],
    );
  }

  Future<void> reorderPlaylists({
    required String accountId,
    required XtreamPlaylistType type,
    required List<String> orderedPlaylistIds,
  }) async {
    final batch = _db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var index = 0; index < orderedPlaylistIds.length; index++) {
      batch.update(
        IptvStorageTables.playlistSettings,
        <String, Object?>{'position': index, 'updated_at': now},
        where: 'account_id = ? AND playlist_id = ? AND type = ?',
        whereArgs: <Object?>[accountId, orderedPlaylistIds[index], type.name],
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> reorderPlaylistsGlobal({
    required String accountId,
    required List<String> orderedPlaylistIds,
  }) async {
    final batch = _db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var index = 0; index < orderedPlaylistIds.length; index++) {
      batch.update(
        IptvStorageTables.playlistSettings,
        <String, Object?>{'global_position': index, 'updated_at': now},
        where: 'account_id = ? AND playlist_id = ?',
        whereArgs: <Object?>[accountId, orderedPlaylistIds[index]],
      );
    }

    await batch.commit(noResult: true);
  }

  Map<String, Object?> _toRow(XtreamPlaylistSettings settings) {
    return <String, Object?>{
      'account_id': settings.accountId,
      'playlist_id': settings.playlistId,
      'type': settings.type.name,
      'position': settings.position,
      'global_position': settings.globalPosition,
      'is_visible': settings.isVisible ? 1 : 0,
      'updated_at': settings.updatedAt.millisecondsSinceEpoch,
    };
  }
}
