import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

abstract class ContinueWatchingRepository {
  Future<void> remove(String contentId, ContentType type);
}
