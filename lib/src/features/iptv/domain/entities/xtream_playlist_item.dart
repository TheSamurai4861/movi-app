import 'package:equatable/equatable.dart';

enum XtreamPlaylistItemType { movie, series }

class XtreamPlaylistItem extends Equatable {
  const XtreamPlaylistItem({
    required this.accountId,
    required this.categoryId,
    required this.categoryName,
    required this.streamId,
    required this.title,
    required this.type,
    this.overview,
    this.posterUrl,
    this.containerExtension,
    this.rating,
    this.releaseYear,
    this.tmdbId,
    this.imdbId,
  });

  final String accountId;
  final String categoryId;
  final String categoryName;
  final int streamId;
  final String title;
  final XtreamPlaylistItemType type;
  final String? overview;
  final String? posterUrl;

  /// Extension de container renvoyée par certains panels Xtream (ex: "mkv", "mp4").
  ///
  /// Peut être absente ou non fiable selon les providers.
  final String? containerExtension;
  final double? rating;
  final int? releaseYear;
  final int? tmdbId;
  final String? imdbId;

  @override
  List<Object?> get props => [
    accountId,
    categoryId,
    categoryName,
    streamId,
    title,
    type,
    overview,
    posterUrl,
    containerExtension,
    rating,
    releaseYear,
    tmdbId,
    imdbId,
  ];
}
