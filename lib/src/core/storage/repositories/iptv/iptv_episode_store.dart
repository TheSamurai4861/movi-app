import 'package:sqflite/sqflite.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_episode_data.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_storage_tables.dart';

/// Persists the episode cache used for IPTV series resolution.
class IptvEpisodeStore {
  IptvEpisodeStore(this._db);

  final Database _db;

  Future<void> saveEpisodes({
    required String ownerId,
    required String accountId,
    required int seriesId,
    required Map<int, Map<int, EpisodeData>> episodes,
  }) async {
    final batch = _db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    batch.delete(
      IptvStorageTables.episodes,
      where: 'owner_id = ? AND account_id = ? AND series_id = ?',
      whereArgs: <Object?>[ownerId, accountId, seriesId],
    );

    for (final seasonEntry in episodes.entries) {
      final seasonNumber = seasonEntry.key;
      for (final episodeEntry in seasonEntry.value.entries) {
        final episodeNumber = episodeEntry.key;
        final episodeData = episodeEntry.value;
        batch.insert(IptvStorageTables.episodes, <String, Object?>{
          'owner_id': ownerId,
          'account_id': accountId,
          'series_id': seriesId,
          'season_number': seasonNumber,
          'episode_number': episodeNumber,
          'episode_id': episodeData.episodeId,
          'extension': episodeData.extension,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    await batch.commit(noResult: true);
  }

  Future<int?> getEpisodeId({
    required String ownerId,
    required String accountId,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    final data = await getEpisodeData(
      ownerId: ownerId,
      accountId: accountId,
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    return data?.episodeId;
  }

  Future<EpisodeData?> getEpisodeData({
    required String ownerId,
    required String accountId,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    final rows = await _db.query(
      IptvStorageTables.episodes,
      columns: const ['episode_id', 'extension'],
      where:
          'owner_id = ? AND account_id = ? AND series_id = ? AND season_number = ? AND episode_number = ?',
      whereArgs: <Object?>[
        ownerId,
        accountId,
        seriesId,
        seasonNumber,
        episodeNumber,
      ],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final episodeId = rows.first['episode_id'] as int?;
    final extension = rows.first['extension'] as String?;
    if (episodeId == null) return null;

    return EpisodeData(episodeId: episodeId, extension: extension);
  }

  Future<Map<int, Map<int, EpisodeData>>> getAllEpisodesForSeries({
    required String ownerId,
    required String accountId,
    required int seriesId,
  }) async {
    final rows = await _db.query(
      IptvStorageTables.episodes,
      where: 'owner_id = ? AND account_id = ? AND series_id = ?',
      whereArgs: <Object?>[ownerId, accountId, seriesId],
      orderBy: 'season_number ASC, episode_number ASC',
    );

    final result = <int, Map<int, EpisodeData>>{};
    for (final row in rows) {
      final seasonNumber = row['season_number'] as int?;
      final episodeNumber = row['episode_number'] as int?;
      final episodeId = row['episode_id'] as int?;
      final extension = row['extension'] as String?;

      if (seasonNumber == null || episodeNumber == null || episodeId == null) {
        continue;
      }

      result.putIfAbsent(seasonNumber, () => <int, EpisodeData>{});
      result[seasonNumber]![episodeNumber] = EpisodeData(
        episodeId: episodeId,
        extension: extension,
      );
    }

    return result;
  }
}
