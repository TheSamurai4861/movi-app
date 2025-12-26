import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class PlaybackHistoryEntry {
  const PlaybackHistoryEntry({
    required this.contentId,
    required this.type,
    required this.title,
    this.poster,
    this.lastPosition,
    this.duration,
    this.season,
    this.episode,
  });

  final String contentId;
  final ContentType type;
  final String title;
  final Uri? poster;
  final Duration? lastPosition;
  final Duration? duration;
  final int? season;
  final int? episode;
}

abstract class PlaybackHistoryRepository {
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
  });

  Future<void> remove(String contentId, ContentType type, {String? userId});

  Future<PlaybackHistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String? userId,
  });
}
