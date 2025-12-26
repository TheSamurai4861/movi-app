class PlayerActiveTracks {
  const PlayerActiveTracks({
    required this.audioTrackIds,
    required this.subtitleTrackIds,
    this.activeAudioTrackId,
    this.activeSubtitleTrackId,
  });

  final List<int> audioTrackIds;
  final List<int> subtitleTrackIds;
  final int? activeAudioTrackId;
  final int? activeSubtitleTrackId;
}
