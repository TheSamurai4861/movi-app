import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';

class PlaybackHistoryRepositoryImpl implements PlaybackHistoryRepository {
  const PlaybackHistoryRepositoryImpl(this._local);

  final HistoryLocalRepository _local;

  @override
  Future<void> upsertPlay({
    required String contentId,
    required ContentType type,
    required String title,
    Uri? poster,
    DateTime? playedAt,
    Duration? position,
    Duration? duration,
    int? season,
    int? episode,
    String? userId,
  }) {
    return _local.upsertPlay(
      contentId: contentId,
      type: type,
      title: title,
      poster: poster,
      playedAt: playedAt,
      position: position,
      duration: duration,
      season: season,
      episode: episode,
      userId: userId ?? 'default',
    );
  }

  @override
  Future<void> remove(String contentId, ContentType type, {String? userId}) {
    return _local.remove(contentId, type, userId: userId ?? 'default');
  }

  @override
  Future<PlaybackHistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String? userId,
  }) async {
    final e = await _local.getEntry(
      contentId,
      type,
      season: season,
      episode: episode,
      userId: userId ?? 'default',
    );
    if (e == null) return null;
    return PlaybackHistoryEntry(
      contentId: e.contentId,
      type: e.type,
      title: e.title,
      poster: e.poster,
      lastPosition: e.lastPosition,
      duration: e.duration,
      season: e.season,
      episode: e.episode,
    );
  }
}
