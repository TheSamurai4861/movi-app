// lib/src/features/library/presentation/pages/library_page.dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/library/library_constants.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_filter_pills.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

/// LibraryPage (version "content-only" pour être hostée par le Shell).
///
/// ✅ Changements clés:
/// - Pas de Scaffold/SafeArea/SwipeBackWrapper ici (le Shell s’en charge).
/// - Pas de bottomInset MoviBottomNavBar (le Shell gère ses insets).
/// - Champ de recherche avec FocusNode réel + animation propre.
/// - UI stable avec la retention du Shell.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  late final AnimationController _anim;
  late final Animation<double> _opacity;
  late final Animation<double> _slideY;

  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );

    _opacity = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOut,
    );

    _slideY = Tween<double>(begin: -12.0, end: 0.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _isSearchVisible = !_isSearchVisible);

    if (_isSearchVisible) {
      _anim.forward();
      // Focus après l’animation (meilleure sensation)
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _searchFocusNode.requestFocus();
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
      });
    } else {
      _anim.reverse();
      _searchController.clear();
      ref.read(librarySearchQueryProvider.notifier).setQuery('');
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _showCreatePlaylistDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.createPlaylistTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: l10n.playlistName,
            autofocus: true,
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final name = nameController.text.trim();
              Navigator.of(context).pop();

              if (name.isEmpty) return;

              try {
                final userId = ref.read(currentUserIdProvider);
                final playlistId = PlaylistId(
                  '${LibraryConstants.userPlaylistPrefix}${DateTime.now().millisecondsSinceEpoch}',
                );
                final createPlaylist = ref.read(createPlaylistUseCaseProvider);

                await createPlaylist(
                  id: playlistId,
                  title: MediaTitle(name),
                  owner: userId,
                  isPublic: false,
                );

                ref.invalidate(libraryPlaylistsProvider);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.playlistCreatedSuccess(name))),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.playlistCreateError(e.toString()))),
                );
              }
            },
            child: Text(l10n.actionConfirm),
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
    final l10n = AppLocalizations.of(context)!;
    if (playlist.playlistId == null) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(playlist.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final setPinned = ref.read(setPlaylistPinnedUseCaseProvider);
                await setPinned.call(
                  id: PlaylistId(playlist.playlistId!),
                  isPinned: !playlist.isPinned,
                );
                ref.invalidate(libraryPlaylistsProvider);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      !playlist.isPinned ? l10n.playlistPinned : l10n.playlistUnpinned,
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.push_pin,
                  size: 18,
                  color: playlist.isPinned ? Colors.white70 : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  playlist.isPinned ? l10n.unpinPlaylist : l10n.pinPlaylist,
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showRenameDialog(context, ref, playlist);
            },
            child: Text(l10n.renamePlaylist),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _showDeleteDialog(context, ref, playlist);
            },
            child: Text(l10n.deletePlaylist),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.actionCancel),
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    LibraryPlaylistItem playlist,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (playlist.playlistId == null) return;

    final nameController = TextEditingController(text: playlist.title);

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.playlistRenameTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: l10n.playlistNamePlaceholder,
            autofocus: true,
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final name = nameController.text.trim();
              Navigator.of(ctx).pop();
              if (name.isEmpty) return;

              try {
                final renamePlaylist = ref.read(renamePlaylistUseCaseProvider);
                await renamePlaylist.call(
                  id: PlaylistId(playlist.playlistId!),
                  title: MediaTitle(name),
                );

                ref.invalidate(libraryPlaylistsProvider);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Playlist renommée en "$name"')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            child: Text(l10n.actionConfirm),
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
    final l10n = AppLocalizations.of(context)!;
    if (playlist.playlistId == null) return;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.deletePlaylist),
        content: Text('Êtes-vous sûr de vouloir supprimer "${playlist.title}" ?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();

              try {
                final deletePlaylist = ref.read(deletePlaylistUseCaseProvider);
                await deletePlaylist.call(PlaylistId(playlist.playlistId!));

                ref.invalidate(libraryPlaylistsProvider);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Playlist supprimée')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            child: Text(l10n.deletePlaylist),
          ),
        ],
      ),
    );
  }

  void _navigateToPlaylist(LibraryPlaylistItem playlist) {
    if (playlist.type == LibraryPlaylistType.actor) {
      final personId = playlist.id.replaceFirst(LibraryConstants.actorPrefix, '');
      context.push(
        AppRouteNames.person,
        extra: PersonSummary(id: PersonId(personId), name: playlist.title),
      );
      return;
    }

    if (playlist.id.startsWith(LibraryConstants.sagaPrefix)) {
      final sagaId = playlist.id.replaceFirst(LibraryConstants.sagaPrefix, '');
      context.push(AppRouteNames.sagaDetail, extra: sagaId);
      return;
    }

    context.push(AppRouteNames.libraryPlaylist, extra: playlist);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final filter = ref.watch(libraryFilterProvider);
    final playlistsAsync = ref.watch(filteredLibraryPlaylistsProvider);
    final searchQuery = ref.watch(librarySearchQueryProvider);

    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.navLibrary,
                      style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ) ??
                          const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                IconButton(
                  icon: Image.asset(
                    AppAssets.iconSearch,
                    width: 28,
                    height: 28,
                    color: _isSearchVisible ? theme.colorScheme.primary : null,
                  ),
                  onPressed: _toggleSearch,
                  tooltip: l10n.searchTitle,
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Image.asset(
                    AppAssets.iconPlus,
                    width: 24,
                    height: 24,
                  ),
                  onPressed: _showCreatePlaylistDialog,
                  tooltip: l10n.createPlaylistTitle,
                ),
                ],
              ),
            ),

            // Search field (animated)
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                if (!_isSearchVisible && _anim.value == 0) {
                  return const SizedBox.shrink();
                }

                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideY.value),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
                      child: _LibrarySearchField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        hintText: l10n.librarySearchPlaceholder,
                        clearTooltip: l10n.clear,
                        onChanged: (text) {
                          ref
                              .read(librarySearchQueryProvider.notifier)
                              .setQuery(text);
                        },
                        onClear: () {
                          _searchController.clear();
                          ref.read(librarySearchQueryProvider.notifier).setQuery('');
                          _searchFocusNode.requestFocus();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Filter pills (optionnellement animés avec le search)
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(0, _isSearchVisible ? (_slideY.value / 2) : 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LibraryFilterPills(
                      activeFilter: filter,
                      onFilterChanged: (newFilter) {
                        ref.read(libraryFilterProvider.notifier).setFilter(newFilter);
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // List
            Expanded(
              child: SyncableRefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(libraryPlaylistsProvider);
                },
                child: playlistsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Erreur: $error',
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (playlists) {
                    if (playlists.isEmpty) {
                      if (searchQuery.isNotEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Aucun résultat pour "$searchQuery"',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.35,
                            child: Center(
                              child: Text(
                                l10n.libraryEmpty,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          showItemCount: !playlist.id.startsWith(
                            LibraryConstants.sagaPrefix,
                          ),
                          onTap: () => _navigateToPlaylist(playlist),
                          onLongPress: playlist.type == LibraryPlaylistType.userPlaylist &&
                                  playlist.playlistId != null
                              ? () => _showPlaylistMenu(context, ref, playlist)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibrarySearchField extends StatelessWidget {
  const _LibrarySearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
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
                    onPressed: onClear,
                    tooltip: clearTooltip,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 16,
            ),
          ),
        );
      },
    );
  }
}
