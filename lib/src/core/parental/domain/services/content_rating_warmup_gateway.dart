/// Port applicatif chargé de préchauffer les ratings d'un contenu.
///
/// L'implémentation concrète peut déléguer à un repository de ratings,
/// un cache, une API distante, etc.
abstract class ContentRatingWarmupGateway {
  Future<void> warmupMovieRating(int tmdbId);

  Future<void> warmupSeriesRating(int tmdbId);
}
