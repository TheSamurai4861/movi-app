import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/core/storage/services/cache_policy.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/config/models/network_endpoints.dart';

import 'package:movi/src/features/person/data/datasources/person_local_data_source.dart';
import 'package:movi/src/features/person/data/datasources/tmdb_person_remote_data_source.dart';
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';
import 'package:movi/src/features/person/data/repositories/person_repository_impl.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class InMemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    return _store[key];
  }

  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}

class FakeContentCacheRepository extends ContentCacheRepository {
  final Map<String, Map<String, dynamic>> _payloads = <String, Map<String, dynamic>>{};
  final Map<String, DateTime> _updated = <String, DateTime>{};

  @override
  Future<void> put({required String key, required String type, required Map<String, dynamic> payload}) async {
    _payloads[key] = payload;
    _updated[key] = DateTime.now();
  }

  @override
  Future<Map<String, dynamic>?> get(String key, {CachePolicy? policy}) async {
    final payload = _payloads[key];
    if (payload == null) return null;
    if (policy != null) {
      final updatedAt = _updated[key] ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (policy.isExpired(updatedAt)) {
        _payloads.remove(key);
        _updated.remove(key);
        return null;
      }
    }
    return payload;
  }

  @override
  Future<Map<String, dynamic>?> getWithPolicy(String key, CachePolicy policy) async {
    return get(key, policy: policy);
  }

  // Test helper to seed expired entries
  Future<void> seedExpired({required String key, required Map<String, dynamic> payload, required Duration age}) async {
    _payloads[key] = payload;
    _updated[key] = DateTime.now().subtract(age);
  }
}

class StubRemote extends TmdbPersonRemoteDataSource {
  StubRemote() : super(
    TmdbClient(
      executor: NetworkExecutor(Dio()),
      endpoints: const NetworkEndpoints(restBaseUrl: 'http://localhost', imageBaseUrl: 'http://localhost'),
    ),
  );

  int fetchCount = 0;
  List<TmdbPersonDetailDto> searchResults = const <TmdbPersonDetailDto>[];
  List<TmdbPersonDetailDto> popularResults = const <TmdbPersonDetailDto>[];
  late TmdbPersonDetailDto personDetail;

  @override
  Future<TmdbPersonDetailDto> fetchPerson(int id, {String? language}) async {
    fetchCount += 1;
    return personDetail;
  }

  @override
  Future<List<TmdbPersonDetailDto>> searchPeople(String query, {String? language}) async {
    return searchResults;
  }

  @override
  Future<List<TmdbPersonDetailDto>> popularPeople({String? language, int page = 1}) async {
    return popularResults;
  }
}

void main() {
  group('PersonRepositoryImpl (Data)', () {
    late InMemorySecureStorage storage;
    late LocalePreferences prefs;
    late FakeContentCacheRepository cache;
    late StubRemote remote;
    late TmdbImageResolver images;
    late PersonLocalDataSource local;
    late PersonRepositoryImpl repo;

    setUp(() async {
      storage = InMemorySecureStorage();
      prefs = await LocalePreferences.create(storage: storage, defaultLanguageCode: 'fr-FR');
      cache = FakeContentCacheRepository();
      remote = StubRemote();
      images = const TmdbImageResolver();
      local = PersonLocalDataSource(cache, prefs);
      repo = PersonRepositoryImpl(remote, images, local, prefs);
    });

    test('maps TmdbPersonDetailDto to Person with null biography when empty', () async {
      final dto = TmdbPersonDetailDto(
        id: 42,
        name: 'Jane Doe',
        biography: '',
        profilePath: '/poster.jpg',
        birthDate: '1980-01-01',
        deathDate: null,
        placeOfBirth: 'Paris',
        roles: <String>['Actress', 'Director'],
        credits: <TmdbPersonCreditDto>[
          TmdbPersonCreditDto(
            id: 10,
            mediaType: 'movie',
            title: 'A Movie',
            posterPath: '/m.jpg',
            character: 'Lead',
            job: null,
            releaseDate: '2000-05-01',
          ),
          TmdbPersonCreditDto(
            id: 20,
            mediaType: 'tv',
            title: 'A Show',
            posterPath: '/s.jpg',
            character: null,
            job: 'Director',
            releaseDate: '2010-01-05',
          ),
        ],
      );
      remote.personDetail = dto;

      final person = await repo.getPerson(PersonId('42'));
      expect(person.id.value, '42');
      expect(person.name.value, 'Jane Doe');
      expect(person.biography, isNull);
      expect(person.photo, images.poster('/poster.jpg'));
      expect(person.birthDate, DateTime(1980, 1, 1));
      expect(person.deathDate, isNull);
      expect(person.placeOfBirth, 'Paris');
      expect(person.roles, containsAll(<String>['Actress', 'Director']));

      // Filmography mapping
      expect(person.filmography.length, 2);
      final movie = person.filmography.firstWhere((c) => c.reference.type == ContentType.movie);
      final show = person.filmography.firstWhere((c) => c.reference.type == ContentType.series);
      expect(movie.reference.title.value, 'A Movie');
      expect(movie.reference.poster, images.poster('/m.jpg'));
      expect(movie.year, 2000);
      expect(movie.role, 'Lead');
      expect(show.reference.title.value, 'A Show');
      expect(show.reference.poster, images.poster('/s.jpg'));
      expect(show.year, 2010);
      expect(show.role, 'Director');
    });

    test('uses local cache after first fetch (CachePolicy valid)', () async {
      final dto = TmdbPersonDetailDto(
        id: 99,
        name: 'Cached Person',
        biography: 'Bio',
        profilePath: '/p.jpg',
        birthDate: null,
        deathDate: null,
        placeOfBirth: null,
        roles: const <String>[],
        credits: const <TmdbPersonCreditDto>[],
      );
      remote.personDetail = dto;

      final first = await repo.getPerson(PersonId('99'));
      final second = await repo.getPerson(PersonId('99'));

      expect(remote.fetchCount, 1, reason: 'Second call should hit cache');
      expect(first.name.value, 'Cached Person');
      expect(second.name.value, 'Cached Person');
    });

    test('expired cache triggers remote fetch and overwrites cache', () async {
      final dto = TmdbPersonDetailDto(
        id: 7,
        name: 'Fresh Person',
        biography: 'x',
        profilePath: null,
        birthDate: null,
        deathDate: null,
        placeOfBirth: null,
        roles: const <String>[],
        credits: const <TmdbPersonCreditDto>[],
      );
      remote.personDetail = dto;

      // Seed expired cache entry
      final prefs2 = await LocalePreferences.create(storage: storage, defaultLanguageCode: 'fr-FR');
      final key = 'person_detail_${prefs2.languageCode}_7';
      await cache.seedExpired(key: key, payload: dto.toCache(), age: const Duration(days: 10));

      final person = await repo.getPerson(PersonId('7'));
      expect(remote.fetchCount, 1, reason: 'Expired cache should fetch remote');
      expect(person.name.value, 'Fresh Person');
    });

    test('popularPeople maps to PersonSummary with resolved photo', () async {
      remote.popularResults = <TmdbPersonDetailDto>[
        TmdbPersonDetailDto(
          id: 1,
          name: 'Pop One',
          biography: '',
          profilePath: '/face.png',
          birthDate: null,
          deathDate: null,
          placeOfBirth: null,
          roles: const <String>[],
          credits: const <TmdbPersonCreditDto>[],
        ),
        TmdbPersonDetailDto(
          id: 2,
          name: 'Pop Two',
          biography: '',
          profilePath: 'https://example.com/abs.jpg',
          birthDate: null,
          deathDate: null,
          placeOfBirth: null,
          roles: const <String>[],
          credits: const <TmdbPersonCreditDto>[],
        ),
      ];

      final list = await repo.getFeaturedPeople();
      expect(list.length, 2);
      expect(list[0].name, 'Pop One');
      expect(list[0].photo, images.poster('/face.png'));
      expect(list[1].photo?.toString(), 'https://example.com/abs.jpg');
    });

    test('searchPeople maps minimal DTO to PersonSummary', () async {
      remote.searchResults = <TmdbPersonDetailDto>[
        TmdbPersonDetailDto(
          id: 11,
          name: 'Query A',
          biography: '',
          profilePath: '/qa.jpg',
          birthDate: null,
          deathDate: null,
          placeOfBirth: null,
          roles: const <String>[],
          credits: const <TmdbPersonCreditDto>[],
        ),
      ];

      final list = await repo.searchPeople('qa');
      expect(list.length, 1);
      expect(list[0].tmdbId, 11);
      expect(list[0].name, 'Query A');
      expect(list[0].photo, images.poster('/qa.jpg'));
    });
  });
}