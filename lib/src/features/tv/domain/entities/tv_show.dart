import 'package:equatable/equatable.dart';

import '../../../../shared/domain/entities/person_summary.dart';
import '../../../../shared/domain/value_objects/media_id.dart';
import '../../../../shared/domain/value_objects/media_title.dart';
import '../../../../shared/domain/value_objects/synopsis.dart';
import '../../../../shared/domain/value_objects/content_rating.dart';

class TvShow extends Equatable {
  const TvShow({
    required this.id,
    this.tmdbId,
    required this.title,
    required this.synopsis,
    required this.poster,
    this.backdrop,
    this.firstAirDate,
    this.lastAirDate,
    this.status,
    this.rating,
    this.genres = const [],
    this.cast = const [],
    this.creators = const [],
    this.seasons = const [],
  });

  final SeriesId id;
  final int? tmdbId;
  final MediaTitle title;
  final Synopsis synopsis;
  final Uri poster;
  final Uri? backdrop;
  final DateTime? firstAirDate;
  final DateTime? lastAirDate;
  final SeriesStatus? status;
  final ContentRating? rating;
  final List<String> genres;
  final List<PersonSummary> cast;
  final List<PersonSummary> creators;
  final List<Season> seasons;

  @override
  List<Object?> get props => [
        id,
        tmdbId,
        title,
        synopsis,
        poster,
        backdrop,
        firstAirDate,
        lastAirDate,
        status,
        rating,
        genres,
        cast,
        creators,
        seasons,
      ];
}

class Season extends Equatable {
  const Season({
    required this.id,
    required this.seasonNumber,
    required this.title,
    this.overview,
    this.poster,
    this.episodes = const [],
    this.airDate,
  });

  final SeasonId id;
  final int seasonNumber;
  final MediaTitle title;
  final Synopsis? overview;
  final Uri? poster;
  final List<Episode> episodes;
  final DateTime? airDate;

  @override
  List<Object?> get props => [
        id,
        seasonNumber,
        title,
        overview,
        poster,
        episodes,
        airDate,
      ];
}

class Episode extends Equatable {
  const Episode({
    required this.id,
    required this.episodeNumber,
    required this.title,
    this.overview,
    this.runtime,
    this.airDate,
    this.still,
  });

  final EpisodeId id;
  final int episodeNumber;
  final MediaTitle title;
  final Synopsis? overview;
  final Duration? runtime;
  final DateTime? airDate;
  final Uri? still;

  @override
  List<Object?> get props => [
        id,
        episodeNumber,
        title,
        overview,
        runtime,
        airDate,
        still,
      ];
}

class TvShowSummary extends Equatable {
  const TvShowSummary({
    required this.id,
    this.tmdbId,
    required this.title,
    required this.poster,
    this.backdrop,
    this.seasonCount,
    this.status,
  });

  final SeriesId id;
  final int? tmdbId;
  final MediaTitle title;
  final Uri poster;
  final Uri? backdrop;
  final int? seasonCount;
  final SeriesStatus? status;

  @override
  List<Object?> get props => [id, tmdbId, title, poster, backdrop, seasonCount, status];
}

enum SeriesStatus { ongoing, ended, hiatus }
