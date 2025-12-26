import 'package:movi/src/features/player/domain/value_objects/track_info.dart';

class PlayerTracks {
  const PlayerTracks({
    required this.audioTracks,
    required this.subtitleTracks,
    this.activeAudioTrackId,
    this.activeSubtitleTrackId,
  });

  final List<TrackInfo> audioTracks;
  final List<TrackInfo> subtitleTracks;
  final int? activeAudioTrackId;
  final int? activeSubtitleTrackId;
}
