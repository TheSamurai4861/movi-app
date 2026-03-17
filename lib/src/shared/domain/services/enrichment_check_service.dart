import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tv_local_data_source.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/di/di.dart';

/// Statut d'enrichissement d'un contenu
enum EnrichmentStatus {
  /// Toutes les données nécessaires sont présentes
  complete,

  /// Certaines données sont présentes mais pas toutes
  partial,

  /// Aucune donnée enrichie n'est présente
  missing,
}

/// Service chargé de vérifier si un contenu est suffisamment enrichi
/// pour afficher la page de détails sans full enrich.
abstract class EnrichmentCheckService {
  /// Vérifie le statut d'enrichissement d'un film
  Future<EnrichmentStatus> checkMovieEnrichment(int movieId, String language);

  /// Vérifie le statut d'enrichissement d'une série
  Future<EnrichmentStatus> checkTvEnrichment(int seriesId, String language);
}

class EnrichmentCheckServiceImpl implements EnrichmentCheckService {
  EnrichmentCheckServiceImpl(this._movieLocal, this._tvLocal);

  final MovieLocalDataSource _movieLocal;
  final TvLocalDataSource _tvLocal;

  @override
  Future<EnrichmentStatus> checkMovieEnrichment(
    int movieId,
    String language,
  ) async {
    final logger = sl<AppLogger>();
    logger.debug(
      '🔍 [CHECK] checkMovieEnrichment démarré pour movieId=$movieId, language=$language',
      category: 'enrichment_check',
    );

    final cached = await _movieLocal.getMovieDetailLang(
      movieId,
      lang: language,
    );

    if (cached == null) {
      logger.debug(
        '🔍 [CHECK] Aucun cache trouvé pour movieId=$movieId, language=$language → MISSING',
        category: 'enrichment_check',
      );
      return EnrichmentStatus.missing;
    }

    logger.debug(
      '🔍 [CHECK] Cache trouvé pour movieId=$movieId, vérification données...',
      category: 'enrichment_check',
    );

    // Vérifier les données critiques nécessaires pour afficher la page
    // - poster ou backdrop (image hero)
    // - overview (synopsis)
    // - title (titre)
    // - releaseDate (année)
    // - voteAverage (rating)
    // - cast (peut être vide mais doit exister)
    // - recommendations (peut être vide mais doit exister)

    final hasPosterOrBackdrop =
        (cached.posterPath != null && cached.posterPath!.isNotEmpty) ||
        (cached.backdropPath != null && cached.backdropPath!.isNotEmpty);
    final hasOverview = cached.overview.isNotEmpty;
    final hasTitle = cached.title.isNotEmpty;
    final hasReleaseDate =
        cached.releaseDate != null && cached.releaseDate!.isNotEmpty;
    final hasVoteAverage = cached.voteAverage != null;
    final hasCast = cached.cast.isNotEmpty;
    final hasRecommendations = cached.recommendations.isNotEmpty;

    // Données critiques : poster/backdrop, overview, title, releaseDate
    final criticalDataComplete =
        hasPosterOrBackdrop && hasOverview && hasTitle && hasReleaseDate;

    logger.debug(
      '🔍 [CHECK] movieId=$movieId - hasPosterOrBackdrop=$hasPosterOrBackdrop, hasOverview=$hasOverview, hasTitle=$hasTitle, hasReleaseDate=$hasReleaseDate',
      category: 'enrichment_check',
    );

    if (!criticalDataComplete) {
      logger.debug(
        '🔍 [CHECK] Données critiques incomplètes pour movieId=$movieId → MISSING',
        category: 'enrichment_check',
      );
      return EnrichmentStatus.missing;
    }

    // Données secondaires : voteAverage, cast, recommendations
    final secondaryDataComplete =
        hasVoteAverage && hasCast && hasRecommendations;

    logger.debug(
      '🔍 [CHECK] movieId=$movieId - hasVoteAverage=$hasVoteAverage, hasCast=$hasCast, hasRecommendations=$hasRecommendations',
      category: 'enrichment_check',
    );

    if (secondaryDataComplete) {
      logger.debug(
        '🔍 [CHECK] Toutes les données présentes pour movieId=$movieId → COMPLETE',
        category: 'enrichment_check',
      );
      return EnrichmentStatus.complete;
    }

    logger.debug(
      '🔍 [CHECK] Données partielles pour movieId=$movieId → PARTIAL',
      category: 'enrichment_check',
    );
    return EnrichmentStatus.partial;
  }

  @override
  Future<EnrichmentStatus> checkTvEnrichment(
    int seriesId,
    String language,
  ) async {
    final logger = sl<AppLogger>();
    logger.debug(
      '🔍 [CHECK] checkTvEnrichment démarré pour seriesId=$seriesId, language=$language',
      category: 'enrichment_check',
    );

    final cached = await _tvLocal.getShowDetail(seriesId);

    if (cached == null) {
      logger.debug(
        '🔍 [CHECK] Aucun cache trouvé pour seriesId=$seriesId → MISSING',
        category: 'enrichment_check',
      );
      return EnrichmentStatus.missing;
    }

    logger.debug(
      '🔍 [CHECK] Cache trouvé pour seriesId=$seriesId, vérification données...',
      category: 'enrichment_check',
    );

    // Vérifier les données critiques nécessaires pour afficher la page
    // - poster ou backdrop (image hero)
    // - overview (synopsis)
    // - name (titre)
    // - firstAirDate (année)
    // - voteAverage (rating)
    // - cast (peut être vide mais doit exister)
    // - seasons (peut être vide mais doit exister)

    final hasPosterOrBackdrop =
        (cached.posterPath != null && cached.posterPath!.isNotEmpty) ||
        (cached.backdropPath != null && cached.backdropPath!.isNotEmpty);
    final hasOverview = cached.overview.isNotEmpty;
    final hasTitle = cached.name.isNotEmpty;
    final hasFirstAirDate =
        cached.firstAirDate != null && cached.firstAirDate!.isNotEmpty;
    final hasVoteAverage = cached.voteAverage != null;
    final hasCast = cached.cast.isNotEmpty;
    final hasSeasons = cached.seasons.isNotEmpty;

    // Données critiques : poster/backdrop, overview, title, firstAirDate
    final criticalDataComplete =
        hasPosterOrBackdrop && hasOverview && hasTitle && hasFirstAirDate;

    logger.debug(
      '🔍 [CHECK] seriesId=$seriesId - hasPosterOrBackdrop=$hasPosterOrBackdrop, hasOverview=$hasOverview, hasTitle=$hasTitle, hasFirstAirDate=$hasFirstAirDate',
      category: 'enrichment_check',
    );

    if (!criticalDataComplete) {
      logger.debug(
        '🔍 [CHECK] Données critiques incomplètes pour seriesId=$seriesId → MISSING',
        category: 'enrichment_check',
      );
      return EnrichmentStatus.missing;
    }

    // Données secondaires : voteAverage, cast, seasons
    final secondaryDataComplete = hasVoteAverage && hasCast && hasSeasons;

    logger.debug(
      '🔍 [CHECK] seriesId=$seriesId - hasVoteAverage=$hasVoteAverage, hasCast=$hasCast, hasSeasons=$hasSeasons',
      category: 'enrichment_check',
    );

    if (secondaryDataComplete) {
      logger.debug(
        '🔍 [CHECK] Toutes les données présentes pour seriesId=$seriesId → COMPLETE',
        category: 'enrichment_check',
      );
      return EnrichmentStatus.complete;
    }

    logger.debug(
      '🔍 [CHECK] Données partielles pour seriesId=$seriesId → PARTIAL',
      category: 'enrichment_check',
    );
    return EnrichmentStatus.partial;
  }
}
