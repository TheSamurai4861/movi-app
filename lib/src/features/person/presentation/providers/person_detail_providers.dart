import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class PersonDetailViewModel {
  const PersonDetailViewModel({
    required this.name,
    required this.photo,
    required this.moviesCount,
    required this.showsCount,
    required this.movies,
    required this.shows,
  });

  final String name;
  final Uri? photo;
  final int moviesCount;
  final int showsCount;
  final List<MovieSummary> movies;
  final List<TvShowSummary> shows;
}

final personDetailControllerProvider =
    FutureProvider.family<PersonDetailViewModel, String>((ref, personId) async {
  final locator = ref.watch(slProvider);
  final personRepo = locator<PersonRepository>();
  final iptvLocal = locator<IptvLocalRepository>();

  final id = PersonId(personId);
  final person = await personRepo.getPerson(id);

  // Récupérer les IDs disponibles dans la playlist IPTV
  final availableMovieIds = await iptvLocal.getAvailableTmdbIds(
    type: XtreamPlaylistItemType.movie,
  );
  final availableShowIds = await iptvLocal.getAvailableTmdbIds(
    type: XtreamPlaylistItemType.series,
  );

  // Filtrer la filmographie pour ne garder que les films/séries disponibles
  final movies = <MovieSummary>[];
  final shows = <TvShowSummary>[];

  for (final credit in person.filmography) {
    final tmdbId = int.tryParse(credit.reference.id);
    if (tmdbId == null) continue;

    if (credit.reference.type == ContentType.movie &&
        availableMovieIds.contains(tmdbId) &&
        credit.reference.poster != null) {
      movies.add(
        MovieSummary(
          id: MovieId(credit.reference.id),
          tmdbId: tmdbId,
          title: credit.reference.title,
          poster: credit.reference.poster!,
          backdrop: null,
          releaseYear: credit.year,
        ),
      );
    } else if (credit.reference.type == ContentType.series &&
        availableShowIds.contains(tmdbId) &&
        credit.reference.poster != null) {
      shows.add(
        TvShowSummary(
          id: SeriesId(credit.reference.id),
          tmdbId: tmdbId,
          title: credit.reference.title,
          poster: credit.reference.poster!,
          backdrop: null,
          seasonCount: null,
          status: null,
        ),
      );
    }
  }

  return PersonDetailViewModel(
    name: person.name.display,
    photo: person.photo,
    moviesCount: movies.length,
    showsCount: shows.length,
    movies: movies,
    shows: shows,
  );
});

