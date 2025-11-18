import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/features/movie/movie.dart';
import 'package:movi/src/features/tv/tv.dart';
import 'package:movi/src/features/saga/saga.dart';
import 'package:movi/src/features/library/domain/repositories/library_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(
    this._watchlist,
    this._history,
    this._playlists, {
    String? userId,
  }) : _userId = userId ?? 'default';

  final WatchlistLocalRepository _watchlist;
  final HistoryLocalRepository _history;
  final PlaylistRepository _playlists;
  final String _userId;

  @override
  Future<List<MovieSummary>> getLikedMovies() async {
    final entries = await _watchlist.readAll(ContentType.movie, userId: _userId);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => MovieSummary(
            id: MovieId(e.contentId),
            title: MediaTitle(e.title),
            poster: e.poster!,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<TvShowSummary>> getLikedShows() async {
    final entries = await _watchlist.readAll(ContentType.series, userId: _userId);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => TvShowSummary(
            id: SeriesId(e.contentId),
            title: MediaTitle(e.title),
            poster: e.poster!,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SagaSummary>> getLikedSagas() async {
    final entries = await _watchlist.readAll(ContentType.saga, userId: _userId);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => SagaSummary(
            id: SagaId(e.contentId),
            title: MediaTitle(e.title),
            cover: e.poster!,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<PersonSummary>> getLikedPersons() async {
    final entries = await _watchlist.readAll(ContentType.person, userId: _userId);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => PersonSummary(
            id: PersonId(e.contentId),
            name: e.title,
            photo: e.poster,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ContentReference>> getHistoryCompleted() async {
    final movies = await _history.readAll(ContentType.movie);
    final shows = await _history.readAll(ContentType.series);
    return [..._filterCompleted(movies), ..._filterCompleted(shows)];
  }

  @override
  Future<List<ContentReference>> getHistoryInProgress() async {
    final movies = await _history.readAll(ContentType.movie);
    final shows = await _history.readAll(ContentType.series);
    return [..._filterInProgress(movies), ..._filterInProgress(shows)];
  }

  @override
  Future<List<PlaylistSummary>> getUserPlaylists(String userId) {
    return _playlists.getUserPlaylists(userId);
  }

  List<ContentReference> _filterCompleted(List<HistoryEntry> entries) {
    return entries
        .where((e) => _progress(e) >= 0.9)
        .map(
          (e) => ContentReference(
            id: e.contentId,
            title: MediaTitle(e.title),
            type: e.type,
            poster: e.poster,
          ),
        )
        .toList(growable: false);
  }

  List<ContentReference> _filterInProgress(List<HistoryEntry> entries) {
    return entries
        .where((e) {
          final p = _progress(e);
          return p > 0 && p < 0.9;
        })
        .map(
          (e) => ContentReference(
            id: e.contentId,
            title: MediaTitle(e.title),
            type: e.type,
            poster: e.poster,
          ),
        )
        .toList(growable: false);
  }

  double _progress(HistoryEntry e) {
    if (e.duration == null || e.duration!.inSeconds <= 0) return 0;
    final pos = e.lastPosition?.inSeconds ?? 0;
    return pos / e.duration!.inSeconds;
  }
}
