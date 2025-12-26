import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';

/// Contract for Library data (likes, history, user playlists).
/// No UI logic here; presentation consumes these lists directly.
abstract class LibraryRepository {
  /// User liked movies (local watchlist or favorites store).
  Future<List<MovieSummary>> getLikedMovies();

  /// User liked TV shows.
  Future<List<TvShowSummary>> getLikedShows();

  /// User liked sagas/collections.
  Future<List<SagaSummary>> getLikedSagas();

  /// User liked persons (optional depending on storage support).
  Future<List<PersonSummary>> getLikedPersons();

  /// Completed history items (e.g., progress ≥ 90%).
  Future<List<ContentReference>> getHistoryCompleted();

  /// In‑progress history items (0 < progress < 90%).
  Future<List<ContentReference>> getHistoryInProgress();

  /// User playlists summaries.
  Future<List<PlaylistSummary>> getUserPlaylists(String userId);
}
