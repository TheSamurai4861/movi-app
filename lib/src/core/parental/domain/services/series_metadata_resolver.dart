import 'package:flutter/foundation.dart';

@immutable
class SeriesMetadataResolution {
  const SeriesMetadataResolution({required this.tmdbId, this.matchedTitle});

  final int tmdbId;
  final String? matchedTitle;
}

/// Port de résolution d'une série vers un identifiant TMDB.
abstract class SeriesMetadataResolver {
  Future<SeriesMetadataResolution?> resolveByTitle(String normalizedTitle);
}
