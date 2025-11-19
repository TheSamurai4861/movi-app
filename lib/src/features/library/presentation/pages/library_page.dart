import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_filter_pills.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final AnimationController _searchAnimationController;
  late final Animation<double> _searchSlideAnimation;
  late final Animation<double> _searchOpacityAnimation;
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _searchOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (_isSearchVisible) {
        _searchAnimationController.forward();
        // Focus sur le champ de recherche après l'animation
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            FocusScope.of(context).requestFocus(FocusNode());
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchController.text.length),
                );
              }
            });
          }
        });
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        ref.read(librarySearchQueryProvider.notifier).setQuery('');
      }
    });
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.createPlaylistTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: AppLocalizations.of(context)!.playlistName,
            autofocus: true,
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                Navigator.of(context).pop();
                return;
              }

              Navigator.of(context).pop();

              try {
                final userId = ref.read(currentUserIdProvider);
                final playlistId = PlaylistId(
                  'playlist_${DateTime.now().millisecondsSinceEpoch}',
                );
                final createPlaylist = CreatePlaylist(
                  ref.read(slProvider)<PlaylistRepository>(),
                );

                await createPlaylist.call(
                  id: playlistId,
                  title: MediaTitle(name),
                  owner: userId,
                  isPublic: false,
                );

                ref.invalidate(libraryPlaylistsProvider);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.playlistCreatedSuccess(name))),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.playlistCreateError(e.toString()))),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.actionConfirm),
          ),
        ],
      ),
    );
  }

  void _showPlaylistMenu(
    BuildContext context,
    WidgetRef ref,
    LibraryPlaylistItem playlist,
  ) {
    if (playlist.playlistId == null) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(playlist.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showRenameDialog(context, ref, playlist);
            },
            child: Text(AppLocalizations.of(context)!.renamePlaylist),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _showDeleteDialog(context, ref, playlist);
            },
            child: Text(AppLocalizations.of(context)!.deletePlaylist),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(context)!.actionCancel),
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    LibraryPlaylistItem playlist,
  ) {
    if (playlist.playlistId == null) return;

    final nameController = TextEditingController(text: playlist.title);

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.playlistRenameTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: AppLocalizations.of(context)!.playlistNamePlaceholder,
            autofocus: true,
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                Navigator.of(ctx).pop();
                return;
              }

              Navigator.of(ctx).pop();

              try {
                final renamePlaylist = RenamePlaylist(
                  ref.read(slProvider)<PlaylistRepository>(),
                );

                await renamePlaylist.call(
                  id: PlaylistId(playlist.playlistId!),
                  title: MediaTitle(name),
                );

                ref.invalidate(libraryPlaylistsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playlist renommée en "$name"')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.actionConfirm),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    LibraryPlaylistItem playlist,
  ) {
    if (playlist.playlistId == null) return;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Supprimer la playlist'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${playlist.title}" ?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();

              try {
                final deletePlaylist = DeletePlaylist(
                  ref.read(slProvider)<PlaylistRepository>(),
                );

                await deletePlaylist.call(PlaylistId(playlist.playlistId!));

                ref.invalidate(libraryPlaylistsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist supprimée')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            child: const Text('Supprimer'),
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
    final searchQuery = ref.watch(librarySearchQueryProvider);

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
                        width: 30,
                        height: 30,
                        color: _isSearchVisible
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                      ),
                      onPressed: _toggleSearch,
                    ),
                    const SizedBox(width: 8),
                    // Bouton +
                    IconButton(
                      icon: Image.asset(
                        AppAssets.iconPlus,
                        width: 25,
                        height: 25,
                        color: Colors.white,
                      ),
                      onPressed: _showCreatePlaylistDialog,
                    ),
                  ],
                ),
              ),
              // Input de recherche animé
              AnimatedBuilder(
                animation: _searchAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _searchSlideAnimation.value),
                    child: Opacity(
                      opacity: _searchOpacityAnimation.value,
                      child: _isSearchVisible
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                              child: Builder(
                                builder: (context) {
                                  final colorScheme = Theme.of(
                                    context,
                                  ).colorScheme;
                                  return ValueListenableBuilder<
                                    TextEditingValue
                                  >(
                                    valueListenable: _searchController,
                                    builder: (context, value, child) {
                                      return TextField(
                                        controller: _searchController,
                                        onChanged: (text) {
                                          ref
                                              .read(
                                                librarySearchQueryProvider
                                                    .notifier,
                                              )
                                              .setQuery(text);
                                        },
                                        decoration: InputDecoration(
                                          hintText:
                                              AppLocalizations.of(context)!.librarySearchPlaceholder,
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 12,
                                              right: 8,
                                            ),
                                            child: Image.asset(
                                              'assets/icons/search.png',
                                              width: 25,
                                              height: 25,
                                            ),
                                          ),
                                          suffixIcon: value.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Image.asset(
                                                    'assets/icons/supprimer.png',
                                                    width: 25,
                                                    height: 25,
                                                  ),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    ref
                                                        .read(
                                                          librarySearchQueryProvider
                                                              .notifier,
                                                        )
                                                        .setQuery('');
                                                  },
                                                  tooltip: AppLocalizations.of(
                                                    context,
                                                  )!.clear,
                                                )
                                              : null,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            borderSide: BorderSide(
                                              color: colorScheme.outlineVariant,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            borderSide: BorderSide(
                                              color: colorScheme.outlineVariant,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            borderSide: BorderSide(
                                              color: colorScheme.primary,
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 16,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                },
              ),
              // Pills de filtre avec animation
              AnimatedBuilder(
                animation: _searchAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _searchSlideAnimation.value),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: _isSearchVisible ? 10 : 0,
                      ),
                      child: LibraryFilterPills(
                        activeFilter: filter,
                        onFilterChanged: (newFilter) {
                          ref
                              .read(libraryFilterProvider.notifier)
                              .setFilter(newFilter);
                        },
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _searchAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _searchSlideAnimation.value),
                    child: const SizedBox(height: 32),
                  );
                },
              ),
              // Liste des playlists avec animation
              Expanded(
                child: AnimatedBuilder(
                  animation: _searchAnimationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _searchSlideAnimation.value),
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
                            // Si recherche active mais aucun résultat
                            if (searchQuery.isNotEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Aucun résultat pour "$searchQuery"',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            // Sinon, bibliothèque vide
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.libraryEmpty,
                                  style:
                                      Theme.of(context).textTheme.bodyLarge
                                          ?.copyWith(color: Colors.white70) ??
                                      const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          // Utiliser une liste verticale pour tous les filtres (même style que les playlists like)
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: playlists.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final playlist = playlists[index];
                              return LibraryPlaylistCard(
                                title: playlist.title,
                                itemCount: playlist.itemCount,
                                type: playlist.type,
                                isPinned: playlist.isPinned,
                                photo: playlist.photo,
                                showItemCount: !playlist.id.startsWith('saga_'),
                                onTap: () => _navigateToPlaylist(playlist),
                                onLongPress:
                                    playlist.type ==
                                        LibraryPlaylistType.userPlaylist
                                    ? () => _showPlaylistMenu(
                                        context,
                                        ref,
                                        playlist,
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
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
