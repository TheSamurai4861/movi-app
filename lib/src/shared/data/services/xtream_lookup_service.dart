import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/shared/domain/services/xtream_lookup.dart';

class XtreamLookupService implements XtreamLookup {
  XtreamLookupService({
    required IptvLocalRepository iptvLocal,
    required AppLogger logger,
  }) : _iptvLocal = iptvLocal,
       _logger = logger;

  final IptvLocalRepository _iptvLocal;
  final AppLogger _logger;

  @override
  Future<XtreamPlaylistItem?> findItemByMovieId(
    String movieId, {
    Set<String>? accountIds,
    XtreamPlaylistItemType? expectedType,
  }) async {
    final xtreamAccounts = await _iptvLocal.getAccounts();
    final stalkerAccounts = await _iptvLocal.getStalkerAccounts();
    final allAccounts = <String>{
      ...xtreamAccounts.map((a) => a.id),
      ...stalkerAccounts.map((a) => a.id),
    };
    if (accountIds != null) {
      if (accountIds.isEmpty) return null;
      allAccounts.removeWhere((id) => !accountIds.contains(id));
    }
    final accounts = allAccounts.toList(growable: false);
    if (accounts.isEmpty) return null;

    _logger.debug(
      'Recherche du film movieId=$movieId dans ${accounts.length} comptes',
    );

    final isXtreamId = movieId.startsWith('xtream:');
    final streamId = isXtreamId ? int.tryParse(movieId.substring(7)) : null;
    final tmdbId = isXtreamId ? null : int.tryParse(movieId);

    for (final account in accounts) {
      final playlists = await _iptvLocal.getPlaylists(account);
      _logger.debug('Compte $account: ${playlists.length} playlists');

      for (final playlist in playlists) {
        _logger.debug(
          'Playlist ${playlist.title} (${playlist.type.name}): ${playlist.items.length} items',
        );

        XtreamPlaylistItem? item;

        if (isXtreamId) {
          _logger.debug('Recherche par streamId=$streamId (xtream)');
          if (streamId != null) {
            final matches = playlist.items.where(
              (i) => i.streamId == streamId,
            );
            final candidates = expectedType == null
                ? matches
                : matches.where((i) => i.type == expectedType);
            item = candidates.isEmpty ? null : candidates.first;
            if (item != null) {
              _logger.debug(
                'Item trouvé: ${item.title} (streamId=${item.streamId}, tmdbId=${item.tmdbId}, type=${item.type.name})',
              );
            } else if (matches.isNotEmpty && expectedType != null) {
              _logger.debug(
                'Item avec streamId=$streamId trouvé mais type différent (${matches.first.type.name} au lieu de ${expectedType.name})',
              );
            } else {
              _logger.debug(
                'Item avec streamId=$streamId non trouvé dans ${playlist.title}',
              );
            }
          }
        } else {
          _logger.debug('Recherche par tmdbId=$tmdbId');
          if (tmdbId != null) {
            final matches = playlist.items.where((i) => i.tmdbId == tmdbId);
            final candidates = expectedType == null
                ? matches
                : matches.where((i) => i.type == expectedType);
            item = candidates.isEmpty ? null : candidates.first;
            if (item != null) {
              _logger.debug(
                'Item trouvé: ${item.title} (streamId=${item.streamId}, tmdbId=${item.tmdbId}, type=${item.type.name})',
              );
            } else if (matches.isNotEmpty && expectedType != null) {
              _logger.debug(
                'Item avec tmdbId=$tmdbId trouvé mais type différent (${matches.first.type.name} au lieu de ${expectedType.name})',
              );
            } else {
              _logger.debug(
                'Item avec tmdbId=$tmdbId non trouvé dans ${playlist.title}',
              );
            }
          }
        }

        if (item != null) return item;
      }
    }

    return null;
  }
}
