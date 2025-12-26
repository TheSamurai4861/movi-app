import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';
import 'package:movi/src/features/library/domain/repositories/favorites_repository.dart';
import 'package:movi/src/features/library/data/repositories/favorites_repository_impl.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/person/presentation/models/person_detail_view_model.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/person/data/datasources/tmdb_person_remote_data_source.dart';
import 'package:movi/src/features/person/data/datasources/person_local_data_source.dart';
import 'package:movi/src/features/person/data/repositories/person_repository_impl.dart';
import 'package:movi/src/features/person/domain/usecases/get_featured_people.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';

/// Provider pour FavoritesRepository avec userId actuel
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return FavoritesRepositoryImpl(
    ref.watch(slProvider)<WatchlistLocalRepository>(),
    userId: userId,
  );
});

/// DI unifiée — Person: Remote DS
final tmdbPersonRemoteDataSourceProvider =
    Provider<TmdbPersonRemoteDataSource>((ref) {
  final client = ref.watch(slProvider)<TmdbClient>();
  return TmdbPersonRemoteDataSource(client);
});

/// DI unifiée — Person: Local DS
final personLocalDataSourceProvider = Provider<PersonLocalDataSource>((ref) {
  final cache = ref.watch(slProvider)<ContentCacheRepository>();
  final locale = ref.watch(slProvider)<LocalePreferences>();
  return PersonLocalDataSource(cache, locale);
});

/// DI unifiée — Person: Repository
final personRepositoryProvider = Provider<PersonRepository>((ref) {
  final remote = ref.watch(tmdbPersonRemoteDataSourceProvider);
  final images = ref.watch(slProvider)<TmdbImageResolver>();
  final local = ref.watch(personLocalDataSourceProvider);
  final locale = ref.watch(slProvider)<LocalePreferences>();
  return PersonRepositoryImpl(remote, images, local, locale);
});

/// Use case provider — GetFeaturedPeople
final getFeaturedPeopleUseCaseProvider = Provider<GetFeaturedPeople>((ref) {
  final repo = ref.watch(personRepositoryProvider);
  return GetFeaturedPeople(repo);
});

/// Featured people list (popular)
final featuredPeopleProvider = FutureProvider<List<PersonSummary>>((ref) async {
  final usecase = ref.watch(getFeaturedPeopleUseCaseProvider);
  return usecase();
});

/// Provider pour vérifier si une personne est dans les favoris
final personIsFavoriteProvider = FutureProvider.family<bool, String>((
  ref,
  personId,
) async {
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
    final isFavorite = await ref.read(
      personIsFavoriteProvider(personId).future,
    );
    final personRepo = ref.read(personRepositoryProvider);
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

// PersonDetailViewModel moved to presentation/models to keep providers focused.

final personDetailControllerProvider =
    FutureProvider.family<PersonDetailViewModel, String>((ref, personId) async {
      final personRepo = ref.watch(personRepositoryProvider);
      final iptvLocal = ref.watch(slProvider)<IptvLocalRepository>();

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
