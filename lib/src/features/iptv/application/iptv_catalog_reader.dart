import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/category_key.dart';

class IptvCatalogReader {
  IptvCatalogReader(this._local);

  final IptvLocalRepository _local;

  Future<List<ContentReference>> listAccounts() async {
    final accounts = await _local.getAccounts();
    return accounts
        .map(
          (a) => ContentReference(
            id: a.id,
            title: MediaTitle(a.alias),
            type: ContentType.playlist,
          ),
        )
        .toList(growable: false);
  }

  Future<List<ContentReference>> listCategory(CategoryKey key) async {
    final accounts = await _local.getAccounts();
    XtreamAccount? account;
    for (final a in accounts) {
      if (a.alias == key.alias) {
        account = a;
        break;
      }
    }
    if (account == null) return const <ContentReference>[];
    final playlists = await _local.getPlaylists(account.id);
    final cleanedTitle = _cleanCategoryTitle(key.title);
    final matches = playlists.where((pl) => _cleanCategoryTitle(pl.title) == cleanedTitle);
    final playlist = matches.isNotEmpty ? matches.first : null;
    if (playlist == null) return const <ContentReference>[];
    final items = <ContentReference>[];
    for (final it in playlist.items) {
      final refId = (it.tmdbId != null && it.tmdbId! > 0)
          ? it.tmdbId!.toString()
          : 'xtream:${it.streamId}';
      items.add(
        ContentReference(
          id: refId,
          title: MediaTitle(it.title),
          type: it.type == XtreamPlaylistItemType.series ? ContentType.series : ContentType.movie,
          poster: _safePosterUri(it.posterUrl),
          year: it.releaseYear,
          rating: it.rating,
        ),
      );
    }
    return items;
  }

  Future<List<ContentReference>> searchCatalog(String query) async {
    final q = query.trim();
    final accounts = await _local.getAccounts();
    final results = <ContentReference>[];
    for (final acc in accounts) {
      final playlists = await _local.getPlaylists(acc.id);
      for (final pl in playlists) {
        for (final it in pl.items) {
          final title = it.title.trim();
          final posterUrl = it.posterUrl;
          if (posterUrl == null || posterUrl.isEmpty) continue;
          if (q.isNotEmpty && !title.toLowerCase().contains(q.toLowerCase())) {
            continue;
          }
          final poster = _safePosterUri(posterUrl);
          if (poster == null) continue;
          final refId = (it.tmdbId != null && it.tmdbId! > 0)
              ? it.tmdbId!.toString()
              : 'xtream:${it.streamId}';
          results.add(
            ContentReference(
              id: refId,
              title: MediaTitle(title),
              type: it.type == XtreamPlaylistItemType.series ? ContentType.series : ContentType.movie,
              poster: poster,
              year: it.releaseYear,
              rating: it.rating,
            ),
          );
        }
      }
    }
    return results;
  }

  Future<Map<String, List<ContentReference>>> listCategoryLists({Set<String>? activeSourceIds}) async {
    final result = <String, List<ContentReference>>{};
    final accounts = await _local.getAccounts();
    for (final acc in accounts) {
      if (activeSourceIds != null && activeSourceIds.isNotEmpty && !activeSourceIds.contains(acc.id)) {
        continue;
      }
      final playlists = await _local.getPlaylists(acc.id);
      for (final pl in playlists) {
        final key = '${acc.alias}/${_cleanCategoryTitle(pl.title)}';
        final items = <ContentReference>[];
        for (final it in pl.items) {
          final refId = (it.tmdbId != null && it.tmdbId! > 0)
              ? it.tmdbId!.toString()
              : 'xtream:${it.streamId}';
          items.add(
            ContentReference(
              id: refId,
              title: MediaTitle(it.title),
              type: it.type == XtreamPlaylistItemType.series ? ContentType.series : ContentType.movie,
              poster: _safePosterUri(it.posterUrl),
              year: it.releaseYear,
              rating: it.rating,
            ),
          );
        }
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
}