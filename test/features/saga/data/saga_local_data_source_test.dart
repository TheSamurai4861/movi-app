import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/features/saga/data/datasources/saga_local_data_source.dart';
import 'package:movi/src/features/saga/data/dtos/tmdb_saga_detail_dto.dart';

import '../../../helpers/database_initializer.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  test('save and read saga detail from local cache', () async {
    final cache = ContentCacheRepository();
    final prefs = LocalePreferences();
    final local = SagaLocalDataSource(cache, prefs);

    final dto = TmdbSagaDetailDto(
      id: 10,
      name: 'Star Wars Collection',
      overview: 'A long time ago in a galaxy far, far away...',
      posterPath: '/poster.jpg',
      backdropPath: '/backdrop.jpg',
      parts: [
        TmdbSagaPartDto(
          id: 11,
          title: 'A New Hope',
          posterPath: '/p1.jpg',
          releaseDate: '1977-05-25',
          voteAverage: 8.2,
          runtime: 121,
        ),
      ],
    );

    await local.saveSagaDetail(dto);
    final read = await local.getSagaDetail(10);

    expect(read, isNotNull);
    expect(read!.id, 10);
    expect(read.parts.length, 1);
    expect(read.parts.first.runtime, 121);
  });
}

