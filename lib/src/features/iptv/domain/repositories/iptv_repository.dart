import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';

abstract class IptvRepository {
  Future<XtreamAccount> addSource({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
    required String alias,
    String preferredRouteProfileId,
    List<String> fallbackRouteProfileIds,
  });

  Future<XtreamCatalogSnapshot> refreshCatalog(String accountId);

  Future<List<XtreamPlaylist>> listPlaylists(String accountId);
}
