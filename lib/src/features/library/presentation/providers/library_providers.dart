import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/library/domain/repositories/library_repository.dart';
import 'package:movi/src/features/library/data/repositories/library_repository_impl.dart';
import 'package:movi/src/features/library/presentation/widgets/library_filter_pills.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';

/// Exposes the LibraryRepository to the presentation layer.
/// Le repository est créé avec l'ID utilisateur actuel pour filtrer les favoris.
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return LibraryRepositoryImpl(
    ref.watch(slProvider)<WatchlistLocalRepository>(),
    ref.watch(slProvider)<HistoryLocalRepository>(),
    ref.watch(slProvider)<PlaylistRepository>(),
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

  final playlists = <LibraryPlaylistItem>[];

  // Films favoris
  final favoriteMovies = await repository.getLikedMovies();
  if (favoriteMovies.isNotEmpty) {
    playlists.add(
      LibraryPlaylistItem(
        id: 'favorite_movies',
        title: 'Films favoris',
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
        title: 'Séries favorites',
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
        title: 'Historique de visionnage',
        itemCount: totalHistory,
        type: LibraryPlaylistType.watchHistory,
        isPinned: true,
      ),
    );
  }

  // Playlists utilisateur
  final userId = ref.read(currentUserIdProvider);
  final userPlaylists = await repository.getUserPlaylists(userId);
  for (final playlist in userPlaylists) {
    playlists.add(
      LibraryPlaylistItem(
        id: 'playlist_${playlist.id.value}',
        title: playlist.title.value,
        itemCount: playlist.itemCount ?? 0,
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
        itemCount: 0, // TODO: Compter les éléments de la saga
        type: LibraryPlaylistType.userPlaylist, // Utiliser un type approprié
      ),
    );
  }

  // Trier les playlists : les favoris (isPinned: true) en premier
  playlists.sort((a, b) {
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;
    return 0; // Conserver l'ordre pour les autres
  });

  return playlists;
});

/// Provider pour filtrer les playlists selon le type de filtre actif
final filteredLibraryPlaylistsProvider =
    Provider<AsyncValue<List<LibraryPlaylistItem>>>((ref) {
      final filter = ref.watch(libraryFilterProvider);
      final playlistsAsync = ref.watch(libraryPlaylistsProvider);

      return playlistsAsync.when(
        data: (playlists) {
          if (filter == null) return AsyncValue.data(playlists);

          final filtered = playlists.where((playlist) {
            switch (filter) {
              case LibraryFilterType.playlists:
                // Exclure les sagas et les acteurs
                return !playlist.id.startsWith('saga_') &&
                    playlist.type != LibraryPlaylistType.actor &&
                    (playlist.type == LibraryPlaylistType.favoriteMovies ||
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
