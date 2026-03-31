import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/shared/data/services/parental_tmdb_metadata_resolvers.dart';

void main() {
  group('SharedMovieMetadataResolverAdapter', () {
    test('retourne null quand le titre est vide', () async {
      final resolver = SharedMovieMetadataResolverAdapter(
        logger: _FakeLogger(),
        resolveMovieTmdbIdByTitle: (_) async => 42,
      );

      final result = await resolver.resolveByTitle('   ');

      expect(result, isNull);
    });

    test('retourne une résolution quand un tmdb id est trouvé', () async {
      final resolver = SharedMovieMetadataResolverAdapter(
        logger: _FakeLogger(),
        resolveMovieTmdbIdByTitle: (_) async => 603,
      );

      final result = await resolver.resolveByTitle('the matrix');

      expect(result, isNotNull);
      expect(result!.tmdbId, 603);
      expect(result.matchedTitle, 'the matrix');
    });
  });

  group('SharedSeriesMetadataResolverAdapter', () {
    test('retourne null quand le titre est vide', () async {
      final resolver = SharedSeriesMetadataResolverAdapter(
        logger: _FakeLogger(),
        resolveSeriesTmdbIdByTitle: (_) async => 1396,
      );

      final result = await resolver.resolveByTitle('   ');

      expect(result, isNull);
    });

    test('retourne une résolution quand un tmdb id est trouvé', () async {
      final resolver = SharedSeriesMetadataResolverAdapter(
        logger: _FakeLogger(),
        resolveSeriesTmdbIdByTitle: (_) async => 1396,
      );

      final result = await resolver.resolveByTitle('breaking bad');

      expect(result, isNotNull);
      expect(result!.tmdbId, 1396);
      expect(result.matchedTitle, 'breaking bad');
    });
  });
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
