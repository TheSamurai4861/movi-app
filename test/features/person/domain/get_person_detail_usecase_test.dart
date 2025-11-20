import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/person/domain/entities/person.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';
import 'package:movi/src/features/person/domain/usecases/get_person_detail.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';

class FakePersonRepository implements PersonRepository {
  Person? person;
  Object? error;

  @override
  Future<Person> getPerson(PersonId id) async {
    if (error != null) throw error!;
    return person!;
  }

  @override
  Future<List<PersonCredit>> getFilmography(PersonId id) async {
    return const <PersonCredit>[];
  }

  @override
  Future<List<PersonSummary>> searchPeople(String query) async {
    return const <PersonSummary>[];
  }

  @override
  Future<List<PersonSummary>> getFeaturedPeople() async {
    return const <PersonSummary>[];
  }
}

void main() {
  group('GetPersonDetail (Domain)', () {
    test('returns a complete Person on success', () async {
      final repo = FakePersonRepository();
      repo.person = Person(
        id: PersonId('123'),
        tmdbId: 123,
        name: MediaTitle('Jane Doe'),
        biography: 'Bio',
        photo: null,
        birthDate: null,
        deathDate: null,
        placeOfBirth: 'Paris',
        roles: const <String>['Actor'],
        filmography: const <PersonCredit>[],
      );
      final usecase = GetPersonDetail(repo);

      final result = await usecase(PersonId('123'));
      expect(result.name.value, 'Jane Doe');
      expect(result.placeOfBirth, 'Paris');
      expect(result.roles, contains('Actor'));
    });

    test('rethrows repository errors', () async {
      final repo = FakePersonRepository()..error = Exception('repo-failure');
      final usecase = GetPersonDetail(repo);

      expect(() => usecase(PersonId('999')), throwsA(isA<Exception>()));
    });
  });
}