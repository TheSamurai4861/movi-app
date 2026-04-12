import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/domain/value_objects/player_active_tracks.dart';
import 'package:movi/src/features/player/domain/value_objects/player_tracks.dart';

enum PlayerOffsetKind { subtitle, audio }

enum PlayerSubtitleFailureKind { unsupportedCodec }

class PlayerOffsetUnsupportedException implements Exception {
  const PlayerOffsetUnsupportedException({required this.kind, this.reason});

  final PlayerOffsetKind kind;
  final String? reason;

  @override
  String toString() {
    final reasonPart = (reason == null || reason!.trim().isEmpty)
        ? ''
        : ' ($reason)';
    return 'PlayerOffsetUnsupportedException(kind: $kind)$reasonPart';
  }
}

class PlayerSubtitleSelectionException implements Exception {
  const PlayerSubtitleSelectionException({required this.kind, this.reason});

  final PlayerSubtitleFailureKind kind;
  final String? reason;

  @override
  String toString() {
    final reasonPart = (reason == null || reason!.trim().isEmpty)
        ? ''
        : ' ($reason)';
    return 'PlayerSubtitleSelectionException(kind: $kind)$reasonPart';
  }
}

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

  /// Alias explicite pour activer/désactiver une piste de sous-titres
  Future<void> setActiveSubtitleTrack(int? trackId);

  /// Sélectionne une piste audio
  Future<void> setAudioTrack(int? trackId);

  /// Indique si le backend actif supporte le décalage des sous-titres.
  Future<bool> supportsSubtitleOffset();

  /// Indique si le backend actif supporte le décalage audio.
  Future<bool> supportsAudioOffset();

  /// Applique un décalage des sous-titres en millisecondes.
  Future<void> setSubtitleOffsetMs(int offsetMs);

  /// Applique un décalage audio en millisecondes.
  Future<void> setAudioOffsetMs(int offsetMs);

  /// Renvoie les pistes audio/sous-titres disponibles et les pistes actives
  Future<PlayerActiveTracks> getActiveTracks();

  /// Flux des pistes disponibles et des pistes actives
  Stream<PlayerTracks> get tracksStream;

  /// Flux lecture en cours (true/false)
  Stream<bool> get playingStream;

  /// Flux de la position courante
  Stream<Duration> get positionStream;

  /// Flux de la durée du média
  Stream<Duration> get durationStream;

  /// Flux d'état de buffering
  Stream<bool> get bufferingStream;

  /// Libère les ressources du player
  void dispose();
}
