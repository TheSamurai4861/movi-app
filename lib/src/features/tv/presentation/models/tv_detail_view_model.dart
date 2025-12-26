import 'package:flutter/material.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/l10n/app_localizations.dart';

class TvDetailViewModel {
  TvDetailViewModel({
    required this.title,
    required this.yearText,
    required this.seasonsCountText,
    required this.ratingText,
    required this.overviewText,
    required this.cast,
    required this.seasons,
    required this.poster,
    required this.backdrop,
    required this.language,
  });

  final String title;
  final String yearText;
  final String seasonsCountText;
  final String ratingText;
  final String overviewText;
  final List<MoviPerson> cast;
  final List<SeasonViewModel> seasons;
  final Uri? poster;
  final Uri? backdrop;
  final String language;

  factory TvDetailViewModel.fromDomain({
    required TvShow detail,
    required String language,
    bool isAvailableInPlaylist = true,
  }) {
    // Parse locale from language code
    final locale = _parseLocale(language);
    final localizations = lookupAppLocalizations(locale);

    // Map creators first (directors)
    final creators = detail.creators
        .map(
          (p) => MoviPerson(
            id: p.id.value,
            name: p.name,
            role: p.role ?? localizations.personRoleCreator,
            poster: p.photo,
          ),
        )
        .toList(growable: false);

    // Map cast
    final castMembers = detail.cast
        .map(
          (p) => MoviPerson(
            id: p.id.value,
            name: p.name,
            role: p.role ?? '-',
            poster: p.photo,
          ),
        )
        .toList(growable: false);

    // Combine creators first, then cast
    final cast = [...creators, ...castMembers];

    final seasons = detail.seasons
        .map(
          (s) => SeasonViewModel(
            id: s.id.value,
            seasonNumber: s.seasonNumber,
            title: s.title.display,
            episodes: s.episodes
                .map(
                  (e) => EpisodeViewModel(
                    id: e.id.value,
                    episodeNumber: e.episodeNumber,
                    title: e.title.display,
                    overview: e.overview?.value,
                    runtime: e.runtime,
                    airDate: e.airDate,
                    still: e.still,
                    voteAverage: e.voteAverage,
                    isAvailableInPlaylist: isAvailableInPlaylist,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    // Format rating text (same logic as MovieDetailViewModel)
    final ratingText = detail.voteAverage != null
        ? (detail.voteAverage! >= 10
              ? detail.voteAverage!.toStringAsFixed(0)
              : detail.voteAverage!.toStringAsFixed(1))
        : '—';

    // Format seasons count
    final seasonsCount = detail.seasons.length;
    final seasonsCountText = seasonsCount == 1
        ? '$seasonsCount ${localizations.playlistSeasonSingular}'
        : '$seasonsCount ${localizations.playlistSeasonPlural}';

    return TvDetailViewModel(
      title: detail.title.display,
      yearText: detail.firstAirDate?.year.toString() ?? '—',
      seasonsCountText: seasonsCountText,
      ratingText: ratingText,
      overviewText: detail.synopsis.value,
      cast: cast,
      seasons: seasons,
      poster: detail.poster,
      backdrop: detail.backdrop,
      language: language,
    );
  }

  static Locale _parseLocale(String code) {
    final parts = code.split('-');
    final language = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'en';
    final country = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'US';
    return Locale(language, country);
  }
}

class SeasonViewModel {
  SeasonViewModel({
    required this.id,
    required this.seasonNumber,
    required this.title,
    required this.episodes,
    this.isLoadingEpisodes = false,
  });

  final String id;
  final int seasonNumber;
  final String title;
  final List<EpisodeViewModel> episodes;
  final bool isLoadingEpisodes;

  SeasonViewModel copyWith({
    String? id,
    int? seasonNumber,
    String? title,
    List<EpisodeViewModel>? episodes,
    bool? isLoadingEpisodes,
  }) {
    return SeasonViewModel(
      id: id ?? this.id,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      title: title ?? this.title,
      episodes: episodes ?? this.episodes,
      isLoadingEpisodes: isLoadingEpisodes ?? this.isLoadingEpisodes,
    );
  }
}

class EpisodeViewModel {
  EpisodeViewModel({
    required this.id,
    required this.episodeNumber,
    required this.title,
    this.overview,
    this.runtime,
    this.airDate,
    this.still,
    this.voteAverage,
    this.isAvailableInPlaylist = true,
  });

  final String id;
  final int episodeNumber;
  final String title;
  final String? overview;
  final Duration? runtime;
  final DateTime? airDate;
  final Uri? still;
  final double? voteAverage;
  final bool isAvailableInPlaylist;
}
