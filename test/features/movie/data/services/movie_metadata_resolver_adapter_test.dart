import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/movie/data/services/movie_metadata_resolver_adapter.dart';
import 'package:movi/src/features/movie/domain/entities/movie.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

void main() {
  group('MovieMetadataResolverAdapter', () {
    test(
      'retourne le tmdbId quand le match normalisé exact est unique',
      () async {
        final repository = _FakeMovieRepository(
          searchResults: <MovieSummary>[
            MovieSummary(
              id: MovieId('603'),
              tmdbId: 603,
              title: MediaTitle('The Matrix'),
              poster: Uri.parse('https://example.com/matrix.jpg'),
              releaseYear: 1999,
            ),
          ],
        );

        final resolver = MovieMetadataResolverAdapter(
          repository: repository,
          logger: _FakeLogger(),
        );

        final result = await resolver.resolveByTitle('the matrix');

        expect(result, isNotNull);
        expect(result!.tmdbId, 603);
        expect(result.matchedTitle, 'The Matrix');
      },
    );

    test('retourne le seul candidat résolvable quand il est unique', () async {
      final repository = _FakeMovieRepository(
        searchResults: <MovieSummary>[
          MovieSummary(
            id: MovieId('11'),
            tmdbId: 11,
            title: MediaTitle('Star Wars'),
            poster: Uri.parse('https://example.com/starwars.jpg'),
            releaseYear: 1977,
          ),
        ],
      );

      final resolver = MovieMetadataResolverAdapter(
        repository: repository,
        logger: _FakeLogger(),
      );

      final result = await resolver.resolveByTitle('star wars episode iv');

      expect(result, isNotNull);
      expect(result!.tmdbId, 11);
      expect(result.matchedTitle, 'Star Wars');
    });

    test(
      'retourne null quand plusieurs matchs exacts sont possibles',
      () async {
        final repository = _FakeMovieRepository(
          searchResults: <MovieSummary>[
            MovieSummary(
              id: MovieId('1'),
              tmdbId: 1,
              title: MediaTitle('Halloween'),
              poster: Uri.parse('https://example.com/halloween-1.jpg'),
              releaseYear: 1978,
            ),
            MovieSummary(
              id: MovieId('2'),
              tmdbId: 2,
              title: MediaTitle('Halloween'),
              poster: Uri.parse('https://example.com/halloween-2.jpg'),
              releaseYear: 2007,
            ),
          ],
        );

        final resolver = MovieMetadataResolverAdapter(
          repository: repository,
          logger: _FakeLogger(),
        );

        final result = await resolver.resolveByTitle('halloween');

        expect(result, isNull);
      },
    );

    test('retourne null quand le titre demandé est vide', () async {
      final repository = _FakeMovieRepository(
        searchResults: const <MovieSummary>[],
      );
      final resolver = MovieMetadataResolverAdapter(
        repository: repository,
        logger: _FakeLogger(),
      );

      final result = await resolver.resolveByTitle('   ');

      expect(result, isNull);
      expect(repository.lastQuery, isNull);
    });
  });
}

class _FakeMovieRepository implements MovieRepository {
  _FakeMovieRepository({required this.searchResults});

  final List<MovieSummary> searchResults;
  String? lastQuery;

  @override
  Future<List<MovieSummary>> searchMovies(String query) async {
    lastQuery = query;
    return searchResults;
  }

  @override
  Future<Movie> getMovie(MovieId id) {
    throw UnimplementedError();
  }

  @override
  Future<List<PersonSummary>> getCredits(MovieId id) {
    throw UnimplementedError();
  }

  @override
  Future<List<MovieSummary>> getRecommendations(MovieId id) {
    throw UnimplementedError();
  }

  @override
  Future<List<MovieSummary>> getContinueWatching() {
    throw UnimplementedError();
  }

  @override
  Future<bool> isInWatchlist(MovieId id) {
    throw UnimplementedError();
  }

  @override
  Future<void> setWatchlist(MovieId id, {required bool saved}) {
    throw UnimplementedError();
  }

  @override
  Future<void> refreshMetadata(MovieId id) {
    throw UnimplementedError();
  }
}

class _FakeLogger implements AppLogger {
  @override
  void debug(String message, {String? category}) {}

  @override
  void info(String message, {String? category}) {}

  @override
  void warn(String message, {String? category}) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
