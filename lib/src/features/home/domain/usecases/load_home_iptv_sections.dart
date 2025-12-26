import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';

class LoadHomeIptvSections {
  const LoadHomeIptvSections(this._repo);

  final HomeFeedRepository _repo;

  Future<Result<Map<String, List<ContentReference>>, Failure>> call({
    int? itemLimitPerPlaylist,
  }) =>
      _repo.getIptvCategoryLists(itemLimitPerPlaylist: itemLimitPerPlaylist);
}
