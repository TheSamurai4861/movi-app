import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/movie/data/repositories/movie_repository_impl.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/core/storage/repositories/continue_watching_local_repository.dart';

import '../../../helpers/in_memory_content_cache.dart';
import '../../../helpers/fake_watchlist_repository.dart';

class _StubMovieRemote implements TmdbMovieRemoteDataSource {
  @override
  Future<TmdbMovieDetailDto> fetchMovie(int id) => throw UnimplementedError();

  @override
  Future<List<TmdbMovieSummaryDto>> fetchPopular() async => const [];

  @override
  Future<List<TmdbMovieSummaryDto>> searchMovies(String query) async => const [];

  @override
  Future<List<TmdbMovieSummaryDto>> fetchTrendingMovies({String window = 'week'}) async => const [];
}

class _FakeCW implements ContinueWatchingLocalRepository {
  _FakeCW(this._entries);
  final List<ContinueWatchingEntry> _entries;

  @override
  Future<List<ContinueWatchingEntry>> readAll(ContentType type) async =>
      _entries.where((e) => e.type == type).toList(growable: false);

  @override
  Future<void> remove(String contentId, ContentType type) async {}

  @override
  Future<void> upsert(ContinueWatchingEntry entry) async {}
}

void main() {
  test('MovieRepositoryImpl.getContinueWatching maps only entries with poster', () async {
    final repo = MovieRepositoryImpl(
      _StubMovieRemote(),
      const TmdbImageResolver(),
      FakeWatchlistLocalRepository(),
      MovieLocalDataSource(InMemoryContentCacheRepository()),
      _FakeCW([
        ContinueWatchingEntry(
          contentId: '550',
          type: ContentType.movie,
          title: 'Fight Club',
          poster: Uri.parse('https://image.tmdb.org/t/p/w500/poster.jpg'),
          position: const Duration(minutes: 42),
          duration: const Duration(minutes: 139),
          updatedAt: DateTime.now(),
        ),
        ContinueWatchingEntry(
          contentId: '999',
          type: ContentType.movie,
          title: 'No Poster',
          poster: null,
          position: const Duration(minutes: 1),
          duration: const Duration(minutes: 10),
          updatedAt: DateTime.now(),
        ),
      ]),
    );

    final list = await repo.getContinueWatching();
    expect(list.length, 1);
    expect(list.first.id.value, '550');
    expect(list.first.title.value, 'Fight Club');
  });
}
