import 'package:movi/src/core/network/network_executor.dart';
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

  @override
  Future<VideoSource?> buildMovieSource({
    required String movieId,
    required String title,
    Uri? poster,
    Set<String>? preferredAccountIds,
  }) async {
    try {
      final item = await _lookup.findItemByMovieId(
        movieId,
        accountIds: preferredAccountIds,
        expectedType: XtreamPlaylistItemType.movie,
      );
      if (item == null) return null;
      if (item.type != XtreamPlaylistItemType.movie) return null;

      final builder = XtreamStreamUrlBuilderImpl(
        iptvLocal: _iptvLocal,
        vault: _vault,
        networkExecutor: _networkExecutor,
      );
      final url = await builder.buildStreamUrlFromMovieItem(item);
      if (url == null) return null;

      return VideoSource(
        url: url.toString(),
        title: title,
        contentId: movieId,
        tmdbId: item.tmdbId,
        contentType: ContentType.movie,
        poster: poster,
      );
    } on StalkerStreamFailure {
      rethrow;
    } catch (e, st) {
      _logger.error('MovieStreamingServiceImpl error: $e', e, st);
      return null;
    }
  }
}
