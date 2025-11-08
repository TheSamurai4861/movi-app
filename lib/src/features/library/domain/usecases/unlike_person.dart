import '../../../../shared/domain/value_objects/content_reference.dart';
import '../../../../shared/domain/value_objects/media_id.dart';
import '../../../../core/storage/repositories/watchlist_local_repository.dart';

class UnlikePerson {
  const UnlikePerson(this._watchlist);

  final WatchlistLocalRepository _watchlist;

  Future<void> call(PersonId id) async {
    await _watchlist.remove(id.value, ContentType.person);
  }
}
