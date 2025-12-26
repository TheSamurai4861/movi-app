import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class LoadHomeHero {
  const LoadHomeHero(this._repo);

  final HomeFeedRepository _repo;

  Future<Result<List<ContentReference>, Failure>> call() => _repo.getHeroItems();
}
