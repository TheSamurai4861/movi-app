import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class LoadHomeIptvSections {
  const LoadHomeIptvSections(this._repo);

  final HomeFeedRepository _repo;

  Future<Map<String, List<ContentReference>>> call() => _repo.getIptvCategoryLists();
}