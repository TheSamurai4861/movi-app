import 'package:movi/src/features/iptv/domain/entities/xtream_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';

class RefreshXtreamCatalog {
  const RefreshXtreamCatalog(this._repository);

  final IptvRepository _repository;

  Future<Result<XtreamCatalogSnapshot, Failure>> call(String accountId) async {
    try {
      final snapshot = await _repository.refreshCatalog(accountId);
      return Ok(snapshot);
    } on Failure catch (failure) {
      return Err(failure);
    } catch (error, stack) {
      return Err(
        Failure.fromException(
          error,
          stackTrace: stack,
          code: 'iptv_refresh_catalog',
          context: {'accountId': accountId},
        ),
      );
    }
  }
}
