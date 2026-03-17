import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

/// Abstraction pour localiser un item Xtream à partir d'un identifiant film.
abstract class XtreamLookup {
  Future<XtreamPlaylistItem?> findItemByMovieId(
    String movieId, {
    Set<String>? accountIds,
    XtreamPlaylistItemType? expectedType,
  });
}
