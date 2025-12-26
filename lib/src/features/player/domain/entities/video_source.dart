import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Représente une source vidéo à lire
class VideoSource {
  const VideoSource({
    required this.url,
    this.title,
    this.subtitle,
    this.contentId,
    this.tmdbId,
    this.contentType,
    this.poster,
    this.season,
    this.episode,
    this.resumePosition,
  });

  /// URL de la vidéo (peut être locale ou distante)
  final String url;

  /// Titre de la vidéo (optionnel)
  final String? title;

  /// Sous-titre/description (optionnel)
  final String? subtitle;

  /// ID du contenu (pour l'historique)
  final String? contentId;

  /// TMDB numeric ID when available (used for parental rating checks).
  final int? tmdbId;

  /// Type de contenu (pour l'historique)
  final ContentType? contentType;

  /// Poster du contenu (pour l'historique)
  final Uri? poster;

  /// Numéro de saison (pour les séries)
  final int? season;

  /// Numéro d'épisode (pour les séries)
  final int? episode;

  /// Position de reprise de lecture (optionnel)
  final Duration? resumePosition;
}
