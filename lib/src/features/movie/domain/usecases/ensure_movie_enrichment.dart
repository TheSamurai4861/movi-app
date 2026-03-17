import 'dart:async';
import 'package:movi/src/shared/domain/services/enrichment_check_service.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/di/di.dart';

/// Use case qui vérifie si un film est suffisamment enrichi et déclenche
/// le full enrich si nécessaire.
class EnsureMovieEnrichment {
  EnsureMovieEnrichment(
    this._enrichmentCheck,
    this._movieRepository,
    this._appState,
  );

  final EnrichmentCheckService _enrichmentCheck;
  final MovieRepository _movieRepository;
  final AppStateController _appState;

  /// Code de langue basé sur la locale courante (`fr-FR`, `en-US`, ou `en`).
  String get _languageCode {
    final locale = _appState.preferredLocale;
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}-$country';
  }

  /// Vérifie l'enrichissement et déclenche le full enrich si nécessaire.
  ///
  /// Retourne `true` si un enrichissement a été déclenché, `false` si
  /// les données sont déjà complètes.
  Future<bool> call(MovieId movieId) async {
    final logger = sl<AppLogger>();
    logger.debug(
      '🎬 [ENRICH] EnsureMovieEnrichment.call() démarré pour movieId=${movieId.value}',
      category: 'movie_enrichment',
    );

    final movieIdInt = int.tryParse(movieId.value);
    if (movieIdInt == null) {
      logger.debug(
        '🎬 [ENRICH] movieId n\'est pas un entier (${movieId.value}), enrichissement TMDB ignoré',
        category: 'movie_enrichment',
      );
      // Cas IPTV (ex: `xtream:123`) ou IDs non-TMDB : ce use-case ne doit pas
      // déclencher de fetch TMDB basé sur `MovieRepositoryImpl` (qui attend un ID numérique).
      return false;
    }

    final language = _appState.preferredLocale;
    logger.debug(
      '🎬 [ENRICH] Vérification enrichissement pour movieId=$movieIdInt, language=$language',
      category: 'movie_enrichment',
    );

    final status = await _enrichmentCheck.checkMovieEnrichment(
      movieIdInt,
      _languageCode,
    );

    logger.debug(
      '🎬 [ENRICH] Statut enrichissement pour movieId=$movieIdInt: $status',
      category: 'movie_enrichment',
    );

    // Si les données sont complètes, pas besoin d'enrichir
    if (status == EnrichmentStatus.complete) {
      logger.debug(
        '🎬 [ENRICH] Données complètes pour movieId=$movieIdInt, pas d\'enrichissement nécessaire',
        category: 'movie_enrichment',
      );
      return false;
    }

    // Si les données sont manquantes ou partielles, déclencher le full enrich
    logger.debug(
      '🎬 [ENRICH] Données incomplètes (status=$status) pour movieId=$movieIdInt, déclenchement full enrich',
      category: 'movie_enrichment',
    );
    try {
      logger.debug(
        '🎬 [ENRICH] Appel _movieRepository.getMovie() pour movieId=$movieIdInt...',
        category: 'movie_enrichment',
      );
      final startTime = DateTime.now();
      await _movieRepository
          .getMovie(movieId)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.log(
                LogLevel.warn,
                '🎬 [ENRICH] Timeout lors du full enrich pour movieId=$movieIdInt (30s)',
                category: 'movie_enrichment',
              );
              throw TimeoutException('Timeout enrichissement film après 30s');
            },
          );
      final duration = DateTime.now().difference(startTime);
      logger.debug(
        '🎬 [ENRICH] Full enrich réussi pour movieId=$movieIdInt en ${duration.inMilliseconds}ms',
        category: 'movie_enrichment',
      );
      return true;
    } on TimeoutException catch (e, st) {
      logger.log(
        LogLevel.warn,
        '🎬 [ENRICH] Timeout lors du full enrich pour movieId=$movieIdInt: $e',
        category: 'movie_enrichment',
        error: e,
        stackTrace: st,
      );
      // En cas de timeout, on considère que l'enrichissement n'a pas été déclenché
      // La page pourra quand même s'afficher avec les données partielles
      return false;
    } catch (e, st) {
      logger.log(
        LogLevel.warn,
        '🎬 [ENRICH] Erreur lors du full enrich pour movieId=$movieIdInt: $e',
        category: 'movie_enrichment',
        error: e,
        stackTrace: st,
      );
      // En cas d'erreur, on considère que l'enrichissement n'a pas été déclenché
      // La page pourra quand même s'afficher avec les données partielles
      return false;
    }
  }
}
