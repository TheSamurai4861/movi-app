import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/person/data/repositories/person_repository_impl.dart';
import 'package:movi/src/features/person/data/datasources/tmdb_person_remote_data_source.dart';
import 'package:movi/src/features/person/data/datasources/person_local_data_source.dart';
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';
import 'package:movi/src/features/person/domain/entities/person.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';

import '../../../helpers/in_memory_content_cache.dart';

class _FakePersonRemote implements TmdbPersonRemoteDataSource {
  _FakePersonRemote(this.detail);

  TmdbPersonDetailDto detail;
  bool shouldThrow = false;
  int fetchCount = 0;

  @override
  Future<TmdbPersonDetailDto> fetchPerson(int id) async {
    fetchCount += 1;
    if (shouldThrow) throw Exception('network');
    return detail;
  }

  @override
  Future<List<TmdbPersonDetailDto>> searchPeople(String query) async => [detail];
}

void main() {
  group('PersonRepositoryImpl', () {
    late InMemoryContentCacheRepository cache;
    late PersonLocalDataSource local;
    late _FakePersonRemote remote;
    late PersonRepository repo;

    setUp(() {
      cache = InMemoryContentCacheRepository();
      local = PersonLocalDataSource(cache, LocalePreferences());
      remote = _FakePersonRemote(
        TmdbPersonDetailDto(
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
        ),
      );
      repo = PersonRepositoryImpl(remote, const TmdbImageResolver(), local);
    });

    test('returns cached person when present (no remote call)', () async {
      await local.savePersonDetail(remote.detail);
      final person = await repo.getPerson(const PersonId('287'));
      expect(person.name.value, 'Brad Pitt');
      expect(remote.fetchCount, 0);
    });

    test('falls back to cache when remote fails but cache exists', () async {
      // Prime cache
      await local.savePersonDetail(remote.detail);
      // Simulate network failure
      remote.shouldThrow = true;
      final person = await repo.getPerson(const PersonId('287'));
      expect(person.name.value, 'Brad Pitt');
      expect(remote.fetchCount, 0); // no remote call because cache short-circuits
    });

    test('fetches remote and saves to cache when missing', () async {
      final person = await repo.getPerson(const PersonId('287'));
      expect(person, isA<Person>());
      expect(remote.fetchCount, 1);
      final cached = await local.getPersonDetail(287);
      expect(cached, isNotNull);
    });

    test('throws when remote fails and no cache', () async {
      remote.shouldThrow = true;
      expect(() => repo.getPerson(const PersonId('287')), throwsA(isA<Exception>()));
    });

    test('search people maps list', () async {
      final results = await repo.searchPeople('brad');
      expect(results, isNotEmpty);
      expect(results.first.name, 'Brad Pitt');
    });
  });
}
