import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
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
    required XtreamLookupService lookup,
    NetworkExecutor? networkExecutor,
  }) : _iptvLocal = iptvLocal,
       _vault = vault,
       _logger = logger,
       _lookup = lookup,
       _networkExecutor = networkExecutor;

  final IptvLocalRepository _iptvLocal;
  final CredentialsVault _vault;
  final AppLogger _logger;
  final XtreamLookupService _lookup;
  final NetworkExecutor? _networkExecutor;

  /// Recherche un film dans les playlists Xtream et construit la source vidéo.
  ///
  /// Retourne `null` si le film n'est pas trouvé ou si une erreur survient.
  Future<VideoSource?> findAndBuildStreamUrl(MovieSummary movie) async {
    try {
      final urlBuilder = XtreamStreamUrlBuilderImpl(
        iptvLocal: _iptvLocal,
        vault: _vault,
        networkExecutor: _networkExecutor,
      );

      final movieId = movie.id.value;
      final title = movie.title.display;

      // Chercher l'item Xtream correspondant
      final xtreamItem = await _lookup.findItemByMovieId(
        movieId,
        expectedType: XtreamPlaylistItemType.movie,
      );

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
        url: streamUrl.toString(),
        title: title,
        contentId: movieId,
        tmdbId: xtreamItem.tmdbId,
        contentType: ContentType.movie,
        poster: movie.poster,
      );
    } catch (e, st) {
      _logger.error('Erreur lors de la recherche du film: $e', e, st);
      return null;
    }
  }
}
