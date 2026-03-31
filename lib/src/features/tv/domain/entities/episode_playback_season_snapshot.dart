import 'package:equatable/equatable.dart';

class EpisodePlaybackSeasonSnapshot extends Equatable {
  const EpisodePlaybackSeasonSnapshot({
    required this.seasonNumber,
    required this.episodeCount,
    this.firstEpisodeNumber,
    this.lastEpisodeNumber,
  });

  factory EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers({
    required int seasonNumber,
    required Iterable<int> episodeNumbers,
  }) {
    final sortedNumbers = episodeNumbers.toList(growable: false)..sort();
    if (sortedNumbers.isEmpty) {
      return EpisodePlaybackSeasonSnapshot(
        seasonNumber: seasonNumber,
        episodeCount: 0,
      );
    }

    return EpisodePlaybackSeasonSnapshot(
      seasonNumber: seasonNumber,
      episodeCount: sortedNumbers.length,
      firstEpisodeNumber: sortedNumbers.first,
      lastEpisodeNumber: sortedNumbers.last,
    );
  }

  final int seasonNumber;
  final int episodeCount;
  final int? firstEpisodeNumber;
  final int? lastEpisodeNumber;

  bool get usesGlobalNumbering {
    if (episodeCount == 0 ||
        firstEpisodeNumber == null ||
        lastEpisodeNumber == null) {
      return false;
    }
    if (firstEpisodeNumber! > 1) {
      return true;
    }
    return lastEpisodeNumber! > episodeCount;
  }

  @override
  List<Object?> get props => <Object?>[
    seasonNumber,
    episodeCount,
    firstEpisodeNumber,
    lastEpisodeNumber,
  ];
}
