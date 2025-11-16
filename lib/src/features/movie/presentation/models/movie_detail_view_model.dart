import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/features/movie/domain/entities/movie.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';

class MovieDetailViewModel {
  MovieDetailViewModel({
    required this.title,
    required this.yearText,
    required this.durationText,
    required this.ratingText,
    required this.overviewText,
    required this.cast,
    required this.recommendations,
    required this.poster,
    required this.backdrop,
    required this.language,
  });

  final String title;
  final String yearText;
  final String durationText;
  final String ratingText;
  final String overviewText;
  final List<MoviPerson> cast;
  final List<MoviMedia> recommendations;
  final Uri? poster;
  final Uri? backdrop;
  final String language;

  factory MovieDetailViewModel.fromDomain({
    required Movie detail,
    required Iterable<PersonSummary> credits,
    required Iterable<MovieSummary> recommendations,
    required String language,
  }) {
    final dur = detail.duration;
    final h = dur.inHours;
    final mn = dur.inMinutes % 60;
    final cast = credits
        .map(
          (p) => MoviPerson(
            id: p.id.value,
            name: p.name,
            role: p.role ?? '-',
            poster: p.photo,
          ),
        )
        .toList(growable: false);
    final recos = recommendations
        .map(
          (r) => MoviMedia(
            id: r.id.value,
            title: r.title.display,
            poster: r.poster,
            year: r.releaseYear,
            type: MoviMediaType.movie,
          ),
        )
        .toList(growable: false);
    return MovieDetailViewModel(
      title: detail.title.display,
      yearText: detail.releaseDate.year.toString(),
      durationText: '${h}h ${mn}m',
      ratingText: detail.voteAverage != null
          ? (detail.voteAverage! >= 10
                ? detail.voteAverage!.toStringAsFixed(0)
                : detail.voteAverage!.toStringAsFixed(1))
          : '—',
      overviewText: detail.synopsis.value,
      cast: cast,
      recommendations: recos,
      poster: detail.poster,
      backdrop: detail.backdrop,
      language: language,
    );
  }
}
