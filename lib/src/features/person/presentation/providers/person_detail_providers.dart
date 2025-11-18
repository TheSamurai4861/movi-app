import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';
import 'package:movi/src/features/library/domain/repositories/favorites_repository.dart';
import 'package:movi/src/features/library/data/repositories/favorites_repository_impl.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';

/// Provider pour FavoritesRepository avec userId actuel
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return FavoritesRepositoryImpl(
    ref.watch(slProvider)<WatchlistLocalRepository>(),
    userId: userId,
  );
});

/// Provider pour vérifier si une personne est dans les favoris
final personIsFavoriteProvider =
    FutureProvider.family<bool, String>((ref, personId) async {
  final watchlist = ref.watch(slProvider)<WatchlistLocalRepository>();
  return await watchlist.exists(
    personId,
    ContentType.person,
    userId: ref.read(currentUserIdProvider),
  );
});

/// Notifier pour basculer le statut favori d'une personne
class PersonToggleFavoriteNotifier extends Notifier<void> {
  @override
  void build() {
    // État initial vide, la méthode toggle() fait le travail
  }

  Future<void> toggle(String personId) async {
    final favoritesRepo = ref.read(favoritesRepositoryProvider);
    final isFavorite = await ref.read(personIsFavoriteProvider(personId).future);
    final personRepo = ref.read(slProvider)<PersonRepository>();
    final person = await personRepo.getPerson(PersonId(personId));
    
    if (isFavorite) {
      await favoritesRepo.unlikePerson(PersonId(personId));
    } else {
      await favoritesRepo.likePerson(
        id: PersonId(personId),
        name: person.name.display,
        photo: person.photo,
      );
    }
    ref.invalidate(personIsFavoriteProvider(personId));
    // Invalider les playlists de la bibliothèque pour mettre à jour les favoris
    ref.invalidate(libraryPlaylistsProvider);
  }
}

/// Provider pour basculer le statut favori d'une personne
final personToggleFavoriteProvider =
    NotifierProvider<PersonToggleFavoriteNotifier, void>(
  PersonToggleFavoriteNotifier.new,
);

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

  final String name;
  final Uri? photo;
  final int moviesCount;
  final int showsCount;
  final List<MovieSummary> movies;
  final List<TvShowSummary> shows;
  final String? biography;
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
    biography: person.biography,
  );
});

