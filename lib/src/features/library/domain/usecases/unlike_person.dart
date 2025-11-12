import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/core/storage/storage.dart';

class UnlikePerson {
  const UnlikePerson(this._watchlist);

  final WatchlistLocalRepository _watchlist;

  Future<void> call(PersonId id) async {
    await _watchlist.remove(id.value, ContentType.person);
  }
}
