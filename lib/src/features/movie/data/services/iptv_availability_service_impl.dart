import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
import 'package:movi/src/features/movie/domain/services/iptv_availability_service.dart';

class IptvAvailabilityServiceImpl implements IptvAvailabilityService {
  IptvAvailabilityServiceImpl({
    required IptvLocalRepository iptvLocal,
    required AppLogger logger,
    required XtreamLookupService lookup,
  }) : _iptvLocal = iptvLocal,
       _logger = logger,
       _lookup = lookup;

  final IptvLocalRepository _iptvLocal;
  final AppLogger _logger;
  final XtreamLookupService _lookup;

  @override
  Future<bool> isMovieAvailable(String movieId) async {
    if (movieId.startsWith('xtream:')) {
      final item = await _lookup.findItemByMovieId(
        movieId,
        expectedType: XtreamPlaylistItemType.movie,
      );
      return item?.type == XtreamPlaylistItemType.movie;
    }
    final tmdbId = int.tryParse(movieId);
    if (tmdbId == null) return false;
    try {
      final ids = await _iptvLocal.getAvailableTmdbIds(
        type: XtreamPlaylistItemType.movie,
      );
      return ids.contains(tmdbId);
    } catch (e, st) {
      _logger.error('IptvAvailabilityServiceImpl error: $e', e, st);
      return false;
    }
  }
}
