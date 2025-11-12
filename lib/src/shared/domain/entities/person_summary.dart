import 'package:equatable/equatable.dart';

import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class PersonSummary extends Equatable {
  const PersonSummary({
    required this.id,
    this.tmdbId,
    required this.name,
    this.role,
    this.photo,
  });

  final PersonId id;
  final int? tmdbId;
  final String name;
  final String? role;
  final Uri? photo;

  @override
  List<Object?> get props => [id, tmdbId, name, role, photo];
}
