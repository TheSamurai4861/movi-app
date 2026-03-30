import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_settings.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/category_key.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class IptvCatalogReader {
  IptvCatalogReader(this._local, this._analysisService, this._logger);

  final IptvLocalRepository _local;
  final IptvPlaylistAnalysisService _analysisService;
  final AppLogger _logger;
  final Set<String> _loggedUnsupportedItems = <String>{};

  Future<Set<int>> getAvailableTmdbIds({
    XtreamPlaylistItemType? type,
    Set<String>? activeSourceIds,
  }) {
    return _local.getAvailableTmdbIds(type: type, accountIds: activeSourceIds);
  }

  Future<List<ContentReference>> listAccounts() async {
    final xtreamAccounts = await _local.getAccounts();
    final stalkerAccounts = await _local.getStalkerAccounts();
    return [
      ...xtreamAccounts.map(
        (a) => ContentReference(
          id: a.id,
          title: MediaTitle(a.alias),
          type: ContentType.playlist,
        ),
      ),
      ...stalkerAccounts.map(
        (a) => ContentReference(
          id: a.id,
          title: MediaTitle(a.alias),
          type: ContentType.playlist,
        ),
      ),
    ];
  }

  Future<List<ContentReference>> listCategory(CategoryKey key) async {
    final xtreamAccounts = await _local.getAccounts();
    final stalkerAccounts = await _local.getStalkerAccounts();
    final accounts = [
      ...xtreamAccounts.map((a) => (id: a.id, alias: a.alias)),
      ...stalkerAccounts.map((a) => (id: a.id, alias: a.alias)),
    ];
    final account = accounts.firstWhere(
      (a) => a.alias == key.alias,
      orElse: () => (id: '', alias: ''),
    );
    if (account.id.isEmpty) return const <ContentReference>[];
    final playlists = await _local.getPlaylists(account.id, itemLimit: 0);
    final cleanedTitle = _cleanCategoryTitle(key.title);
    final matches = playlists.where(
      (pl) => _cleanCategoryTitle(pl.title) == cleanedTitle,
    );
    final playlist = matches.isNotEmpty ? matches.first : null;
    if (playlist == null) return const <ContentReference>[];
    final playlistItems = await _local.getPlaylistItems(
      accountId: account.id,
      playlistId: playlist.id,
      categoryName: playlist.title,
      playlistType: playlist.type,
    );
    return _toContentReferences(playlistItems);
  }

  Future<List<ContentReference>> searchCatalog(
    String query, {
    int limit = 500,
    Set<String>? activeSourceIds,
  }) async {
    final items = await _local.searchItems(
      query,
      limit: limit,
      accountIds: activeSourceIds,
    );
    return _toContentReferences(items);
  }

  Future<Map<String, List<ContentReference>>> listCategoryLists({
    Set<String>? activeSourceIds,
    int? itemLimitPerPlaylist,
  }) async {
    final result = <String, List<ContentReference>>{};
    if (activeSourceIds != null && activeSourceIds.isEmpty) {
      return result;
    }

    // 🔧 FIX: Charger TOUS les comptes (Xtream + Stalker)
    final xtreamAccounts = await _local.getAccounts();
    final stalkerAccounts = await _local.getStalkerAccounts();

    // Créer une liste unifiée avec (id, alias)
    final allAccounts = <({String id, String alias})>[
      ...xtreamAccounts.map((a) => (id: a.id, alias: a.alias)),
      ...stalkerAccounts.map((a) => (id: a.id, alias: a.alias)),
    ];

    for (final acc in allAccounts) {
      if (activeSourceIds != null &&
          activeSourceIds.isNotEmpty &&
          !activeSourceIds.contains(acc.id)) {
        continue;
      }
      final playlists = await _local.getPlaylists(acc.id, itemLimit: 0);
      final settings = await _local.getPlaylistSettings(acc.id);
      final settingsById = {for (final s in settings) s.playlistId: s};

      final ordered = <(XtreamPlaylist, XtreamPlaylistSettings?)>[];
      for (final pl in playlists) {
        final s = settingsById[pl.id];
        final visible = s?.isVisible ?? true;
        if (!visible) continue;
        ordered.add((pl, s));
      }

      int globalPosOf((XtreamPlaylist, XtreamPlaylistSettings?) entry) =>
          entry.$2?.globalPosition ?? 1 << 30;
      int stableTitleCmp(
        (XtreamPlaylist, XtreamPlaylistSettings?) a,
        (XtreamPlaylist, XtreamPlaylistSettings?) b,
      ) => a.$1.title.compareTo(b.$1.title);

      ordered.sort((a, b) {
        final c = globalPosOf(a).compareTo(globalPosOf(b));
        return c != 0 ? c : stableTitleCmp(a, b);
      });

      for (final entry in ordered) {
        final pl = entry.$1;
        final key = '${acc.alias}/${_cleanCategoryTitle(pl.title)}';
        final playlistItems = await _local.getPlaylistItems(
          accountId: acc.id,
          playlistId: pl.id,
          categoryName: pl.title,
          playlistType: pl.type,
          limit: itemLimitPerPlaylist,
        );
        final items = _toContentReferences(playlistItems);
        if (items.isNotEmpty) {
          result[key] = items;
        }
      }
    }
    return result;
  }

  String _cleanCategoryTitle(String raw) {
    final idx = raw.indexOf('/');
    if (idx >= 0 && idx < raw.length - 1) {
      return raw.substring(idx + 1);
    }
    return raw;
  }

  Uri? _safePosterUri(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final u = Uri.tryParse(raw);
    if (u == null) return null;
    final sch = u.scheme.toLowerCase();
    if (sch != 'http' && sch != 'https') return null;
    return u;
  }

  List<ContentReference> _toContentReferences(
    Iterable<XtreamPlaylistItem> items,
  ) {
    final projected = <ContentReference>[];
    for (final item in items) {
      final reference = _toContentReference(item);
      if (reference != null) {
        projected.add(reference);
      }
    }
    return List<ContentReference>.unmodifiable(projected);
  }

  ContentReference? _toContentReference(XtreamPlaylistItem item) {
    final analysis = _analysisService.analyze(item);
    if (!analysis.fallback.isSupported) {
      _logUnsupportedItem(item, analysis);
      return null;
    }

    final refId = (item.tmdbId != null && item.tmdbId! > 0)
        ? item.tmdbId!.toString()
        : 'xtream:${item.streamId}';
    final poster =
        analysis.fallback.posterDecision ==
            IptvPosterFallbackDecision.keepSourcePoster
        ? _safePosterUri(item.posterUrl)
        : null;
    final year =
        analysis.fallback.yearDecision == IptvYearFallbackDecision.hideYear
        ? null
        : analysis.normalizedYear;
    final rating =
        analysis.fallback.ratingDecision ==
            IptvRatingFallbackDecision.keepSourceRating
        ? item.rating
        : null;

    return ContentReference(
      id: refId,
      title: MediaTitle(analysis.displayTitle),
      type: item.type == XtreamPlaylistItemType.series
          ? ContentType.series
          : ContentType.movie,
      poster: poster,
      year: year,
      rating: rating,
    );
  }

  void _logUnsupportedItem(
    XtreamPlaylistItem item,
    IptvPlaylistAnalysis analysis,
  ) {
    final key =
        '${item.accountId}|${item.categoryId}|${item.streamId}|${item.title.trim()}';
    if (_loggedUnsupportedItems.contains(key)) return;
    _loggedUnsupportedItems.add(key);

    final diagnostics = analysis.diagnostics.map((d) => d.name).join(', ');
    _logger.warn(
      'Skipping unsupported IPTV item '
      'accountId=${item.accountId} streamId=${item.streamId} '
      'title="${item.title.trim()}" diagnostics=[$diagnostics]',
      category: 'iptv_catalog_reader',
    );
  }
}
