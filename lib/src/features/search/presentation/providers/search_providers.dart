// lib/src/features/search/presentation/providers/search_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/domain/usecases/search_instant.dart';
import 'package:movi/src/features/search/domain/usecases/search_paginated.dart';
import 'package:movi/src/features/search/presentation/models/search_results_args.dart';
import 'package:movi/src/features/search/presentation/controllers/search_instant_controller.dart';
import 'package:movi/src/features/search/presentation/controllers/search_paged_controller.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/search/data/datasources/tmdb_watch_providers_remote_data_source.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/search/domain/usecases/load_watch_providers.dart';
import 'package:movi/src/features/search/domain/entities/watch_provider.dart';
import 'package:movi/src/features/search/domain/entities/tmdb_genre.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/parental/domain/services/genre_maturity_checker.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final locator = ref.watch(slProvider);
  return locator<SearchRepository>();
});

final searchInstantUseCaseProvider = Provider<SearchInstant>(
  (ref) => SearchInstant(ref.watch(searchRepositoryProvider)),
);

final searchPaginatedUseCaseProvider = Provider<SearchPaginated>(
  (ref) => SearchPaginated(ref.watch(searchRepositoryProvider)),
);

final loadWatchProvidersUseCaseProvider = Provider<LoadWatchProviders>((ref) {
  final locator = ref.watch(slProvider);
  return locator<LoadWatchProviders>();
});

final searchControllerProvider =
    NotifierProvider<SearchInstantController, SearchState>(
      SearchInstantController.new,
    );

final searchResultsControllerProvider =
    NotifierProvider.family<
      SearchPagedController,
      SearchResultsState,
      SearchResultsPageArgs
    >(SearchPagedController.new);

/// Provider pour vérifier la disponibilité des films d'une saga dans la playlist
final sagaAvailabilityProvider =
    FutureProvider.family<({Saga? detail, Map<int, bool> availability}), SagaSummary>((
      ref,
      saga,
    ) async {
      final sagaRepo = ref.watch(slProvider)<SagaRepository>();
      final iptvLocal = ref.watch(slProvider)<IptvLocalRepository>();

      try {
        final sagaDetail = await sagaRepo.getSaga(saga.id);
        final availableIds = await iptvLocal.getAvailableTmdbIds(
          type: XtreamPlaylistItemType.movie,
        );

        final availabilityMap = <int, bool>{};
        for (final entry in sagaDetail.timeline) {
          if (entry.reference.type == ContentType.movie) {
            final movieId = int.tryParse(entry.reference.id);
            if (movieId != null) {
              availabilityMap[movieId] = availableIds.contains(movieId);
            }
          }
        }

        return (detail: sagaDetail, availability: availabilityMap);
      } catch (_) {
        return (detail: null, availability: <int, bool>{});
      }
    });

/// Provider pour filtrer les sagas qui ont au moins 1 film disponible dans la playlist
final filteredSagasProvider =
    FutureProvider.family<List<SagaSummary>, List<SagaSummary>>((
      ref,
      sagas,
    ) async {
      if (sagas.isEmpty) return const [];

      final profile = ref.watch(currentProfileProvider);
      final hasRestrictions = profile != null && (profile.isKid || profile.pegiLimit != null);
      final policy = hasRestrictions ? ref.read(parental.agePolicyProvider) : null;
      final classifier = ref.read(slProvider)<parental.PlaylistMaturityClassifier>();
      final profilePegi =
          parental.PegiRating.tryParse(profile?.pegiLimit) ??
          (profile?.isKid == true ? parental.PegiRating.pegi12 : null);

      final filtered = <SagaSummary>[];
      for (final saga in sagas) {
        final res = await ref.watch(
          sagaAvailabilityProvider(saga).future,
        );

        if (!res.availability.values.any((available) => available)) continue;

        if (hasRestrictions && policy != null && profilePegi != null) {
          final requiredByTitle = classifier.requiredPegiForPlaylistTitle(
            saga.title.value,
          );
          if (requiredByTitle != null && requiredByTitle > profilePegi.value) {
            continue;
          }

          final detail = res.detail;
          if (detail != null) {
            final timelineRefs = detail.timeline
                .map((e) => e.reference)
                .where(
                  (r) =>
                      r.type == ContentType.movie || r.type == ContentType.series,
                )
                .toList(growable: false);

            if (timelineRefs.isNotEmpty) {
              final allowed = await policy.filterAllowed(timelineRefs, profile);
              if (allowed.length != timelineRefs.length) {
                continue;
              }
            }
          }
        }

        filtered.add(saga);
      }

      return filtered;
    });

final watchProvidersRemoteDataSourceProvider =
    Provider<TmdbWatchProvidersRemoteDataSource>((ref) {
      final locator = ref.watch(slProvider);
      return locator<TmdbWatchProvidersRemoteDataSource>();
    });

/// IDs des fournisseurs de streaming dans l'ordre souhaité
const _providerOrder = [
  8, // Netflix
  337, // Disney+
  119, // Amazon Prime Video
  350, // Apple TV+
  1899, // HBO Max
  283, // Crunchyroll
];

/// Set des fournisseurs connus pour le filtrage
const _knownProviderIds = {
  8, // Netflix
  337, // Disney+
  119, // Amazon Prime Video
  350, // Apple TV+
  1899, // HBO Max
  283, // Crunchyroll
};

/// IDs de providers à exclure explicitement (variantes, channels, etc.)
const _excludedProviderIds = {
  2, // Apple TV (sans le +)
  531, // Paramount+ (retiré de la liste)
  582, // Paramount+ Amazon Channel
  2303, // Paramount Plus Premium
  2472, // HBO Max Amazon Channel
};

/// Provider pour récupérer la liste des watch providers disponibles.
/// Filtre uniquement les providers connus et les trie dans l'ordre spécifié.
final watchProvidersProvider = FutureProvider<List<WatchProvider>>((ref) async {
  final useCase = ref.watch(loadWatchProvidersUseCaseProvider);

  // On utilise 'FR' par défaut comme dans la logique précédente
  final providers = await useCase('FR');

  // Filtrer uniquement les providers connus
  final knownProviders = providers.where((provider) {
    // Exclure explicitement les IDs dans la liste d'exclusion
    if (_excludedProviderIds.contains(provider.providerId)) {
      return false;
    }
    // Inclure si l'ID est dans la liste des fournisseurs connus
    if (_knownProviderIds.contains(provider.providerId)) {
      return true;
    }
    // Exclure Canal VOD et autres variantes Canal
    final nameLower = provider.providerName.toLowerCase();
    if (nameLower.contains('canal')) {
      return false;
    }
    // Exclure Apple TV (sans le +) et autres variantes
    if (nameLower == 'apple tv' ||
        (nameLower.contains('apple tv') && !nameLower.contains('+'))) {
      return false;
    }
    // Exclure tous les Paramount+
    if (nameLower.contains('paramount')) {
      return false;
    }
    // Exclure les variantes HBO Max (Amazon channel, etc.)
    if (nameLower.contains('hbo')) {
      if (nameLower.contains('channel')) {
        return false;
      }
      // Ne garder que l'ID 1899 pour HBO Max principal
      return provider.providerId == 1899;
    }
    return false;
  }).toList();

  // Trier selon l'ordre spécifié
  knownProviders.sort((a, b) {
    final indexA = _providerOrder.indexOf(a.providerId);
    final indexB = _providerOrder.indexOf(b.providerId);

    // Si les deux sont dans l'ordre, utiliser leur position
    if (indexA != -1 && indexB != -1) {
      return indexA.compareTo(indexB);
    }
    // Si seul A est dans l'ordre, A vient en premier
    if (indexA != -1) return -1;
    // Si seul B est dans l'ordre, B vient en premier
    if (indexB != -1) return 1;
    // Sinon, trier par nom pour les autres
    return a.providerName.compareTo(b.providerName);
  });

  return knownProviders;
});

/// Modèle simple pour stocker le poster et backdrop d'un média populaire
class PopularMediaPoster {
  const PopularMediaPoster({
    required this.posterUrl,
    this.backdropUrl,
    this.isMovie = true,
  });

  final String? posterUrl;
  final String? backdropUrl;
  final bool isMovie;
}

/// Provider pour récupérer le média le plus populaire (premier résultat) pour un provider.
/// Récupère d'abord les films, puis les séries si aucun film n'est trouvé.
final providerPopularMediaProvider =
    FutureProvider.family<PopularMediaPoster?, int>((ref, providerId) async {
      try {
        final client = ref.watch(slProvider)<TmdbClient>();
        final imageResolver = ref.watch(slProvider)<TmdbImageResolver>();
        final language = ref.watch(asp.currentLanguageCodeProvider);
        final profile = ref.watch(currentProfileProvider);

        // For kid/restricted profiles, avoid showing "popular content" backdrops
        // in the providers grid: these visuals are not filtered and can display
        // inappropriate content.
        if (profile != null && (profile.isKid || profile.pegiLimit != null)) {
          return null;
        }

        // Essayer d'abord les films
        final moviesJson = await client.getJson(
          'discover/movie',
          query: {
            'with_watch_providers': providerId.toString(),
            'watch_region': 'FR',
            'page': 1,
            'sort_by': 'popularity.desc', // Tri par popularité décroissante
          },
          language: language,
        );

        final movieResults = moviesJson['results'] as List<dynamic>? ?? [];
        if (movieResults.isNotEmpty) {
          final firstMovie = movieResults.first as Map<String, dynamic>?;
          final posterPath = firstMovie?['poster_path'] as String?;
          final backdropPath = firstMovie?['backdrop_path'] as String?;
          if (posterPath != null && posterPath.isNotEmpty) {
            final posterUrl = imageResolver.poster(posterPath);
            final backdropUrl = backdropPath != null && backdropPath.isNotEmpty
                ? imageResolver.backdrop(backdropPath).toString()
                : null;
            return PopularMediaPoster(
              posterUrl: posterUrl.toString(),
              backdropUrl: backdropUrl,
              isMovie: true,
            );
          }
        }

        // Si aucun film trouvé, essayer les séries
        final tvJson = await client.getJson(
          'discover/tv',
          query: {
            'with_watch_providers': providerId.toString(),
            'watch_region': 'FR',
            'page': 1,
            'sort_by': 'popularity.desc', // Tri par popularité décroissante
          },
          language: language,
        );

        final tvResults = tvJson['results'] as List<dynamic>? ?? [];
        if (tvResults.isNotEmpty) {
          final firstTv = tvResults.first as Map<String, dynamic>?;
          final posterPath = firstTv?['poster_path'] as String?;
          final backdropPath = firstTv?['backdrop_path'] as String?;
          if (posterPath != null && posterPath.isNotEmpty) {
            final posterUrl = imageResolver.poster(posterPath);
            final backdropUrl = backdropPath != null && backdropPath.isNotEmpty
                ? imageResolver.backdrop(backdropPath).toString()
                : null;
            return PopularMediaPoster(
              posterUrl: posterUrl.toString(),
              backdropUrl: backdropUrl,
              isMovie: false,
            );
          }
        }

        return null;
      } catch (_) {
        return null;
      }
    });

/// Provider pour récupérer la liste des genres disponibles sur TMDB (films + séries).
///
/// Source:
/// - `genre/movie/list`
/// - `genre/tv/list`
final tmdbGenresProvider = FutureProvider<TmdbGenres>((ref) async {
  final client = ref.watch(slProvider)<TmdbClient>();
  final language = ref.watch(asp.currentLanguageCodeProvider);
  final profile = ref.watch(currentProfileProvider);
  final classifier = ref.watch(slProvider)<parental.PlaylistMaturityClassifier>();
  final profilePegi =
      parental.PegiRating.tryParse(profile?.pegiLimit) ??
      (profile?.isKid == true ? parental.PegiRating.pegi12 : null);

  List<TmdbGenre> parseGenres(Map<String, dynamic> json, ContentType type) {
    final raw = json['genres'];
    if (raw is! List) return const <TmdbGenre>[];
    final result = <TmdbGenre>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final id = item['id'];
      final name = item['name'];
      final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');
      final parsedName = name?.toString().trim() ?? '';
      if (parsedId == null || parsedName.isEmpty) continue;
      result.add(TmdbGenre(id: parsedId, name: parsedName, type: type));
    }
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (profilePegi == null) return result;

    // ID-based filtering using GenreMaturityChecker (locale-independent).
    // Filters genres based on PEGI requirements (Horror, Thriller, Crime, War, Film-Noir).
    // Applies to both movies and series.
    final filteredById = result.where((g) {
      return GenreMaturityChecker.isGenreAllowed(g.id, profilePegi.value);
    }).toList(growable: false);

    // Hide explicit mature genres for restricted profiles (ex: Horror/Thriller).
    // This complements the ID-based filtering by also checking genre names.
    final filtered = filteredById.where((g) {
      final required = classifier.requiredPegiForPlaylistTitle(g.name);
      return required == null || required <= profilePegi.value;
    }).toList(growable: false);
    return filtered;
  }

  final movieJson = await client.getJson(
    'genre/movie/list',
    language: language,
  );
  final tvJson = await client.getJson('genre/tv/list', language: language);

  return TmdbGenres(
    movie: parseGenres(movieJson, ContentType.movie),
    series: parseGenres(tvJson, ContentType.series),
  );
});
