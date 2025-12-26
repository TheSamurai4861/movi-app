import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/features/library/domain/repositories/favorites_repository.dart';

class LikePerson {
  const LikePerson(this._favorites);

  final FavoritesRepository _favorites;

  Future<void> call({
    required PersonId id,
    required String name,
    Uri? photo,
  }) async {
    await _favorites.likePerson(id: id, name: name, photo: photo);
  }
}
