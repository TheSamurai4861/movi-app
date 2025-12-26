import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/domain/services/similarity_service.dart';
import 'package:movi/src/shared/domain/services/tmdb_id_resolver_service.dart';

void main() {
  test('movie resolver uses cleaned candidates', () async {
    final client = _buildClient();
    final movieRemote = _FakeMovieRemote(
      {
        'Top Gun Maverick': [
          TmdbMovieSummaryDto(
            id: 1,
            title: 'Top Gun: Maverick',
            posterPath: null,
            backdropPath: null,
            releaseDate: '2022-05-01',
            voteAverage: 8.2,
          ),
        ],
      },
      client,
    );
    final resolver = _buildResolver(
      moviesRemote: movieRemote,
      tvRemote: _FakeTvRemote({}, client),
      client: client,
    );

    final id = await resolver.searchTmdbIdByTitleForMovie(
      title: '|FR| Top Gun Maverick 2022 4K MULTI (HDR10)',
      language: 'fr',
    );

    expect(id, 1);
    expect(movieRemote.queries, contains('Top Gun Maverick'));
  });

  test('movie resolver prefers year match when scores are close', () async {
    final client = _buildClient();
    final movieRemote = _FakeMovieRemote(
      {
        'The Batman': [
          TmdbMovieSummaryDto(
            id: 10,
            title: 'The Batman',
            posterPath: null,
            backdropPath: null,
            releaseDate: '1989-01-01',
            voteAverage: 7.1,
          ),
          TmdbMovieSummaryDto(
            id: 20,
            title: 'The Batman',
            posterPath: null,
            backdropPath: null,
            releaseDate: '2022-03-01',
            voteAverage: 7.9,
          ),
        ],
      },
      client,
    );
    final resolver = _buildResolver(
      moviesRemote: movieRemote,
      tvRemote: _FakeTvRemote({}, client),
      client: client,
    );

    final id = await resolver.searchTmdbIdByTitleForMovie(
      title: 'The Batman 2022 VOSTFR 2160p',
      language: 'fr',
    );

    expect(id, 20);
  });

  test('tv resolver uses cleaned candidates', () async {
    final client = _buildClient();
    final tvRemote = _FakeTvRemote(
      {
        'Breaking Bad': [
          TmdbTvSummaryDto(
            id: 99,
            name: 'Breaking Bad',
            posterPath: null,
            backdropPath: null,
            firstAirDate: '2008-01-20',
            voteAverage: 9.0,
          ),
        ],
      },
      client,
    );
    final resolver = _buildResolver(
      moviesRemote: _FakeMovieRemote({}, client),
      tvRemote: tvRemote,
      client: client,
    );

    final id = await resolver.searchTmdbIdByTitleForTv(
      title: 'Breaking Bad 2008 4K MULTI',
      language: 'fr',
    );

    expect(id, 99);
    expect(tvRemote.queries, contains('Breaking Bad'));
  });
}

TmdbClient _buildClient() {
  final endpoints = NetworkEndpoints(
    restBaseUrl: 'https://example.com',
    imageBaseUrl: 'https://example.com',
    tmdbApiKey: 'test',
  );
  final executor = NetworkExecutor(Dio());
  return TmdbClient(executor: executor, endpoints: endpoints);
}

TmdbIdResolverService _buildResolver({
  required TmdbMovieRemoteDataSource moviesRemote,
  required TmdbTvRemoteDataSource tvRemote,
  required TmdbClient client,
}) {
  return TmdbIdResolverService(
    moviesRemote: moviesRemote,
    tvRemote: tvRemote,
    tmdbClient: client,
    similarity: _FakeSimilarityService(),
    logger: _FakeLogger(),
  );
}

class _FakeSimilarityService implements SimilarityService {
  @override
  double score(String original, String result) {
    final o = _normalize(original);
    final r = _normalize(result);
    if (o == r) return 1.0;
    if (o.isEmpty || r.isEmpty) return 0.0;
    if (o.contains(r) || r.contains(o)) return 0.7;
    return 0.2;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }
}

class _FakeLogger extends AppLogger {
  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

class _FakeMovieRemote extends TmdbMovieRemoteDataSource {
  _FakeMovieRemote(this._results, TmdbClient client) : super(client);

  final Map<String, List<TmdbMovieSummaryDto>> _results;
  final List<String> queries = <String>[];

  @override
  Future<List<TmdbMovieSummaryDto>> searchMovies(
    String query, {
    int page = 1,
    String? language,
    CancelToken? cancelToken,
  }) async {
    queries.add(query);
    return _results[query] ?? const <TmdbMovieSummaryDto>[];
  }
}

class _FakeTvRemote extends TmdbTvRemoteDataSource {
  _FakeTvRemote(this._results, TmdbClient client) : super(client);

  final Map<String, List<TmdbTvSummaryDto>> _results;
  final List<String> queries = <String>[];

  @override
  Future<List<TmdbTvSummaryDto>> searchShows(
    String query, {
    int page = 1,
    String? language,
    CancelToken? cancelToken,
    int retries = 1,
  }) async {
    queries.add(query);
    return _results[query] ?? const <TmdbTvSummaryDto>[];
  }
}
