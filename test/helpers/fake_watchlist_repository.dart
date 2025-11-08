import 'package:movi/src/core/storage/repositories/watchlist_local_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class FakeWatchlistLocalRepository implements WatchlistLocalRepository {
  @override
  Future<bool> exists(String contentId, ContentType type) async => false;

  @override
  Future<List<WatchlistEntry>> readAll(ContentType type) async => const [];

  @override
  Future<void> remove(String contentId, ContentType type) async {}

  @override
  Future<void> upsert(WatchlistEntry entry) async {}
}
