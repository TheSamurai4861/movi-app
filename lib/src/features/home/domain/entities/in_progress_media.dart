import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Modèle domain pour représenter un média "en cours" avec progression.
class InProgressMedia {
  const InProgressMedia({
    required this.contentId,
    required this.type,
    required this.title,
    this.poster,
    this.backdrop,
    required this.progress,
    this.season,
    this.episode,
    this.year,
    this.duration,
    this.rating,
    this.seriesTitle,
    this.episodeTitle,
  });

  final String contentId;
  final ContentType type;
  final String title;
  final Uri? poster;
  final Uri? backdrop;
  final double progress; // 0.0 à 1.0
  final int? season;
  final int? episode;
  final int? year;
  final Duration? duration;
  final double? rating;
  final String? seriesTitle; // Pour les épisodes
  final String? episodeTitle; // Titre de l'épisode sans numéro
}
