import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/playlist/playlist.dart';

enum LibraryPlaylistSortType {
  title,
  recentlyAdded,
  yearAscending,
  yearDescending,
}

class LibraryPlaylistSorter {
  static List<ContentReference> sort(
    List<ContentReference> items, {
    LibraryPlaylistSortType? sortType,
    List<PlaylistItem>? playlistItems,
  }) {
    if (sortType == null) return items;

    final sorted = List<ContentReference>.from(items);

    switch (sortType) {
      case LibraryPlaylistSortType.title:
        sorted.sort(
          (a, b) => a.title.value.toLowerCase().compareTo(
            b.title.value.toLowerCase(),
          ),
        );
        return sorted;
      case LibraryPlaylistSortType.recentlyAdded:
        if (playlistItems != null && playlistItems.isNotEmpty) {
          sorted.sort((a, b) {
            final itemA = playlistItems.firstWhere(
              (pi) => pi.reference.id == a.id,
              orElse: () => PlaylistItem(reference: a),
            );
            final itemB = playlistItems.firstWhere(
              (pi) => pi.reference.id == b.id,
              orElse: () => PlaylistItem(reference: b),
            );
            final dateA = itemA.addedAt ?? DateTime(1970);
            final dateB = itemB.addedAt ?? DateTime(1970);
            return dateB.compareTo(dateA);
          });
        }
        return sorted;
      case LibraryPlaylistSortType.yearAscending:
        final withYear = <ContentReference>[];
        final withoutYear = <ContentReference>[];
        for (final item in sorted) {
          if (item.year != null) {
            withYear.add(item);
          } else {
            withoutYear.add(item);
          }
        }
        withYear.sort((a, b) {
          final yearA = a.year ?? 0;
          final yearB = b.year ?? 0;
          return yearA.compareTo(yearB);
        });
        return [...withYear, ...withoutYear];
      case LibraryPlaylistSortType.yearDescending:
        sorted.sort((a, b) {
          final yearA = a.year ?? 0;
          final yearB = b.year ?? 0;
          return yearB.compareTo(yearA);
        });
        return sorted;
    }
  }
}
