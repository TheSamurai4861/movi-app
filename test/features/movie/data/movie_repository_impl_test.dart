import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/movie/data/repositories/movie_repository_impl.dart';
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import '../../../helpers/in_memory_content_cache.dart';
import '../../../helpers/fake_watchlist_repository.dart';
import '../../../helpers/fake_continue_watching_repository.dart';

class _FakeMovieRemoteDataSource implements TmdbMovieRemoteDataSource {
  _FakeMovieRemoteDataSource(this.detail);

  final TmdbMovieDetailDto detail;
  int fetchCount = 0;

  @override
  Future<TmdbMovieDetailDto> fetchMovie(int id) async {
    fetchCount += 1;
    return detail;
  }

  @override
  Future<List<TmdbMovieSummaryDto>> searchMovies(String query) async => detail.recommendations;

  @override
  Future<List<TmdbMovieSummaryDto>> fetchPopular() async => detail.recommendations;

  @override
  Future<List<TmdbMovieSummaryDto>> fetchTrendingMovies({String window = 'week'}) async =>
      detail.recommendations;
}


void main() {
  group('MovieRepositoryImpl', () {
    late MovieRepository repository;
    late InMemoryContentCacheRepository cache;
    late _FakeMovieRemoteDataSource remote;

    setUp(() {
      final dto = TmdbMovieDetailDto(
        id: 1,
        title: 'Inception',
        overview: 'A mind heist.',
        posterPath: '/poster.jpg',
        backdropPath: '/backdrop.jpg',
        logoPath: '/logo.png',
        releaseDate: '2010-07-16',
        runtime: 148,
        voteAverage: 8.5,
        genres: ['Sci-Fi', 'Action'],
        cast: [TmdbMovieCastDto(id: 10, name: 'Leonardo DiCaprio', character: 'Cobb', profilePath: '/leo.jpg')],
        directors: [TmdbMovieCrewDto(id: 20, name: 'Christopher Nolan', job: 'Director')],
        recommendations: [TmdbMovieSummaryDto(id: 2, title: 'Interstellar', posterPath: '/poster2.jpg', backdropPath: '/backdrop2.jpg', releaseDate: '2014-11-07', voteAverage: 8.6)],
      );
      cache = InMemoryContentCacheRepository();
      remote = _FakeMovieRemoteDataSource(dto);
      repository = MovieRepositoryImpl(
        remote,
        const TmdbImageResolver(),
        FakeWatchlistLocalRepository(),
        MovieLocalDataSource(cache),
        FakeContinueWatchingLocalRepository(),
      );
    });

    test('maps movie detail correctly', () async {
      final movie = await repository.getMovie(const MovieId('1'));
      expect(movie.title.value, 'Inception');
      expect(movie.duration.inMinutes, 148);
      expect(movie.cast.first.name, 'Leonardo DiCaprio');
    });

    test('uses cached movie detail on repeated calls', () async {
      await repository.getMovie(const MovieId('1'));
      await repository.getMovie(const MovieId('1'));
      expect(remote.fetchCount, 1);
    });
  });
}
