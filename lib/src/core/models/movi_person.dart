import 'package:equatable/equatable.dart';

class MoviPerson extends Equatable {
  const MoviPerson({
    required this.id,
    required this.name,
    required this.role,
    this.poster,
  });

  final String id;
  final String name;
  final String role;
  final Uri? poster;

  MoviPerson copyWith({
    String? id,
    String? name,
    String? role,
    Uri? poster,
    bool removePoster = false,
  }) {
    return MoviPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      poster: removePoster ? null : poster ?? this.poster,
    );
  }

  @override
  List<Object?> get props => [id, name, role, poster];

  @override
  String toString() =>
      'MoviPerson(id: $id, name: $name, role: $role, '
      'poster: ${poster?.toString() ?? "-"})';
}
