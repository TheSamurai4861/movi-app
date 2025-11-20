import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

class XtreamLookupService {
  XtreamLookupService({
    required IptvLocalRepository iptvLocal,
    required AppLogger logger,
  }) : _iptvLocal = iptvLocal,
       _logger = logger;

  final IptvLocalRepository _iptvLocal;
  final AppLogger _logger;

  Future<XtreamPlaylistItem?> findItemByMovieId(String movieId) async {
    final accounts = await _iptvLocal.getAccounts();

    _logger.debug(
      'Recherche du film movieId=$movieId dans ${accounts.length} comptes',
    );

    for (final account in accounts) {
      final playlists = await _iptvLocal.getPlaylists(account.id);
      _logger.debug('Compte ${account.id}: ${playlists.length} playlists');

      for (final playlist in playlists) {
        _logger.debug(
          'Playlist ${playlist.title} (${playlist.type.name}): ${playlist.items.length} items',
        );

        XtreamPlaylistItem? item;

        if (movieId.startsWith('xtream:')) {
          final streamIdStr = movieId.substring(7);
          final streamId = int.tryParse(streamIdStr);
          _logger.debug('Recherche par streamId=$streamId (xtream)');
          if (streamId != null) {
            try {
              item = playlist.items.firstWhere((i) => i.streamId == streamId);
              _logger.debug(
                'Item trouvé: ${item.title} (streamId=${item.streamId}, tmdbId=${item.tmdbId}, type=${item.type.name})',
              );
            } catch (_) {
              _logger.debug(
                'Item avec streamId=$streamId non trouvé dans ${playlist.title}',
              );
            }
          }
        } else {
          final tmdbId = int.tryParse(movieId);
          _logger.debug('Recherche par tmdbId=$tmdbId');
          if (tmdbId != null) {
            try {
              item = playlist.items.firstWhere((i) => i.tmdbId == tmdbId);
              _logger.debug(
                'Item trouvé: ${item.title} (streamId=${item.streamId}, tmdbId=${item.tmdbId}, type=${item.type.name})',
              );
            } catch (_) {
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
