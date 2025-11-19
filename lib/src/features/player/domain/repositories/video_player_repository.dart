import 'package:movi/src/features/player/domain/entities/video_source.dart';

/// Interface pour le contrôle du player vidéo
abstract class VideoPlayerRepository {
  /// Ouvre une source vidéo
  Future<void> open(VideoSource source);

  /// Joue la vidéo
  Future<void> play();

  /// Met en pause
  Future<void> pause();

  /// Avance de [seconds] secondes
  Future<void> seekForward(int seconds);

  /// Recule de [seconds] secondes
  Future<void> seekBackward(int seconds);

  /// Va à une position spécifique
  Future<void> seekTo(Duration position);

  /// Définit le volume (0.0 à 1.0)
  Future<void> setVolume(double volume);

  /// Active/désactive les sous-titres
  Future<void> setSubtitlesEnabled(bool enabled);

  /// Sélectionne une piste de sous-titres
  Future<void> setSubtitleTrack(int? trackId);

  /// Sélectionne une piste audio
  Future<void> setAudioTrack(int? trackId);

  /// Libère les ressources du player
  void dispose();
}
