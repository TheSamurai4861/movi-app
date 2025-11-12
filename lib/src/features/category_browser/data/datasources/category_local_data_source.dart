// lib/src/features/category_browser/data/datasources/category_local_data_source.dart
import 'package:flutter/foundation.dart';

import '../../../../core/storage/repositories/iptv_local_repository.dart';
import '../../../../core/iptv/domain/entities/xtream_playlist.dart';
import '../../../../core/iptv/domain/entities/xtream_playlist_item.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';
import '../../../../shared/domain/value_objects/media_title.dart';
import '../../../home/data/repositories/home_feed_repository_impl.dart'
    show XtreamAccountLite; // reuse lite projection
import '../../../category_browser/domain/value_objects/category_key.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this._iptvLocal);

  final IptvLocalRepository _iptvLocal;

  /// Récupère toutes les références de contenu pour une catégorie donnée.
  Future<List<ContentReference>> listItems(CategoryKey key) async {
    final accounts = await _safeGetAccounts();
    final account = accounts.firstWhere(
      (a) => a.alias == key.alias,
      orElse: () => const XtreamAccountLite(id: '', alias: ''),
    );
    if (account.id.isEmpty) return const <ContentReference>[];

    final playlists = await _safeGetPlaylists(account.id);
    final String cleanedTitle = _cleanCategoryTitle(key.title);

    final matches = playlists.where(
      (pl) => _cleanCategoryTitle(pl.title) == cleanedTitle,
    );
    final playlist = matches.isNotEmpty ? matches.first : null;
    if (playlist == null) return const <ContentReference>[];

    final List<ContentReference> items = <ContentReference>[];
    for (final it in playlist.items) {
      final String refId = (it.tmdbId != null && it.tmdbId! > 0)
          ? it.tmdbId!.toString()
          : 'xtream:${it.streamId}';
      items.add(
        ContentReference(
          id: refId,
          title: MediaTitle(it.title),
          type: it.type == XtreamPlaylistItemType.series
              ? ContentType.series
              : ContentType.movie,
          poster: _safePosterUri(it.posterUrl),
          year: it.releaseYear,
          rating: it.rating,
        ),
      );
    }
    return items;
  }

  // Copie de la logique safe utilisée côté HomeFeedRepositoryImpl
  Future<List<XtreamAccountLite>> _safeGetAccounts() async {
    try {
      final accounts = await _iptvLocal.getAccounts();
      return accounts
          .map((a) => XtreamAccountLite(id: a.id, alias: a.alias))
          .toList(growable: false);
    } catch (e) {
      assert(() {
        debugPrint('[CategoryLocalDataSource] getAccounts error: $e');
        return true;
      }());
      return const <XtreamAccountLite>[];
    }
  }

  Future<List<XtreamPlaylist>> _safeGetPlaylists(String accountId) async {
    try {
      final List<XtreamPlaylist> playlists = await _iptvLocal.getPlaylists(
        accountId,
      );
      return playlists;
    } catch (e) {
      assert(() {
        debugPrint('[CategoryLocalDataSource] getPlaylists error: $e');
        return true;
      }());
      return const <XtreamPlaylist>[];
    }
  }

  String _cleanCategoryTitle(String raw) {
    final int idx = raw.indexOf('/');
    if (idx >= 0 && idx < raw.length - 1) {
      return raw.substring(idx + 1);
    }
    return raw;
  }

  Uri? _safePosterUri(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final Uri? u = Uri.tryParse(raw);
    if (u == null) return null;
    final String scheme = u.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return u;
  }
}
