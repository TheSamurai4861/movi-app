import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/tv/data/services/series_metadata_resolver_adapter.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

void main() {
  group('SeriesMetadataResolverAdapter', () {
    test('retourne null quand le titre demandé est vide', () async {
      final repository = _FakeTvRepository();
      final resolver = SeriesMetadataResolverAdapter(
        repository: repository,
        logger: _FakeLogger(),
      );

      final result = await resolver.resolveByTitle('   ');

      expect(result, isNull);
      expect(repository.lastQuery, isNull);
    });

    test(
      'retourne null quand la recherche ne renvoie aucun résultat',
      () async {
        final repository = _FakeTvRepository(
          searchResults: const <TvShowSummary>[],
        );
        final resolver = SeriesMetadataResolverAdapter(
          repository: repository,
          logger: _FakeLogger(),
        );

        final result = await resolver.resolveByTitle('breaking bad');

        expect(result, isNull);
        expect(repository.lastQuery, 'breaking bad');
      },
    );
  });
}

class _FakeTvRepository implements TvRepository {
  _FakeTvRepository({this.searchResults = const <TvShowSummary>[]});

  final List<TvShowSummary> searchResults;
  String? lastQuery;

  @override
  Future<List<TvShowSummary>> searchShows(String query) async {
    lastQuery = query;
    return searchResults;
  }

  @override
  Future<TvShow> getShow(SeriesId id) {
    throw UnimplementedError();
  }

  @override
  Future<TvShow> getShowLite(SeriesId id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Season>> getSeasons(SeriesId id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId) {
    throw UnimplementedError();
  }

  @override
  Future<List<TvShowSummary>> getFeaturedShows() {
    throw UnimplementedError();
  }

  @override
  Future<List<TvShowSummary>> getUserWatchlist() {
    throw UnimplementedError();
  }

  @override
  Future<List<TvShowSummary>> getContinueWatching() {
    throw UnimplementedError();
  }

  @override
  Future<bool> isInWatchlist(SeriesId id) {
    throw UnimplementedError();
  }

  @override
  Future<void> setWatchlist(SeriesId id, {required bool saved}) {
    throw UnimplementedError();
  }

  @override
  Future<void> refreshMetadata(SeriesId id) {
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
