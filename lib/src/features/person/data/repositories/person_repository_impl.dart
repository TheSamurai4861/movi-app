import 'package:movi/src/shared/domain/entities/person_summary.dart';

import 'package:movi/src/features/person/domain/entities/person.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/person/data/datasources/tmdb_person_remote_data_source.dart';
import 'package:movi/src/features/person/data/datasources/person_local_data_source.dart';
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';

class PersonRepositoryImpl implements PersonRepository {
  PersonRepositoryImpl(this._remote, this._images, this._local, this._locale);

  final TmdbPersonRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final PersonLocalDataSource _local;
  final LocalePreferences _locale;

  @override
  Future<Person> getPerson(PersonId id) async {
    final dto = await _loadPerson(id);
    return _mapPerson(dto);
  }

  @override
  Future<List<PersonCredit>> getFilmography(PersonId id) async {
    final dto = await _loadPerson(id);
    return dto.credits.map(_mapCredit).toList();
  }

  @override
  Future<List<PersonSummary>> searchPeople(String query) async {
    final dtos = await _remote.searchPeople(
      query,
      language: _locale.languageCode,
    );
    return dtos
        .map(
          (dto) => PersonSummary(
            id: PersonId(dto.id.toString()),
            tmdbId: dto.id,
            name: dto.name,
            photo: _images.poster(dto.profilePath),
          ),
        )
        .toList();
  }

  @override
  Future<List<PersonSummary>> getFeaturedPeople() async {
    // Previously used searchPeople('a') as a placeholder to surface some results.
    // Now backed by TMDB `person/popular` to provide real featured profiles.
    final dtos = await _remote.popularPeople(language: _locale.languageCode);
    return dtos
        .map(
          (dto) => PersonSummary(
            id: PersonId(dto.id.toString()),
            tmdbId: dto.id,
            name: dto.name,
            photo: _images.poster(dto.profilePath),
          ),
        )
        .toList();
  }

  Person _mapPerson(TmdbPersonDetailDto dto) {
    return Person(
      id: PersonId(dto.id.toString()),
      tmdbId: dto.id,
      name: MediaTitle(dto.name),
      biography: dto.biography.isEmpty ? null : dto.biography,
      photo: _images.poster(dto.profilePath),
      birthDate: _parseDate(dto.birthDate),
      deathDate: _parseDate(dto.deathDate),
      placeOfBirth: dto.placeOfBirth,
      roles: dto.roles,
      filmography: dto.credits.map(_mapCredit).toList(),
    );
  }

  PersonCredit _mapCredit(TmdbPersonCreditDto dto) {
    final type = dto.mediaType == 'tv' ? ContentType.series : ContentType.movie;
    return PersonCredit(
      reference: ContentReference(
        id: dto.id.toString(),
        title: MediaTitle(dto.title),
        type: type,
        poster: _images.poster(dto.posterPath),
      ),
      role: dto.character ?? dto.job,
      year: dto.releaseDate != null && dto.releaseDate!.isNotEmpty
          ? (DateTime.tryParse(dto.releaseDate!)?.year)
          : null,
    );
  }

  DateTime? _parseDate(String? date) =>
      date == null || date.isEmpty ? null : DateTime.tryParse(date);

  Future<TmdbPersonDetailDto> _loadPerson(PersonId id) async {
    final personId = int.parse(id.value);
    final cached = await _local.getPersonDetail(personId);
    if (cached != null) return cached;
    final remote = await _remote.fetchPerson(
      personId,
      language: _locale.languageCode,
    );
    await _local.savePersonDetail(remote);
    return remote;
  }
}
