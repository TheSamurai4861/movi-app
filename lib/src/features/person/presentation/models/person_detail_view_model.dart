// lib/src/features/person/presentation/models/person_detail_view_model.dart
// View model for the Person detail page. Keeps UI-friendly data only.

import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';

/// UI-facing model for person detail.
/// Contains pre-filtered filmography items and display-ready fields.
class PersonDetailViewModel {
  const PersonDetailViewModel({
    required this.name,
    required this.photo,
    required this.moviesCount,
    required this.showsCount,
    required this.movies,
    required this.shows,
    this.biography,
  });

  /// Person display name.
  final String name;

  /// Optional profile photo URI.
  final Uri? photo;

  /// Count of available movies.
  final int moviesCount;

  /// Count of available TV shows.
  final int showsCount;

  /// Filtered movies available on IPTV with posters.
  final List<MovieSummary> movies;

  /// Filtered TV shows available on IPTV with posters.
  final List<TvShowSummary> shows;

  /// Optional biography text.
  final String? biography;
}