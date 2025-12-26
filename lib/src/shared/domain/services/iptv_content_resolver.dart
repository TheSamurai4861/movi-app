import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class IptvContentResolution {
  const IptvContentResolution({
    required this.isAvailable,
    this.resolvedContentId,
  });

  final bool isAvailable;
  final String? resolvedContentId;

  static const unavailable = IptvContentResolution(isAvailable: false);

  static IptvContentResolution available(String contentId) =>
      IptvContentResolution(isAvailable: true, resolvedContentId: contentId);
}

abstract class IptvContentResolver {
  Future<IptvContentResolution> resolve({
    required String contentId,
    required ContentType type,
    required Set<String> activeSourceIds,
  });
}
