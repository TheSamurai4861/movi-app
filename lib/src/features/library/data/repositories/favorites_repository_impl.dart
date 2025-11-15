import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/library/domain/repositories/favorites_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._watchlist);

  final WatchlistLocalRepository _watchlist;

  @override
  Future<void> likePerson({
    required PersonId id,
    required String name,
    Uri? photo,
  }) async {
    await _watchlist.upsert(
      WatchlistEntry(
        contentId: id.value,
        type: ContentType.person,
        title: name,
        poster: photo,
        addedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> unlikePerson(PersonId id) async {
    await _watchlist.remove(id.value, ContentType.person);
  }
}
