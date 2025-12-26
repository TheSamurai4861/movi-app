import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/features/movie/movie.dart';
import 'package:movi/src/features/tv/tv.dart';
import 'package:movi/src/features/saga/saga.dart';
import 'package:movi/src/features/person/person.dart';
import 'package:movi/src/features/library/domain/repositories/library_repository.dart';
import 'package:movi/src/features/library/domain/services/history_filter.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(
    this._watchlist,
    this._history,
    this._playlists,
    this._personRepository, {
    String? userId,
  }) : _userId = userId ?? 'default';

  final WatchlistLocalRepository _watchlist;
  final HistoryLocalRepository _history;
  final PlaylistRepository _playlists;
  final PersonRepository _personRepository;
  final String _userId;

  @override
  Future<List<MovieSummary>> getLikedMovies() async {
    final entries = await _watchlist.readAll(
      ContentType.movie,
      userId: _userId,
    );
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
    final entries = await _watchlist.readAll(
      ContentType.series,
      userId: _userId,
    );
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
    final entries = await _watchlist.readAll(
      ContentType.person,
      userId: _userId,
    );
    final persons = <PersonSummary>[];

    for (final entry in entries) {
      // Si la photo n'est pas disponible dans la base de données, la charger depuis TMDB
      Uri? photo = entry.poster;
      if (photo == null) {
        try {
          final person = await _personRepository.getPerson(
            PersonId(entry.contentId),
          );
          photo = person.photo;
        } catch (e) {
          // Si l'erreur survient, continuer sans photo
          photo = null;
        }
      }

      persons.add(
        PersonSummary(
          id: PersonId(entry.contentId),
          name: entry.title,
          photo: photo,
        ),
      );
    }

    return persons;
  }

  @override
  Future<List<ContentReference>> getHistoryCompleted() async {
    final movies = await _history.readAll(ContentType.movie, userId: _userId);
    final shows = await _history.readAll(ContentType.series, userId: _userId);
    return [
      ...HistoryFilter.completed(movies),
      ...HistoryFilter.completed(shows),
    ];
  }

  @override
  Future<List<ContentReference>> getHistoryInProgress() async {
    final movies = await _history.readAll(ContentType.movie, userId: _userId);
    final shows = await _history.readAll(ContentType.series, userId: _userId);
    return [
      ...HistoryFilter.inProgress(movies),
      ...HistoryFilter.inProgress(shows),
    ];
  }

  @override
  Future<List<PlaylistSummary>> getUserPlaylists(String userId) {
    return _playlists.getUserPlaylists(userId);
  }
}
