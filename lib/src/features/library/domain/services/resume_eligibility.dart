import 'package:movi/src/features/library/library_constants.dart';

/// Règle métier partagée pour décider si une reprise est admissible.
Duration? normalizeResumePosition({
  required Duration? position,
  required Duration? duration,
}) {
  if (position == null ||
      position <= Duration.zero ||
      duration == null ||
      duration.inSeconds <= 0) {
    return null;
  }

  final progress = position.inSeconds / duration.inSeconds;
  if (progress < LibraryConstants.inProgressMinThreshold ||
      progress >= LibraryConstants.inProgressMaxThreshold) {
    return null;
  }
  return position;
}
