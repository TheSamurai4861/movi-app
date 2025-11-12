import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_catalog_snapshot.dart';

class XtreamCacheDataSource {
  XtreamCacheDataSource(IptvLocalRepository _, ContentCacheRepository __);

  static const Object snapshotPolicy = 'default';

  Future<XtreamCatalogSnapshot?> getSnapshot(
    String accountId, {
    Object? policy,
  }) async {
    return null;
  }
}
