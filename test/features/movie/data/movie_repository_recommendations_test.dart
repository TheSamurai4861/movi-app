import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/movie/data/repositories/movie_repository_impl.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/storage/repositories/watchlist_local_repository.dart';
import 'package:movi/src/core/storage/repositories/continue_watching_local_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

import '../../../helpers/in_memory_content_cache.dart';

class _FakeMovieRemote implements TmdbMovieRemoteDataSource {
  _FakeMovieRemote(this.detail);
  TmdbMovieDetailDto detail;
  int fetchCount = 0;

  @override
  Future<TmdbMovieDetailDto> fetchMovie(int id) async {
    fetchCount += 1;
    return detail;
  }

  @override
  Future<List<TmdbMovieSummaryDto>> fetchPopular() async => detail.recommendations;

  @override
  Future<List<TmdbMovieSummaryDto>> searchMovies(String query) async => detail.recommendations;

  @override
  Future<List<TmdbMovieSummaryDto>> fetchTrendingMovies({String window = 'week'}) async =>
      detail.recommendations;
}

class _NoopWatchlist implements WatchlistLocalRepository {
  @override
  Future<bool> exists(String contentId, ContentType type) async => false;

  @override
  Future<List<WatchlistEntry>> readAll(ContentType type) async => const [];

  @override
  Future<void> remove(String contentId, ContentType type) async {}

  @override
  Future<void> upsert(WatchlistEntry entry) async {}
}

class _NoopCW implements ContinueWatchingLocalRepository {
  const _NoopCW();
  @override
  Future<List<ContinueWatchingEntry>> readAll(ContentType type) async => const [];
  @override
  Future<void> remove(String contentId, ContentType type) async {}
  @override
  Future<void> upsert(ContinueWatchingEntry entry) async {}
}

void main() {
  group('MovieRepositoryImpl recommendations', () {
    late InMemoryContentCacheRepository cache;
    late MovieLocalDataSource local;
    late _FakeMovieRemote remote;
    late MovieRepositoryImpl repo;

    setUp(() {
      cache = InMemoryContentCacheRepository();
      local = MovieLocalDataSource(cache);
      remote = _FakeMovieRemote(
        TmdbMovieDetailDto(
          id: 1,
          title: 'Inception',
          overview: 'A mind heist',
          posterPath: '/p.jpg',
          backdropPath: '/b.jpg',
          logoPath: null,
          releaseDate: '2010-07-16',
          runtime: 148,
          voteAverage: 8.5,
          genres: const ['Sci-Fi'],
          cast: const [],
          directors: const [],
          recommendations: [
            TmdbMovieSummaryDto(id: 2, title: 'Interstellar', posterPath: '/i.jpg', backdropPath: null, releaseDate: '2014-11-07', voteAverage: 8.6),
          ],
        ),
      );
      repo = MovieRepositoryImpl(remote, const TmdbImageResolver(), _NoopWatchlist(), local, const _NoopCW());
    });

    test('fetches and caches recommendations when missing', () async {
      final list = await repo.getRecommendations(const MovieId('1'));
      expect(list, isNotEmpty);
      // Re-read from local to confirm it was cached
      final cached = await local.getRecommendations(1);
      expect(cached, isNotNull);
      expect(remote.fetchCount, 1);
    });

    test('uses cached recommendations on subsequent calls', () async {
      // Prime cache
      await repo.getRecommendations(const MovieId('1'));
      final before = remote.fetchCount;
      final again = await repo.getRecommendations(const MovieId('1'));
      expect(again, isNotEmpty);
      expect(remote.fetchCount, before); // no additional remote call
    });
  });
}
