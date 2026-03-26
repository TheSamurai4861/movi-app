import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/library/library_constants.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

/// Helper centralisé pour filtrer l'historique en listes "terminé" / "en cours"
/// et le mapper vers des [ContentReference].
///
/// La définition de "terminé" pour l'historique est basée sur
/// [LibraryConstants.watchHistoryCompletedThreshold].
class HistoryFilter {
  const HistoryFilter._();

  /// Entrées dont la progression est supérieure ou égale au seuil "terminé".
  static List<ContentReference> completed(List<HistoryEntry> entries) {
    return entries
        .where(
          (e) => _progress(e) >= LibraryConstants.watchHistoryCompletedThreshold,
        )
        .map(_toContentReference)
        .toList(growable: false);
  }

  /// Entrées dont la progression est comprise dans la plage Home:
  /// >= min in progress et < seuil "terminé".
  static List<ContentReference> inProgress(List<HistoryEntry> entries) {
    return entries
        .where((e) {
          final p = _progress(e);
          return p >= LibraryConstants.inProgressMinThreshold &&
              p < LibraryConstants.inProgressMaxThreshold;
        })
        .map(_toContentReference)
        .toList(growable: false);
  }

  static ContentReference _toContentReference(HistoryEntry e) {
    return ContentReference(
      id: e.contentId,
      title: MediaTitle(e.title),
      type: e.type,
      poster: e.poster,
    );
  }

  static double _progress(HistoryEntry e) {
    if (e.duration == null || e.duration!.inSeconds <= 0) return 0;
    final pos = e.lastPosition?.inSeconds ?? 0;
    return pos / e.duration!.inSeconds;
  }
}
