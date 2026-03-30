import 'package:movi/src/features/player/domain/value_objects/track_info.dart';
import 'package:movi/src/features/player/presentation/utils/track_label_formatter.dart';

enum PreferredTrackSelectionStatus {
  noPreference,
  noTracksAvailable,
  matchFound,
  noMatchFound,
  disableRequested,
}

class PreferredTrackSelection {
  const PreferredTrackSelection({
    required this.type,
    required this.status,
    this.preferredLanguageCode,
    this.requestedTrack,
  });

  final TrackType type;
  final PreferredTrackSelectionStatus status;
  final String? preferredLanguageCode;
  final TrackInfo? requestedTrack;

  bool get hasPreference =>
      preferredLanguageCode != null && preferredLanguageCode!.isNotEmpty;
}

class PreferredTracksSelection {
  const PreferredTracksSelection({required this.audio, required this.subtitle});

  final PreferredTrackSelection audio;
  final PreferredTrackSelection subtitle;
}

class PreferredTracksApplicationPlan {
  const PreferredTracksApplicationPlan({
    required this.selection,
    required this.fingerprint,
    required this.shouldApply,
  });

  final PreferredTracksSelection selection;
  final String fingerprint;
  final bool shouldApply;
}

class PreferredTracksSelector {
  const PreferredTracksSelector();

  PreferredTracksSelection select({
    required List<TrackInfo> audioTracks,
    required List<TrackInfo> subtitleTracks,
    required String? preferredAudioLanguageCode,
    required String? preferredSubtitleLanguageCode,
  }) {
    return PreferredTracksSelection(
      audio: _selectAudioTrack(
        tracks: audioTracks,
        preferredLanguageCode: preferredAudioLanguageCode,
      ),
      subtitle: _selectSubtitleTrack(
        tracks: subtitleTracks,
        preferredLanguageCode: preferredSubtitleLanguageCode,
      ),
    );
  }

  PreferredTracksApplicationPlan plan({
    required List<TrackInfo> audioTracks,
    required List<TrackInfo> subtitleTracks,
    required String? preferredAudioLanguageCode,
    required String? preferredSubtitleLanguageCode,
    required int? currentAudioTrackId,
    required int? currentSubtitleTrackId,
    required bool subtitlesEnabled,
    String? previousFingerprint,
  }) {
    final selection = select(
      audioTracks: audioTracks,
      subtitleTracks: subtitleTracks,
      preferredAudioLanguageCode: preferredAudioLanguageCode,
      preferredSubtitleLanguageCode: preferredSubtitleLanguageCode,
    );
    final fingerprint = _buildFingerprint(
      selection: selection,
      audioTracks: audioTracks,
      subtitleTracks: subtitleTracks,
      currentAudioTrackId: currentAudioTrackId,
      currentSubtitleTrackId: currentSubtitleTrackId,
      subtitlesEnabled: subtitlesEnabled,
    );
    return PreferredTracksApplicationPlan(
      selection: selection,
      fingerprint: fingerprint,
      shouldApply: fingerprint != previousFingerprint,
    );
  }

  PreferredTrackSelection _selectAudioTrack({
    required List<TrackInfo> tracks,
    required String? preferredLanguageCode,
  }) {
    final normalizedPreference = TrackLabelFormatter.normalizeLanguageCode(
      preferredLanguageCode,
    );
    if (normalizedPreference == null) {
      return const PreferredTrackSelection(
        type: TrackType.audio,
        status: PreferredTrackSelectionStatus.noPreference,
      );
    }
    if (tracks.isEmpty) {
      return PreferredTrackSelection(
        type: TrackType.audio,
        status: PreferredTrackSelectionStatus.noTracksAvailable,
        preferredLanguageCode: normalizedPreference,
      );
    }

    final requestedTrack = _findMatchingTrack(
      tracks: tracks,
      preferredLanguageCode: normalizedPreference,
    );
    if (requestedTrack == null) {
      return PreferredTrackSelection(
        type: TrackType.audio,
        status: PreferredTrackSelectionStatus.noMatchFound,
        preferredLanguageCode: normalizedPreference,
      );
    }

    return PreferredTrackSelection(
      type: TrackType.audio,
      status: PreferredTrackSelectionStatus.matchFound,
      preferredLanguageCode: normalizedPreference,
      requestedTrack: requestedTrack,
    );
  }

  PreferredTrackSelection _selectSubtitleTrack({
    required List<TrackInfo> tracks,
    required String? preferredLanguageCode,
  }) {
    final normalizedPreference = TrackLabelFormatter.normalizeLanguageCode(
      preferredLanguageCode,
    );
    if (normalizedPreference == null) {
      return const PreferredTrackSelection(
        type: TrackType.subtitle,
        status: PreferredTrackSelectionStatus.disableRequested,
      );
    }
    if (tracks.isEmpty) {
      return PreferredTrackSelection(
        type: TrackType.subtitle,
        status: PreferredTrackSelectionStatus.noTracksAvailable,
        preferredLanguageCode: normalizedPreference,
      );
    }

    final requestedTrack = _findMatchingTrack(
      tracks: tracks,
      preferredLanguageCode: normalizedPreference,
    );
    if (requestedTrack == null) {
      return PreferredTrackSelection(
        type: TrackType.subtitle,
        status: PreferredTrackSelectionStatus.noMatchFound,
        preferredLanguageCode: normalizedPreference,
      );
    }

    return PreferredTrackSelection(
      type: TrackType.subtitle,
      status: PreferredTrackSelectionStatus.matchFound,
      preferredLanguageCode: normalizedPreference,
      requestedTrack: requestedTrack,
    );
  }

  TrackInfo? _findMatchingTrack({
    required List<TrackInfo> tracks,
    required String preferredLanguageCode,
  }) {
    for (final track in tracks) {
      final languageCode = TrackLabelFormatter.getLanguageCode(track);
      if (languageCode == preferredLanguageCode) {
        return track;
      }
    }
    return null;
  }

  String _buildFingerprint({
    required PreferredTracksSelection selection,
    required List<TrackInfo> audioTracks,
    required List<TrackInfo> subtitleTracks,
    required int? currentAudioTrackId,
    required int? currentSubtitleTrackId,
    required bool subtitlesEnabled,
  }) {
    return <String>[
      'audioTracks=${_tracksSignature(audioTracks)}',
      'subtitleTracks=${_tracksSignature(subtitleTracks)}',
      'currentAudio=$currentAudioTrackId',
      'currentSubtitle=$currentSubtitleTrackId',
      'subtitlesEnabled=$subtitlesEnabled',
      'audioStatus=${selection.audio.status.name}',
      'audioPreference=${selection.audio.preferredLanguageCode ?? ''}',
      'audioRequested=${selection.audio.requestedTrack?.id ?? 'none'}',
      'subtitleStatus=${selection.subtitle.status.name}',
      'subtitlePreference=${selection.subtitle.preferredLanguageCode ?? ''}',
      'subtitleRequested=${selection.subtitle.requestedTrack?.id ?? 'none'}',
    ].join('|');
  }

  String _tracksSignature(List<TrackInfo> tracks) {
    return tracks
        .map(
          (track) =>
              '${track.type.name}:${track.id}:${track.language ?? ''}:${track.title ?? ''}',
        )
        .join(',');
  }
}
