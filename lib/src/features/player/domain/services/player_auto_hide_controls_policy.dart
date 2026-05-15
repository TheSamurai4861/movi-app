/// Règles pour l'auto-masquage des contrôles du lecteur vidéo.
class PlayerAutoHideControlsPolicy {
  const PlayerAutoHideControlsPolicy._();

  /// Programme l'auto-hide uniquement si l'overlay est visible et la lecture active.
  static bool shouldScheduleAutoHide({
    required bool showControls,
    required bool isPlaying,
  }) {
    return showControls && isPlaying;
  }

  /// La persistance périodique ne dépend pas de la visibilité des contrôles.
  static bool shouldRunProgressPersistTimer({required bool isPlaying}) {
    return isPlaying;
  }
}
