import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/features/person/data/datasources/person_local_data_source.dart';
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';

import '../../../helpers/in_memory_content_cache.dart';

void main() {
  group('PersonLocalDataSource', () {
    late ContentCacheRepository cache;
    late LocalePreferences prefs;
    late PersonLocalDataSource local;

    setUp(() {
      cache = InMemoryContentCacheRepository();
      prefs = LocalePreferences();
      local = PersonLocalDataSource(cache, prefs);
    });

    TmdbPersonDetailDto makeDto() => TmdbPersonDetailDto(
          id: 287,
          name: 'Brad Pitt',
          biography: 'Bio',
          profilePath: '/brad.jpg',
          birthDate: '1963-12-18',
          deathDate: null,
          placeOfBirth: 'Shawnee, USA',
          roles: const ['Acting'],
          credits: [
            TmdbPersonCreditDto(
              id: 550,
              mediaType: 'movie',
              title: 'Fight Club',
              posterPath: '/fc.jpg',
              character: 'Tyler Durden',
              job: null,
              releaseDate: '1999-10-15',
            ),
          ],
        );

    test('save and read person detail', () async {
      final dto = makeDto();
      await local.savePersonDetail(dto);
      final read = await local.getPersonDetail(287);
      expect(read, isNotNull);
      expect(read!.name, 'Brad Pitt');
      expect(read.credits, isNotEmpty);
    });

    test('returns null when cache is empty', () async {
      final read = await local.getPersonDetail(1);
      expect(read, isNull);
    });
  });
}
