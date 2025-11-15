import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/features/library/domain/repositories/favorites_repository.dart';

class UnlikePerson {
  const UnlikePerson(this._favorites);

  final FavoritesRepository _favorites;

  Future<void> call(PersonId id) async {
    await _favorites.unlikePerson(id);
  }
}
