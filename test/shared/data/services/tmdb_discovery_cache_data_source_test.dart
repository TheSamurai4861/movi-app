import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/shared/data/services/tmdb_discovery_cache_data_source.dart';
import 'package:movi/src/features/search/domain/entities/tmdb_genre.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

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

  test('returns fresh trending payload when within TTL', () async {
    final db = await openTestDb();
    addTearDown(() async => db.close());

    final repo = ContentCacheRepository(db);
    final cache = TmdbDiscoveryCacheDataSource(repo);

    await cache.putTrendingMovies(
      <Map<String, dynamic>>[
        <String, dynamic>{'id': 1, 'title': 'Movie'},
      ],
      language: 'fr-FR',
      sourceFingerprint: 'source-a',
    );

    final result = await cache.getCachedTrendingMovies(
      language: 'fr-FR',
      sourceFingerprint: 'source-a',
    );

    expect(result.isFresh, isTrue);
    expect(result.value, isNotNull);
    expect(result.value!.single['id'], 1);
  });

  test('returns stale genres payload without deleting it', () async {
    final db = await openTestDb();
    addTearDown(() async => db.close());

    final repo = ContentCacheRepository(db);
    final cache = TmdbDiscoveryCacheDataSource(repo);

    await cache.putGenres(
      const TmdbGenres(
        movie: <TmdbGenre>[
          TmdbGenre(id: 28, name: 'Action', type: ContentType.movie),
        ],
        series: <TmdbGenre>[
          TmdbGenre(id: 18, name: 'Drama', type: ContentType.series),
        ],
      ),
      language: 'fr-FR',
    );

    await db.update(
      'content_cache',
      <String, Object?>{
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 8))
            .millisecondsSinceEpoch,
      },
    );

    final result = await cache.getCachedGenres(language: 'fr-FR');

    expect(result.isStale, isTrue);
    expect(result.value, isNotNull);
    expect(result.value!.movie.single.name, 'Action');
    expect(await repo.getEntry('tmdb_genres_fr-FR'), isNotNull);
  });
}
