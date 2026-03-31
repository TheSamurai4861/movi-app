import 'package:movi/src/core/parental/domain/repositories/content_rating_repository.dart';
import 'package:movi/src/core/parental/domain/services/content_rating_warmup_gateway.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Adaptateur de warmup basé sur le [ContentRatingRepository].
///
/// Le warmup consiste simplement à déclencher la lecture du rating,
/// ce qui permet à l'implémentation sous-jacente de remplir son cache.
class ContentRatingRepositoryWarmupGateway
    implements ContentRatingWarmupGateway {
  const ContentRatingRepositoryWarmupGateway(
    this._repository, {
    this.preferredRegions = const <String>['BE', 'FR', 'US'],
  });

  final ContentRatingRepository _repository;
  final List<String> preferredRegions;

  @override
  Future<void> warmupMovieRating(int tmdbId) {
    return _warmup(ContentType.movie, tmdbId);
  }

  @override
  Future<void> warmupSeriesRating(int tmdbId) {
    return _warmup(ContentType.series, tmdbId);
  }

  Future<void> _warmup(ContentType type, int tmdbId) async {
    if (tmdbId <= 0) {
      return;
    }

    await _repository.getMinAge(
      type: type,
      tmdbId: tmdbId,
      preferredRegions: preferredRegions,
    );
  }
}
