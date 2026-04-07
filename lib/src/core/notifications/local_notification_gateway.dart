import 'dart:async';
import 'dart:convert';

final class NewEpisodeNotificationRequest {
  const NewEpisodeNotificationRequest({
    required this.seriesId,
    required this.seriesTitle,
    required this.seasonNumber,
    required this.episodeNumber,
    this.posterUri,
  });

  final String seriesId;
  final String seriesTitle;
  final int seasonNumber;
  final int episodeNumber;
  final Uri? posterUri;

  String get title => 'Nouvel épisode disponible';

  String get body =>
      '$seriesTitle — Saison $seasonNumber, épisode $episodeNumber';

  int get notificationId =>
      Object.hash(seriesId, seasonNumber, episodeNumber) & 0x7fffffff;

  String toPayload() => jsonEncode({
        'kind': 'series_new_episode',
        'seriesId': seriesId,
        'seasonNumber': seasonNumber,
        'episodeNumber': episodeNumber,
      });
}

final class SeriesNotificationNavigationIntent {
  const SeriesNotificationNavigationIntent({
    required this.seriesId,
    required this.seasonNumber,
    required this.episodeNumber,
  });

  final String seriesId;
  final int seasonNumber;
  final int episodeNumber;

  static SeriesNotificationNavigationIntent? fromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['kind'] != 'series_new_episode') return null;
      final seriesId = decoded['seriesId']?.toString() ?? '';
      if (seriesId.trim().isEmpty) return null;
      return SeriesNotificationNavigationIntent(
        seriesId: seriesId,
        seasonNumber:
            int.tryParse(decoded['seasonNumber']?.toString() ?? '') ?? 0,
        episodeNumber:
            int.tryParse(decoded['episodeNumber']?.toString() ?? '') ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

abstract class LocalNotificationGateway {
  Stream<SeriesNotificationNavigationIntent> get navigationIntents;

  Future<void> initialize();

  Future<bool> requestSeriesNotificationsPermissionIfNeeded();

  Future<bool> areSeriesNotificationsEnabled();

  Future<void> showNewEpisodeNotification(
    NewEpisodeNotificationRequest request,
  );
}
