import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/library/domain/repositories/history_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._history);

  final HistoryLocalRepository _history;

  @override
  Future<List<ContentReference>> getCompleted() async {
    final movies = await _history.readAll(ContentType.movie);
    final shows = await _history.readAll(ContentType.series);
    return [..._filterCompleted(movies), ..._filterCompleted(shows)];
  }

  @override
  Future<List<ContentReference>> getInProgress() async {
    final movies = await _history.readAll(ContentType.movie);
    final shows = await _history.readAll(ContentType.series);
    return [..._filterInProgress(movies), ..._filterInProgress(shows)];
  }

  List<ContentReference> _filterCompleted(List<HistoryEntry> entries) {
    return entries
        .where((e) => _progress(e) >= 0.9)
        .map(
          (e) => ContentReference(
            id: e.contentId,
            title: MediaTitle(e.title),
            type: e.type,
            poster: e.poster,
          ),
        )
        .toList(growable: false);
  }

  List<ContentReference> _filterInProgress(List<HistoryEntry> entries) {
    return entries
        .where((e) {
          final p = _progress(e);
          return p > 0 && p < 0.9;
        })
        .map(
          (e) => ContentReference(
            id: e.contentId,
            title: MediaTitle(e.title),
            type: e.type,
            poster: e.poster,
          ),
        )
        .toList(growable: false);
  }

  double _progress(HistoryEntry e) {
    if (e.duration == null || e.duration!.inSeconds <= 0) return 0;
    final pos = e.lastPosition?.inSeconds ?? 0;
    return pos / e.duration!.inSeconds;
  }
}
