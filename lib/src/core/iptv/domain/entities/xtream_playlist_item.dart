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
    this.rating,
    this.releaseYear,
    this.tmdbId,
  });

  final String accountId;
  final String categoryId;
  final String categoryName;
  final int streamId;
  final String title;
  final XtreamPlaylistItemType type;
  final String? overview;
  final String? posterUrl;
  final double? rating;
  final int? releaseYear;
  final int? tmdbId;

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
        rating,
        releaseYear,
        tmdbId,
      ];
}
