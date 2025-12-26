import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class ContentRatingResult {
  const ContentRatingResult({
    required this.minAge,
    required this.regionUsed,
    required this.rawRating,
  });

  final int? minAge;
  final String? regionUsed;
  final String? rawRating;
}

abstract class ContentRatingRepository {
  Future<ContentRatingResult> getMinAge({
    required ContentType type,
    required int tmdbId,
    List<String> preferredRegions = const <String>['BE', 'FR', 'US'],
  });
}

