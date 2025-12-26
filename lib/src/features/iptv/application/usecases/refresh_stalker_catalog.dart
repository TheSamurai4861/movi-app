import 'package:movi/src/features/iptv/domain/entities/stalker_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/repositories/stalker_repository.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';

class RefreshStalkerCatalog {
  const RefreshStalkerCatalog(this._repository);

  final StalkerRepository _repository;

  Future<Result<StalkerCatalogSnapshot, Failure>> call(String accountId) async {
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
          code: 'stalker_refresh_catalog',
          context: {'accountId': accountId},
        ),
      );
    }
  }
}

