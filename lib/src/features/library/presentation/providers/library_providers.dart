import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/features/library/domain/repositories/library_repository.dart';
import 'package:movi/src/features/library/data/repositories/library_repository_impl.dart';
import 'package:movi/src/features/library/presentation/widgets/library_filter_pills.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/features/person/person.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/l10n/app_localizations.dart';

/// Exposes the LibraryRepository to the presentation layer.
/// Le repository est créé avec l'ID utilisateur actuel pour filtrer les favoris.
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return LibraryRepositoryImpl(
    ref.watch(slProvider)<WatchlistLocalRepository>(),
    ref.watch(slProvider)<HistoryLocalRepository>(),
    ref.watch(slProvider)<PlaylistRepository>(),
    ref.watch(slProvider)<PersonRepository>(),
    userId: userId,
  );
});

/// Exposes the PlaylistRepository to the presentation layer.
final playlistRepositoryProvider = Provider<PlaylistRepository>(
  (ref) => ref.watch(slProvider)<PlaylistRepository>(),
);

/// Model pour représenter une playlist dans la bibliothèque
class LibraryPlaylistItem {
  const LibraryPlaylistItem({
    required this.id,
    required this.title,
    required this.itemCount,
    required this.type,
    this.isPinned = false,
    this.playlistId,
    this.photo, // Photo de profil pour les artistes
  });

  final String id;
  final String title;
  final int itemCount;
  final LibraryPlaylistType type;
  final bool isPinned;
  final String? playlistId; // Pour les playlists utilisateur
  final Uri? photo; // Photo de profil pour les artistes
}

/// Provider pour charger toutes les playlists de la bibliothèque
final libraryPlaylistsProvider = FutureProvider<List<LibraryPlaylistItem>>((
  ref,
) async {
  final repository = ref.watch(libraryRepositoryProvider);
  final locale = ref.watch(currentLocaleProvider);
  final localizations = lookupAppLocalizations(locale);

  final playlists = <LibraryPlaylistItem>[];

  // Médias en cours de lecture
  final inProgress = await repository.getHistoryInProgress();
  if (inProgress.isNotEmpty) {
    playlists.add(
      LibraryPlaylistItem(
        id: 'in_progress',
        title: localizations.libraryInProgress,
        itemCount: inProgress.length,
        type: LibraryPlaylistType.inProgress,
        isPinned: true,
      ),
    );
  }

  // Films favoris
  final favoriteMovies = await repository.getLikedMovies();
  if (favoriteMovies.isNotEmpty) {
    playlists.add(
      LibraryPlaylistItem(
        id: 'favorite_movies',
        title: localizations.libraryFavoriteMovies,
        itemCount: favoriteMovies.length,
        type: LibraryPlaylistType.favoriteMovies,
        isPinned: true,
      ),
    );
  }

  // Séries favorites
  final favoriteSeries = await repository.getLikedShows();
  if (favoriteSeries.isNotEmpty) {
    playlists.add(
      LibraryPlaylistItem(
        id: 'favorite_series',
        title: localizations.libraryFavoriteSeries,
        itemCount: favoriteSeries.length,
        type: LibraryPlaylistType.favoriteSeries,
        isPinned: true,
      ),
    );
  }

  // Historique de visionnage
  final historyCompleted = await repository.getHistoryCompleted();
  final historyInProgress = await repository.getHistoryInProgress();
  final totalHistory = historyCompleted.length + historyInProgress.length;
  if (totalHistory > 0) {
    playlists.add(
      LibraryPlaylistItem(
        id: 'watch_history',
        title: localizations.libraryWatchHistory,
        itemCount: totalHistory,
        type: LibraryPlaylistType.watchHistory,
        isPinned: true,
      ),
    );
  }

  // Playlists utilisateur
  final userId = ref.read(currentUserIdProvider);
  final playlistRepository = ref.watch(playlistRepositoryProvider);
  final userPlaylists = await repository.getUserPlaylists(userId);
  for (final playlist in userPlaylists) {
    // Charger le nombre réel d'éléments depuis la playlist complète
    int itemCount = 0;
    try {
      final playlistDetail = await playlistRepository.getPlaylist(playlist.id);
      itemCount = playlistDetail.items.length;
    } catch (_) {
      // Si erreur, utiliser itemCount du summary ou 0
      itemCount = playlist.itemCount ?? 0;
    }
    
    playlists.add(
      LibraryPlaylistItem(
        id: 'playlist_${playlist.id.value}',
        title: playlist.title.value,
        itemCount: itemCount,
        type: LibraryPlaylistType.userPlaylist,
        playlistId: playlist.id.value,
      ),
    );
  }

  // Acteurs likés
  final likedPersons = await repository.getLikedPersons();
  for (final person in likedPersons) {
    playlists.add(
      LibraryPlaylistItem(
        id: 'actor_${person.id.value}',
        title: person.name,
        itemCount: 0, // Les acteurs n'ont pas de compteur d'éléments
        type: LibraryPlaylistType.actor,
        photo: person.photo, // Photo de profil de l'artiste
      ),
    );
  }

  // Sagas likées
  final likedSagas = await repository.getLikedSagas();
  for (final saga in likedSagas) {
    playlists.add(
      LibraryPlaylistItem(
        id: 'saga_${saga.id.value}',
        title: saga.title.value,
        itemCount: 0, 
        type: LibraryPlaylistType.userPlaylist, // Utiliser un type approprié
        photo: saga.cover, // Image hero de la saga
      ),
    );
  }

  // Trier les playlists : "En cours" en premier, puis les autres favoris (isPinned: true)
  playlists.sort((a, b) {
    // "En cours" toujours en premier
    if (a.type == LibraryPlaylistType.inProgress &&
        b.type != LibraryPlaylistType.inProgress) {
      return -1;
    }
    if (a.type != LibraryPlaylistType.inProgress &&
        b.type == LibraryPlaylistType.inProgress) {
      return 1;
    }
    // Ensuite les autres favoris
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;
    return 0; // Conserver l'ordre pour les autres
  });

  return playlists;
});

/// Contrôleur pour la recherche dans la bibliothèque
class LibrarySearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

/// Provider pour la recherche dans la bibliothèque
final librarySearchQueryProvider =
    NotifierProvider<LibrarySearchQueryController, String>(
      LibrarySearchQueryController.new,
    );

/// Provider pour filtrer les playlists selon le type de filtre actif et la recherche
final filteredLibraryPlaylistsProvider =
    Provider<AsyncValue<List<LibraryPlaylistItem>>>((ref) {
      final filter = ref.watch(libraryFilterProvider);
      final searchQuery = ref.watch(librarySearchQueryProvider);
      final playlistsAsync = ref.watch(libraryPlaylistsProvider);

      return playlistsAsync.when(
        data: (playlists) {
          var filtered = playlists;

          // Appliquer le filtre de type
          if (filter != null) {
            filtered = filtered.where((playlist) {
              switch (filter) {
                case LibraryFilterType.playlists:
                  // Exclure les sagas et les acteurs
                  return !playlist.id.startsWith('saga_') &&
                      playlist.type != LibraryPlaylistType.actor &&
                      (playlist.type == LibraryPlaylistType.inProgress ||
                          playlist.type == LibraryPlaylistType.favoriteMovies ||
                          playlist.type == LibraryPlaylistType.favoriteSeries ||
                          playlist.type == LibraryPlaylistType.watchHistory ||
                          playlist.type == LibraryPlaylistType.userPlaylist);
                case LibraryFilterType.sagas:
                  // Filtrer les sagas (id commence par 'saga_')
                  return playlist.id.startsWith('saga_');
                case LibraryFilterType.artistes:
                  return playlist.type == LibraryPlaylistType.actor;
              }
            }).toList();
          }

          // Appliquer la recherche
          if (searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase().trim();
            filtered = filtered.where((playlist) {
              return playlist.title.toLowerCase().contains(query);
            }).toList();
          }

          return AsyncValue.data(filtered);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });

/// Contrôleur pour le filtre actif
class LibraryFilterController extends Notifier<LibraryFilterType?> {
  @override
  LibraryFilterType? build() => null;

  void setFilter(LibraryFilterType? filter) {
    state = filter;
  }
}

/// Provider pour le filtre actif
final libraryFilterProvider =
    NotifierProvider<LibraryFilterController, LibraryFilterType?>(
      LibraryFilterController.new,
    );

/// Provider pour charger les items d'une playlist spécifique (avec positions)
final playlistItemsProvider = FutureProvider.family<List<PlaylistItem>, String>((ref, playlistId) async {
  final playlistRepository = ref.watch(playlistRepositoryProvider);
  
  try {
    final playlistDetail = await playlistRepository.getPlaylist(PlaylistId(playlistId));
    return playlistDetail.items;
  } catch (e) {
    return [];
  }
});

/// Provider pour charger les ContentReference d'une playlist (pour compatibilité)
/// Enrichit les ContentReference avec les années depuis TMDB si manquantes
final playlistContentReferencesProvider = FutureProvider.family<List<ContentReference>, String>((ref, playlistId) async {
  final itemsAsync = ref.watch(playlistItemsProvider(playlistId));
  
  return itemsAsync.when(
    loading: () => <ContentReference>[],
    error: (_, __) => <ContentReference>[],
    data: (items) async {
      final references = items.map((item) => item.reference).toList();
      
      // Enrichir avec les années depuis TMDB pour les items sans année
      final sl = ref.read(slProvider);
      final tmdbClient = sl<TmdbClient>();
      
      final enrichedReferences = await Future.wait(
        references.map((reference) async {
          // Si l'année est déjà présente, ne pas faire d'appel API
          if (reference.year != null) return reference;
          
          // Extraire l'ID TMDB
          final tmdbId = int.tryParse(reference.id);
          if (tmdbId == null) return reference;
          
          try {
            int? year;
            
            // Essayer d'abord comme film, puis comme série
            if (reference.type == ContentType.movie) {
              try {
                final json = await tmdbClient.getJson('movie/$tmdbId');
                final releaseDate = json['release_date']?.toString();
                if (releaseDate != null && releaseDate.isNotEmpty) {
                  final dateParts = releaseDate.split('-');
                  if (dateParts.isNotEmpty) {
                    year = int.tryParse(dateParts[0]);
                  }
                }
              } catch (_) {
                // Ignorer les erreurs
              }
            } else if (reference.type == ContentType.series) {
              try {
                final json = await tmdbClient.getJson('tv/$tmdbId');
                final firstAirDate = json['first_air_date']?.toString();
                if (firstAirDate != null && firstAirDate.isNotEmpty) {
                  final dateParts = firstAirDate.split('-');
                  if (dateParts.isNotEmpty) {
                    year = int.tryParse(dateParts[0]);
                  }
                }
              } catch (_) {
                // Ignorer les erreurs
              }
            }
            
            // Si on a récupéré une année, mettre à jour la référence
            if (year != null) {
              return reference.copyWith(year: Optional.of(year));
            }
          } catch (_) {
            // En cas d'erreur, retourner la référence originale
          }
          
          return reference;
        }),
      );
      
      return enrichedReferences;
    },
  );
});
