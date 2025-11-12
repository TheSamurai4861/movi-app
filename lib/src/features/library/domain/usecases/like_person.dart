import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/core/storage/storage.dart';

class LikePerson {
  const LikePerson(this._watchlist);

  final WatchlistLocalRepository _watchlist;

  Future<void> call({
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
}
