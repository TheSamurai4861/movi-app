import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/person/domain/entities/person.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';
import 'package:movi/src/features/person/domain/usecases/get_person_filmography.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';

class FakeFilmographyRepository implements PersonRepository {
  List<PersonCredit> credits = const <PersonCredit>[];
  Object? error;

  @override
  Future<List<PersonCredit>> getFilmography(PersonId id) async {
    if (error != null) throw error!;
    return credits;
  }

  @override
  Future<Person> getPerson(PersonId id) async {
    throw UnimplementedError();
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
  group('GetPersonFilmography (Domain)', () {
    test('returns filmography with correct types and years', () async {
      final repo = FakeFilmographyRepository();
      repo.credits = <PersonCredit>[
        PersonCredit(
          reference: ContentReference(
            id: 'm1',
            title: MediaTitle('A Movie'),
            type: ContentType.movie,
            poster: null,
          ),
          role: 'Lead',
          year: 2001,
        ),
        PersonCredit(
          reference: ContentReference(
            id: 's1',
            title: MediaTitle('A Show'),
            type: ContentType.series,
            poster: null,
          ),
          role: 'Director',
          year: 2015,
        ),
      ];
      final usecase = GetPersonFilmography(repo);

      final result = await usecase(PersonId('any'));
      expect(result.length, 2);
      expect(result.first.reference.type, ContentType.movie);
      expect(result.last.reference.type, ContentType.series);
      expect(result.first.year, 2001);
      expect(result.last.year, 2015);
    });

    test('rethrows repository errors', () async {
      final repo = FakeFilmographyRepository()..error = Exception('repo-failure');
      final usecase = GetPersonFilmography(repo);

      expect(() => usecase(PersonId('err')), throwsA(isA<Exception>()));
    });
  });
}