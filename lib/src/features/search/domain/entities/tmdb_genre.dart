import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class TmdbGenre {
  const TmdbGenre({required this.id, required this.name, required this.type});

  final int id;
  final String name;
  final ContentType type;
}

class TmdbGenres {
  const TmdbGenres({required this.movie, required this.series});

  final List<TmdbGenre> movie;
  final List<TmdbGenre> series;
}
