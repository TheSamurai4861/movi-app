import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class PlayerRouteArgs {
  const PlayerRouteArgs({
    required this.url,
    this.title,
    this.subtitle,
    this.contentId,
    this.contentType,
    this.poster,
    this.season,
    this.episode,
    this.resumeSeconds,
  });

  final String url;
  final String? title;
  final String? subtitle;
  final String? contentId;
  final ContentType? contentType;
  final Uri? poster;
  final int? season;
  final int? episode;
  final int? resumeSeconds;

  VideoSource toVideoSource() {
    return VideoSource(
      url: url,
      title: title,
      subtitle: subtitle,
      contentId: contentId,
      contentType: contentType,
      poster: poster,
      season: season,
      episode: episode,
      resumePosition: resumeSeconds == null
          ? null
          : Duration(seconds: resumeSeconds!),
    );
  }
}

