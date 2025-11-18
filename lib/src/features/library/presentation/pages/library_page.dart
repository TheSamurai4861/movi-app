import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_filter_pills.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  void _showCreatePlaylistDialog() {
    // TODO: Implémenter le dialogue de création de playlist
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une playlist'),
        content: const Text('Fonctionnalité à venir'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _navigateToPlaylist(LibraryPlaylistItem playlist) {
    if (playlist.type == LibraryPlaylistType.actor) {
      // Pour les acteurs, ouvrir la page acteur
      // L'ID est stocké comme 'actor_123', on extrait juste le numéro
      final personId = playlist.id.replaceFirst('actor_', '');
      context.push(
        AppRouteNames.person,
        extra: PersonSummary(id: PersonId(personId), name: playlist.title),
      );
    } else if (playlist.id.startsWith('saga_')) {
      // Pour les sagas, ouvrir la page de détail de saga
      final sagaId = playlist.id.replaceFirst('saga_', '');
      context.push(AppRouteNames.sagaDetail, extra: sagaId);
    } else {
      // Pour les autres playlists, ouvrir la page de détail
      context.push(AppRouteNames.libraryPlaylist, extra: playlist);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(libraryFilterProvider);
    final playlistsAsync = ref.watch(filteredLibraryPlaylistsProvider);

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              // En-tête avec titre et boutons
              Padding(
                padding: AppSpacing.page,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.navLibrary,
                        style:
                            Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ) ??
                            const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    // Bouton recherche
                    IconButton(
                      icon: Image.asset(
                        AppAssets.iconSearch,
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // TODO: Implémenter la recherche dans la bibliothèque
                      },
                    ),
                    const SizedBox(width: 8),
                    // Bouton +
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _showCreatePlaylistDialog,
                    ),
                  ],
                ),
              ),
              // Pills de filtre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LibraryFilterPills(
                  activeFilter: filter,
                  onFilterChanged: (newFilter) {
                    ref
                        .read(libraryFilterProvider.notifier)
                        .setFilter(newFilter);
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Liste des playlists
              Expanded(
                child: playlistsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Erreur: $error',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  data: (playlists) {
                    if (playlists.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context)!.libraryEmpty,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                              ) ??
                              const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    // Utiliser une liste verticale pour tous les filtres (même style que les playlists like)
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: playlists.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return LibraryPlaylistCard(
                          title: playlist.title,
                          itemCount: playlist.itemCount,
                          type: playlist.type,
                          isPinned: playlist.isPinned,
                          photo: playlist.photo,
                          onTap: () => _navigateToPlaylist(playlist),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
