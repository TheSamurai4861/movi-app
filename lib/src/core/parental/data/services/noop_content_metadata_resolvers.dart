import 'package:movi/src/core/parental/domain/services/movie_metadata_resolver.dart';
import 'package:movi/src/core/parental/domain/services/series_metadata_resolver.dart';

/// Fallback sûr tant qu'aucun adaptateur concret n'est enregistré côté feature.
///
/// Permet de casser le couplage maintenant sans bloquer le bootstrap.
/// Dès que les implémentations concrètes existent, elles doivent être injectées
/// via GetIt à la place de ces no-op.
class NoopMovieMetadataResolver implements MovieMetadataResolver {
  const NoopMovieMetadataResolver();

  @override
  Future<MovieMetadataResolution?> resolveByTitle(
    String normalizedTitle,
  ) async {
    return null;
  }
}

class NoopSeriesMetadataResolver implements SeriesMetadataResolver {
  const NoopSeriesMetadataResolver();

  @override
  Future<SeriesMetadataResolution?> resolveByTitle(
    String normalizedTitle,
  ) async {
    return null;
  }
}
