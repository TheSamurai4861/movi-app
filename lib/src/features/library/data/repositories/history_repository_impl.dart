import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/library/domain/repositories/history_repository.dart';
import 'package:movi/src/features/library/domain/services/history_filter.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._history);

  final HistoryLocalRepository _history;

  @override
  Future<List<ContentReference>> getCompleted() async {
    final movies = await _history.readAll(ContentType.movie);
    final shows = await _history.readAll(ContentType.series);
    return [
      ...HistoryFilter.completed(movies),
      ...HistoryFilter.completed(shows),
    ];
  }

  @override
  Future<List<ContentReference>> getInProgress() async {
    final movies = await _history.readAll(ContentType.movie);
    final shows = await _history.readAll(ContentType.series);
    return [
      ...HistoryFilter.inProgress(movies),
      ...HistoryFilter.inProgress(shows),
    ];
  }
}
