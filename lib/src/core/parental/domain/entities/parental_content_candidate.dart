import 'package:flutter/foundation.dart';

/// Type de contenu utile au préchargement parental.
enum ParentalContentCandidateKind { movie, series }

/// Candidat neutre extrait de la source catalogue.
///
/// Cette entité évite d'exposer des modèles IPTV / feature dans l'application
/// du module parental.
@immutable
class ParentalContentCandidate {
  const ParentalContentCandidate({
    required this.kind,
    required this.title,
    required this.normalizedTitle,
    this.tmdbId,
  });

  final ParentalContentCandidateKind kind;
  final String title;
  final String normalizedTitle;
  final int? tmdbId;

  bool get hasTmdbId => tmdbId != null && tmdbId! > 0;

  ParentalContentCandidate copyWith({
    ParentalContentCandidateKind? kind,
    String? title,
    String? normalizedTitle,
    int? tmdbId,
  }) {
    return ParentalContentCandidate(
      kind: kind ?? this.kind,
      title: title ?? this.title,
      normalizedTitle: normalizedTitle ?? this.normalizedTitle,
      tmdbId: tmdbId ?? this.tmdbId,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ParentalContentCandidate &&
            other.kind == kind &&
            other.title == title &&
            other.normalizedTitle == normalizedTitle &&
            other.tmdbId == tmdbId;
  }

  @override
  int get hashCode => Object.hash(kind, title, normalizedTitle, tmdbId);

  @override
  String toString() {
    return 'ParentalContentCandidate('
        'kind: $kind, '
        'title: $title, '
        'normalizedTitle: $normalizedTitle, '
        'tmdbId: $tmdbId'
        ')';
  }
}
