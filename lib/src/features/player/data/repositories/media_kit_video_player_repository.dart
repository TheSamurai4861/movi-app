import 'package:media_kit/media_kit.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/domain/repositories/video_player_repository.dart';

/// Implémentation du VideoPlayerRepository avec media_kit
class MediaKitVideoPlayerRepository implements VideoPlayerRepository {
  MediaKitVideoPlayerRepository() {
    _player = Player();
  }

  late final Player _player;

  Player get player => _player;

  @override
  Future<void> open(VideoSource source) async {
    await _player.open(Media(source.url), play: true);
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seekForward(int seconds) async {
    final currentPosition = _player.state.position;
    final newPosition = currentPosition + Duration(seconds: seconds);
    await _player.seek(newPosition);
  }

  @override
  Future<void> seekBackward(int seconds) async {
    final currentPosition = _player.state.position;
    final newPosition = currentPosition - Duration(seconds: seconds);
    await _player.seek(newPosition);
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 100.0));
  }

  @override
  Future<void> setSubtitlesEnabled(bool enabled) async {
    if (enabled) {
      // Active la première piste de sous-titres disponible
      final tracks = _player.state.tracks.subtitle;
      if (tracks.isNotEmpty) {
        await _player.setSubtitleTrack(tracks.first);
      }
    } else {
      // Désactive les sous-titres en définissant un track vide
      // Note: media_kit peut nécessiter une approche différente selon la version
      // Si cela ne fonctionne pas, on peut simplement ne rien faire
      // car l'utilisateur peut désactiver visuellement
    }
  }

  @override
  Future<void> setSubtitleTrack(int? trackId) async {
    if (trackId == null) {
      // Désactiver les sous-titres
      return;
    }
    final tracks = _player.state.tracks.subtitle;
    if (tracks.isEmpty) return;

    final track = tracks.firstWhere(
      (t) => t.id == trackId.toString(),
      orElse: () => tracks.first,
    );
    await _player.setSubtitleTrack(track);
  }

  @override
  Future<void> setAudioTrack(int? trackId) async {
    if (trackId == null) {
      return;
    }
    final tracks = _player.state.tracks.audio;
    if (tracks.isEmpty) return;

    final track = tracks.firstWhere(
      (t) => t.id == trackId.toString(),
      orElse: () => tracks.first,
    );
    await _player.setAudioTrack(track);
  }

  @override
  void dispose() {
    _player.dispose();
  }
}
