import 'package:movi/src/shared/domain/value_objects/media_id.dart';

abstract class FavoritesRepository {
  Future<void> likePerson({
    required PersonId id,
    required String name,
    Uri? photo,
  });

  Future<void> unlikePerson(PersonId id);
}
