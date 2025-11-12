import 'package:movi/src/features/iptv/domain/entities/xtream_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';

class RefreshXtreamCatalog {
  const RefreshXtreamCatalog(this._repository);

  final IptvRepository _repository;

  Future<Result<XtreamCatalogSnapshot, Failure>> call(String accountId) {
    return _repository
        .refreshCatalog(accountId)
        .then<Result<XtreamCatalogSnapshot, Failure>>((value) => Ok(value))
        .catchError(
          (error) => Err<XtreamCatalogSnapshot, Failure>(error as Failure),
        );
  }
}
