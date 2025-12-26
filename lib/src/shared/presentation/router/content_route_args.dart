import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class ContentRouteArgs {
  const ContentRouteArgs({required this.id, required this.type});

  const ContentRouteArgs.movie(String id) : this(id: id, type: ContentType.movie);

  const ContentRouteArgs.series(String id)
      : this(id: id, type: ContentType.series);

  final String id;
  final ContentType type;

  bool get isXtream => id.startsWith('xtream:');
}
