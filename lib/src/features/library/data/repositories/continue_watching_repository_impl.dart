import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';

class ContinueWatchingRepositoryImpl implements ContinueWatchingRepository {
  const ContinueWatchingRepositoryImpl(this._local);
  final ContinueWatchingLocalRepository _local;

  @override
  Future<void> remove(String contentId, ContentType type) {
    return _local.remove(contentId, type);
  }
}
