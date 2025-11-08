import 'package:movi/src/core/storage/repositories/continue_watching_local_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class FakeContinueWatchingLocalRepository implements ContinueWatchingLocalRepository {
  @override
  Future<List<ContinueWatchingEntry>> readAll(ContentType type) async => const [];

  @override
  Future<void> remove(String contentId, ContentType type) async {}

  @override
  Future<void> upsert(ContinueWatchingEntry entry) async {}
}

