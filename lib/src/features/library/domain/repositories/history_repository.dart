import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

abstract class HistoryRepository {
  Future<List<ContentReference>> getCompleted();
  Future<List<ContentReference>> getInProgress();
}
