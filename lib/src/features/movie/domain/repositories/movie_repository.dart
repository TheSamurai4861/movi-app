import 'package:movi/src/features/movie/domain/entities/movie.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

/// Contrat domain pour les opérations liées aux films.
abstract class MovieRepository {
  /// Détail complet d’un film.
  Future<Movie> getMovie(MovieId id);

  /// Distribution principale (cast & crew).
  Future<List<PersonSummary>> getCredits(MovieId id);

  /// Recommandations similaires.
  Future<List<MovieSummary>> getRecommendations(MovieId id);

  /// Liste « Continue Watching ».
  Future<List<MovieSummary>> getContinueWatching();

  /// Résultats de recherche (titre, tags…).
  Future<List<MovieSummary>> searchMovies(String query);

  /// Présence dans la watchlist.
  Future<bool> isInWatchlist(MovieId id);

  /// Ajoute ou retire de la watchlist.
  Future<void> setWatchlist(MovieId id, {required bool saved});

  /// Supprime le cache des métadonnées d'un film pour forcer le rechargement.
  Future<void> refreshMetadata(MovieId id);
}
