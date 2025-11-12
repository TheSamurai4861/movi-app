import 'package:equatable/equatable.dart';

import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class Person extends Equatable {
  const Person({
    required this.id,
    this.tmdbId,
    required this.name,
    this.biography,
    this.photo,
    this.birthDate,
    this.deathDate,
    this.placeOfBirth,
    this.roles = const [],
    this.filmography = const [],
  });

  final PersonId id;
  final int? tmdbId;
  final MediaTitle name;
  final String? biography;
  final Uri? photo;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? placeOfBirth;
  final List<String> roles;
  final List<PersonCredit> filmography;

  @override
  List<Object?> get props => [
    id,
    tmdbId,
    name,
    biography,
    photo,
    birthDate,
    deathDate,
    placeOfBirth,
    roles,
    filmography,
  ];
}

class PersonCredit extends Equatable {
  const PersonCredit({required this.reference, this.role, this.year});

  final ContentReference reference;
  final String? role;
  final int? year;

  @override
  List<Object?> get props => [reference, role, year];
}
