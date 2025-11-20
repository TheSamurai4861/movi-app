import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/movie/domain/services/movie_streaming_service.dart';

class MovieStreamingServiceImpl implements MovieStreamingService {
  MovieStreamingServiceImpl({
    required IptvLocalRepository iptvLocal,
    required CredentialsVault vault,
    required AppLogger logger,
    required XtreamLookupService lookup,
  }) : _iptvLocal = iptvLocal,
       _vault = vault,
       _logger = logger,
       _lookup = lookup;

  final IptvLocalRepository _iptvLocal;
  final CredentialsVault _vault;
  final AppLogger _logger;
  final XtreamLookupService _lookup;

  @override
  Future<VideoSource?> buildMovieSource({
    required String movieId,
    required String title,
    Uri? poster,
  }) async {
    try {
      final item = await _lookup.findItemByMovieId(movieId);
      if (item == null) return null;
      if (item.type != XtreamPlaylistItemType.movie) return null;

      final builder = XtreamStreamUrlBuilderImpl(
        iptvLocal: _iptvLocal,
        vault: _vault,
      );
      final url = await builder.buildStreamUrlFromMovieItem(item);
      if (url == null) return null;

      return VideoSource(
        url: url.toString(),
        title: title,
        contentId: movieId,
        contentType: ContentType.movie,
        poster: poster,
      );
    } catch (e, st) {
      _logger.error('MovieStreamingServiceImpl error: $e', e, st);
      return null;
    }
  }
}
