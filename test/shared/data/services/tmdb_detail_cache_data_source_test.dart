import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_season_detail_dto.dart';
import 'package:movi/src/shared/data/services/tmdb_detail_cache_data_source.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> openTestDb() async {
    final db = await openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE content_cache (
        cache_key TEXT PRIMARY KEY,
        cache_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    return db;
  }

  test('returns fresh movie detail payload within ttl', () async {
    final db = await openTestDb();
    addTearDown(() async => db.close());

    final repo = ContentCacheRepository(db);
    final cache = TmdbDetailCacheDataSource(repo);

    await cache.putMovieDetailFull(
      TmdbMovieDetailDto(
        id: 1,
        title: 'Movie',
        overview: 'Overview',
        posterPath: '/poster.jpg',
        backdropPath: '/backdrop.jpg',
        logoPath: '/logo.png',
        releaseDate: '2024-01-01',
        runtime: 120,
        voteAverage: 7.5,
        genres: const <String>['Action'],
        cast: const <TmdbMovieCastDto>[],
        directors: const <TmdbMovieCrewDto>[],
        recommendations: const <TmdbMovieSummaryDto>[],
      ),
      language: 'fr-FR',
    );

    final result = await cache.getCachedMovieDetailFull(
      movieId: 1,
      language: 'fr-FR',
    );

    expect(result.isFresh, isTrue);
    expect(result.value?.title, 'Movie');
  });

  test('returns stale movie recommendations without deleting them', () async {
    final db = await openTestDb();
    addTearDown(() async => db.close());

    final repo = ContentCacheRepository(db);
    final cache = TmdbDetailCacheDataSource(repo);

    await cache.putMovieRecommendations(
      <TmdbMovieSummaryDto>[
        TmdbMovieSummaryDto(
          id: 2,
          title: 'Reco',
          posterPath: '/reco.jpg',
          backdropPath: null,
          releaseDate: '2024-01-02',
          voteAverage: 6.2,
        ),
      ],
      movieId: 1,
      language: 'fr-FR',
    );

    await db.update(
      'content_cache',
      <String, Object?>{
        'updated_at': DateTime.now()
            .subtract(const Duration(hours: 30))
            .millisecondsSinceEpoch,
      },
    );

    final result = await cache.getCachedMovieRecommendations(
      movieId: 1,
      language: 'fr-FR',
    );

    expect(result.isStale, isTrue);
    expect(result.value, isNotNull);
    expect(result.value!.single.title, 'Reco');
    expect(
      await repo.getEntry('tmdb_movie_recommendations_1_fr-FR'),
      isNotNull,
    );
  });

  test('uses archive ttl for old seasons', () async {
    final db = await openTestDb();
    addTearDown(() async => db.close());

    final repo = ContentCacheRepository(db);
    final cache = TmdbDetailCacheDataSource(repo);

    await cache.putTvSeasonDetail(
      TmdbTvSeasonDetailDto(
        id: 10,
        name: 'Season 1',
        airDate: '2020-01-01',
        episodes: <TmdbTvEpisodeDto>[
          TmdbTvEpisodeDto(
            id: 11,
            name: 'Episode 1',
            airDate: '2020-01-10',
            voteAverage: 7,
            runtime: 42,
            stillPath: null,
            overview: 'Old episode',
            episodeNumber: 1,
          ),
        ],
      ),
      showId: 5,
      seasonNumber: 1,
      language: 'fr-FR',
    );

    await db.update(
      'content_cache',
      <String, Object?>{
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch,
      },
    );

    final result = await cache.getCachedTvSeasonDetail(
      showId: 5,
      seasonNumber: 1,
      language: 'fr-FR',
    );

    expect(result.isFresh, isTrue);
    expect(result.value?.episodes.single.name, 'Episode 1');
  });
}
