import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
import 'package:movi/src/shared/domain/services/iptv_content_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class IptvContentResolverImpl implements IptvContentResolver {
  IptvContentResolverImpl({
    required IptvLocalRepository iptvLocal,
    required XtreamLookupService lookup,
  }) : _iptvLocal = iptvLocal,
       _lookup = lookup;

  final IptvLocalRepository _iptvLocal;
  final XtreamLookupService _lookup;

  @override
  Future<IptvContentResolution> resolve({
    required String contentId,
    required ContentType type,
    required Set<String> activeSourceIds,
  }) async {
    final cleanedIds = _sanitizeIds(activeSourceIds);
    if (cleanedIds.isEmpty) return IptvContentResolution.unavailable;

    final itemType = _mapItemType(type);
    if (itemType == null) return IptvContentResolution.unavailable;

    if (contentId.startsWith('xtream:')) {
      final inActive = await _lookup.findItemByMovieId(
        contentId,
        accountIds: cleanedIds,
        expectedType: itemType,
      );
      if (inActive != null) {
        return IptvContentResolution.available(contentId);
      }

      final fallbackItem = await _lookup.findItemByMovieId(
        contentId,
        expectedType: itemType,
      );
      final tmdbId = fallbackItem?.tmdbId;
      if (tmdbId == null || tmdbId <= 0) {
        return IptvContentResolution.unavailable;
      }

      final available = await _iptvLocal.getAvailableTmdbIds(
        type: itemType,
        accountIds: cleanedIds,
      );
      if (!available.contains(tmdbId)) {
        return IptvContentResolution.unavailable;
      }
      return IptvContentResolution.available(tmdbId.toString());
    }

    final tmdbId = int.tryParse(contentId);
    if (tmdbId == null) return IptvContentResolution.unavailable;

    final available = await _iptvLocal.getAvailableTmdbIds(
      type: itemType,
      accountIds: cleanedIds,
    );
    if (!available.contains(tmdbId)) {
      return IptvContentResolution.unavailable;
    }
    return IptvContentResolution.available(contentId);
  }

  XtreamPlaylistItemType? _mapItemType(ContentType type) {
    switch (type) {
      case ContentType.movie:
        return XtreamPlaylistItemType.movie;
      case ContentType.series:
        return XtreamPlaylistItemType.series;
      default:
        return null;
    }
  }

  Set<String> _sanitizeIds(Set<String> ids) {
    final cleaned = ids.map((id) => id.trim()).where((id) => id.isNotEmpty);
    return Set<String>.unmodifiable(cleaned);
  }
}
