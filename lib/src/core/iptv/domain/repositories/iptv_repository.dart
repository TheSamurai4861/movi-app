import '../entities/xtream_account.dart';
import '../entities/xtream_catalog_snapshot.dart';
import '../entities/xtream_playlist.dart';
import '../value_objects/xtream_endpoint.dart';

abstract class IptvRepository {
  Future<List<XtreamAccount>> getAccounts();

  Future<XtreamAccount> addSource({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
    required String alias,
  });

  Future<void> removeSource(String accountId);

  Future<XtreamCatalogSnapshot> refreshCatalog(String accountId);

  Future<List<XtreamPlaylist>> listPlaylists(String accountId);
}
