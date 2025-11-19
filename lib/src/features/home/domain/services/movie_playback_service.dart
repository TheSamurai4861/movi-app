import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Service pour gérer la lecture de films depuis le hero de la page d'accueil.
///
/// Centralise la logique de recherche de playlists Xtream et de construction
/// d'URLs de streaming pour éviter la duplication entre widgets.
class MoviePlaybackService {
  MoviePlaybackService({
    required IptvLocalRepository iptvLocal,
    required CredentialsVault vault,
    required AppLogger logger,
  }) : _iptvLocal = iptvLocal,
       _vault = vault,
       _logger = logger;

  final IptvLocalRepository _iptvLocal;
  final CredentialsVault _vault;
  final AppLogger _logger;

  /// Recherche un film dans les playlists Xtream et construit la source vidéo.
  ///
  /// Retourne `null` si le film n'est pas trouvé ou si une erreur survient.
  Future<VideoSource?> findAndBuildStreamUrl(MovieSummary movie) async {
    try {
      final urlBuilder = XtreamStreamUrlBuilder(
        iptvLocal: _iptvLocal,
        vault: _vault,
      );

      final movieId = movie.id.value;
      final title = movie.title.display;

      // Chercher l'item Xtream correspondant
      final xtreamItem = await _findXtreamItem(movieId);

      if (xtreamItem == null) {
        _logger.info('Film movieId=$movieId non trouvé dans les playlists');
        return null;
      }

      // Vérifier que c'est bien un film
      if (xtreamItem.type != XtreamPlaylistItemType.movie) {
        _logger.warn(
          'Item trouvé est de type ${xtreamItem.type.name}, pas un film',
        );
        return null;
      }

      // Construire l'URL de streaming
      final streamUrl = await urlBuilder.buildStreamUrlFromMovieItem(
        xtreamItem,
      );

      if (streamUrl == null) {
        _logger.error(
          'Impossible de construire l\'URL pour streamId=${xtreamItem.streamId}',
        );
        return null;
      }

      _logger.debug('URL de streaming construite: $streamUrl');

      return VideoSource(
        url: streamUrl,
        title: title,
        contentId: movieId,
        contentType: ContentType.movie,
        poster: movie.poster,
      );
    } catch (e, st) {
      _logger.error('Erreur lors de la recherche du film: $e', e, st);
      return null;
    }
  }

  /// Recherche un item Xtream par son ID (streamId ou tmdbId).
  Future<XtreamPlaylistItem?> _findXtreamItem(String movieId) async {
    final accounts = await _iptvLocal.getAccounts();

    _logger.debug(
      'Recherche du film movieId=$movieId dans ${accounts.length} comptes',
    );

    for (final account in accounts) {
      final playlists = await _iptvLocal.getPlaylists(account.id);
      _logger.debug('Compte ${account.id}: ${playlists.length} playlists');

      // Recherche globale dans toutes les playlists (movies et series)
      // car certains films peuvent être mal catégorisés
      for (final playlist in playlists) {
        _logger.debug(
          'Playlist ${playlist.title} (${playlist.type.name}): ${playlist.items.length} items',
        );

        XtreamPlaylistItem? item;

        // Si l'ID commence par "xtream:", chercher par streamId
        if (movieId.startsWith('xtream:')) {
          final streamIdStr = movieId.substring(7);
          final streamId = int.tryParse(streamIdStr);
          _logger.debug('Recherche par streamId=$streamId (xtream)');
          if (streamId != null) {
            try {
              item = playlist.items.firstWhere((i) => i.streamId == streamId);
              _logger.debug(
                'Film trouvé: ${item.title} (streamId=${item.streamId}, tmdbId=${item.tmdbId}, type=${item.type.name})',
              );
            } catch (_) {
              _logger.debug(
                'Film avec streamId=$streamId non trouvé dans ${playlist.title}',
              );
            }
          }
        } else {
          // Sinon, chercher par tmdbId
          final tmdbId = int.tryParse(movieId);
          _logger.debug('Recherche par tmdbId=$tmdbId');
          if (tmdbId != null) {
            try {
              item = playlist.items.firstWhere((i) => i.tmdbId == tmdbId);
              _logger.debug(
                'Film trouvé: ${item.title} (streamId=${item.streamId}, tmdbId=${item.tmdbId}, type=${item.type.name})',
              );
            } catch (_) {
              _logger.debug(
                'Film avec tmdbId=$tmdbId non trouvé dans ${playlist.title}',
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
