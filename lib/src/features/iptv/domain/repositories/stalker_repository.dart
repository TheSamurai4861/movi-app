 import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';

abstract class StalkerRepository {
  Future<StalkerAccount> addSource({
    required StalkerEndpoint endpoint,
    required String macAddress,
    String? username,
    String? password,
    required String alias,
  });

  Future<StalkerCatalogSnapshot> refreshCatalog(String accountId);

  Future<List<XtreamPlaylist>> listPlaylists(String accountId);
}

