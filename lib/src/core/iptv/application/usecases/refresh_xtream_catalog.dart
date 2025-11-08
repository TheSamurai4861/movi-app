import '../../domain/entities/xtream_catalog_snapshot.dart';
import '../../domain/repositories/iptv_repository.dart';

class RefreshXtreamCatalog {
  const RefreshXtreamCatalog(this._repository);

  final IptvRepository _repository;

  Future<XtreamCatalogSnapshot> call(String accountId) {
    return _repository.refreshCatalog(accountId);
  }
}
