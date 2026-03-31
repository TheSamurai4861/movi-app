import 'package:flutter/foundation.dart';

@immutable
class MovieMetadataResolution {
  const MovieMetadataResolution({required this.tmdbId, this.matchedTitle});

  final int tmdbId;
  final String? matchedTitle;
}

/// Port de résolution d'un film vers un identifiant TMDB.
abstract class MovieMetadataResolver {
  Future<MovieMetadataResolution?> resolveByTitle(String normalizedTitle);
}
