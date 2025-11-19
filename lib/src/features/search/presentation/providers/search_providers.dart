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
import 'package:movi/src/features/search/data/dtos/tmdb_watch_provider_dto.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';

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
    FutureProvider.family<Map<int, bool>, SagaSummary>((ref, saga) async {
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

        return availabilityMap;
      } catch (_) {
        return <int, bool>{};
      }
    });

/// Provider pour filtrer les sagas qui ont au moins 1 film disponible dans la playlist
final filteredSagasProvider =
    FutureProvider.family<List<SagaSummary>, List<SagaSummary>>((
      ref,
      sagas,
    ) async {
      if (sagas.isEmpty) return const [];

      final filtered = <SagaSummary>[];
      for (final saga in sagas) {
        final availability = await ref.watch(
          sagaAvailabilityProvider(saga).future,
        );
        if (availability.values.any((available) => available)) {
          filtered.add(saga);
        }
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
final watchProvidersProvider = FutureProvider<List<TmdbWatchProviderDto>>((
  ref,
) async {
  final dataSource = ref.watch(watchProvidersRemoteDataSourceProvider);
  final language = ref.watch(asp.currentLanguageCodeProvider);

  final providers = await dataSource.fetchWatchProviders(language: language);

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
