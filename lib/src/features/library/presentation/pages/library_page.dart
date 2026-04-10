// lib/src/features/library/presentation/pages/library_page.dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:movi/src/features/library/presentation/widgets/library_premium_banner.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';
import 'package:movi/src/features/shell/presentation/providers/shell_providers.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';

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
  final _firstPlaylistFocusNode = FocusNode(debugLabel: 'LibraryFirstPlaylist');
  final _firstFilterFocusNode = FocusNode(debugLabel: 'LibraryFilterPlaylists');
  final _clearFilterFocusNode = FocusNode(debugLabel: 'LibraryClearFilter');
  final _artistsFilterFocusNode = FocusNode(debugLabel: 'LibraryFilterArtists');
  final _searchActionFocusNode = FocusNode(debugLabel: 'LibrarySearchAction');
  final _addActionFocusNode = FocusNode(debugLabel: 'LibraryAddAction');
  final List<FocusNode> _playlistFocusNodes = [];
  late final ShellFocusCoordinator _shellFocusCoordinator;

  late final AnimationController _anim;
  late final Animation<double> _opacity;
  late final Animation<double> _slideY;

  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _shellFocusCoordinator = ref.read(shellFocusCoordinatorProvider);
    _shellFocusCoordinator.registerTabFocusBinding(
      ShellTab.library,
      ShellTabFocusBinding(
        initialFocusNode: _firstPlaylistFocusNode,
        fallbackFocusNode: _searchFocusNode,
      ),
    );

    _anim = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );

    _opacity = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

    _slideY = Tween<double>(
      begin: -12.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _shellFocusCoordinator.unregisterTabFocusBinding(
      ShellTab.library,
      _firstPlaylistFocusNode,
    );
    _disposePlaylistFocusNodes();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _firstPlaylistFocusNode.dispose();
    _firstFilterFocusNode.dispose();
    _clearFilterFocusNode.dispose();
    _artistsFilterFocusNode.dispose();
    _searchActionFocusNode.dispose();
    _addActionFocusNode.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _focusFirstPlaylist() {
    _requestPlaylistFocus(0, ensureVisible: true);
  }

  void _focusFirstFilter() {
    if (_firstFilterFocusNode.context == null ||
        !_firstFilterFocusNode.canRequestFocus) {
      return;
    }
    _firstFilterFocusNode.requestFocus();
  }

  void _focusArtistsFilter() {
    if (_artistsFilterFocusNode.context == null ||
        !_artistsFilterFocusNode.canRequestFocus) {
      return;
    }
    _artistsFilterFocusNode.requestFocus();
  }

  void _focusSidebarMenu() {
    _shellFocusCoordinator.focusSidebar();
  }

  void _focusSearchInput() {
    if (_searchFocusNode.context == null || !_searchFocusNode.canRequestFocus) {
      return;
    }
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
  }

  void _focusSearchAction() {
    if (_searchActionFocusNode.context == null ||
        !_searchActionFocusNode.canRequestFocus) {
      return;
    }
    _searchActionFocusNode.requestFocus();
  }

  KeyEventResult _handleSearchActionKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_addActionFocusNode.context != null &&
          _addActionFocusNode.canRequestFocus) {
        _addActionFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _focusFirstPlaylist();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _focusArtistsFilter();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleAddActionKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _focusFirstPlaylist();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _focusArtistsFilter();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _syncPlaylistFocusNodes(int count) {
    if (_playlistFocusNodes.length == count) return;

    if (_playlistFocusNodes.isEmpty && count > 0) {
      _playlistFocusNodes.add(_firstPlaylistFocusNode);
    }

    while (_playlistFocusNodes.length < count) {
      final index = _playlistFocusNodes.length;
      _playlistFocusNodes.add(
        index == 0
            ? _firstPlaylistFocusNode
            : FocusNode(debugLabel: 'LibraryPlaylist-$index'),
      );
    }

    while (_playlistFocusNodes.length > count) {
      final removed = _playlistFocusNodes.removeLast();
      if (!identical(removed, _firstPlaylistFocusNode)) {
        removed.dispose();
      }
    }
  }

  void _disposePlaylistFocusNodes() {
    for (final node in _playlistFocusNodes) {
      if (!identical(node, _firstPlaylistFocusNode)) {
        node.dispose();
      }
    }
    _playlistFocusNodes.clear();
  }

  void _requestPlaylistFocus(int index, {bool ensureVisible = false}) {
    if (index < 0 || index >= _playlistFocusNodes.length) return;
    final node = _playlistFocusNodes[index];
    if (node.context == null || !node.canRequestFocus) return;
    node.requestFocus();
    if (!ensureVisible) return;
    unawaited(
      Scrollable.ensureVisible(
        node.context!,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ),
    );
  }

  KeyEventResult _handlePlaylistListDirection(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isBackKey =
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace;
    final hasSearchResults =
        _isSearchVisible && _searchController.text.trim().isNotEmpty;
    if (isBackKey && hasSearchResults) {
      _focusSearchInput();
      return KeyEventResult.handled;
    }

    int? targetIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft && index == 0) {
      _focusSidebarMenu();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      targetIndex = index + 1 < _playlistFocusNodes.length ? index + 1 : null;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (index == 0) {
        _focusFirstFilter();
        return KeyEventResult.handled;
      }
      targetIndex = index - 1;
    }

    if (targetIndex == null) return KeyEventResult.ignored;
    _requestPlaylistFocus(targetIndex, ensureVisible: true);
    return KeyEventResult.handled;
  }

  KeyEventResult _handlePlaylistGridDirection(
    BuildContext context,
    int index,
    int columns,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isBackKey =
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace;
    final hasSearchResults =
        _isSearchVisible && _searchController.text.trim().isNotEmpty;
    if (isBackKey && hasSearchResults) {
      _focusSearchInput();
      return KeyEventResult.handled;
    }

    int? targetIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (index % columns == 0) {
        _focusSidebarMenu();
        return KeyEventResult.handled;
      }
      targetIndex = index - 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final nextIndex = index + 1;
      if (index % columns == columns - 1 ||
          nextIndex >= _playlistFocusNodes.length) {
        return KeyEventResult.handled;
      }
      targetIndex = nextIndex;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (index - columns < 0) {
        _focusFirstFilter();
        return KeyEventResult.handled;
      }
      targetIndex = index - columns;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final nextIndex = index + columns;
      if (nextIndex >= _playlistFocusNodes.length) {
        return KeyEventResult.handled;
      }
      targetIndex = nextIndex;
    }

    if (targetIndex == null) return KeyEventResult.ignored;
    _requestPlaylistFocus(targetIndex, ensureVisible: true);
    if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
        targetIndex < columns) {
      final scrollController = PrimaryScrollController.maybeOf(context);
      if (scrollController != null &&
          scrollController.hasClients &&
          scrollController.offset > 0) {
        unawaited(
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    }
    return KeyEventResult.handled;
  }

  void _toggleSearch() {
    setState(() => _isSearchVisible = !_isSearchVisible);

    if (_isSearchVisible) {
      _anim.forward();
      // Focus après l’animation (meilleure sensation)
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _focusSearchInput();
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
    final nameFocusNode = FocusNode(debugLabel: 'CreatePlaylistName');
    final cancelFocusNode = FocusNode(debugLabel: 'CreatePlaylistCancel');
    final submitFocusNode = FocusNode(debugLabel: 'CreatePlaylistSubmit');

    Future<void> submitCreate(BuildContext dialogContext) async {
      final name = nameController.text.trim();
      Navigator.of(dialogContext).pop();

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

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.playlistCreatedSuccess(name))),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.playlistCreateError(e.toString()))),
        );
      }
    }

    final dialogScreenType = _screenType(context);
    if (dialogScreenType == ScreenType.desktop ||
        dialogScreenType == ScreenType.tv) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          final colorScheme = theme.colorScheme;
          return FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.createPlaylistTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(1),
                          child: TextFormField(
                            controller: nameController,
                            focusNode: nameFocusNode,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: colorScheme.primary,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) =>
                                submitFocusNode.requestFocus(),
                            decoration: InputDecoration(
                              hintText: l10n.playlistName,
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF2C2C2E),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.65,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: FocusTraversalOrder(
                                order: const NumericFocusOrder(2),
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) {
                                    if (event is! KeyDownEvent) {
                                      return KeyEventResult.ignored;
                                    }

                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowUp) {
                                      nameFocusNode.requestFocus();
                                      return KeyEventResult.handled;
                                    }

                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowRight) {
                                      submitFocusNode.requestFocus();
                                      return KeyEventResult.handled;
                                    }

                                    return KeyEventResult.ignored;
                                  },
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 52,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ListenableBuilder(
                                        listenable: cancelFocusNode,
                                        builder: (context, _) {
                                          final isFocused =
                                              cancelFocusNode.hasFocus;
                                          return AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 160,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: isFocused
                                                    ? colorScheme.error
                                                    : colorScheme.error
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                width: 2,
                                              ),
                                              color: isFocused
                                                  ? colorScheme.error
                                                        .withValues(alpha: 0.14)
                                                  : colorScheme
                                                        .surfaceContainerHighest
                                                        .withValues(alpha: 0.2),
                                            ),
                                            child: OutlinedButton(
                                              focusNode: cancelFocusNode,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    colorScheme.error,
                                                side: BorderSide.none,
                                                minimumSize:
                                                    const Size.fromHeight(52),
                                                alignment: Alignment.center,
                                                textStyle: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 16,
                                                    ),
                                                shape: const StadiumBorder(),
                                                overlayColor:
                                                    Colors.transparent,
                                              ),
                                              onPressed: () => Navigator.of(
                                                dialogContext,
                                              ).pop(),
                                              child: Text(
                                                l10n.actionCancel,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FocusTraversalOrder(
                                order: const NumericFocusOrder(3),
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) {
                                    if (event is! KeyDownEvent) {
                                      return KeyEventResult.ignored;
                                    }

                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowUp) {
                                      nameFocusNode.requestFocus();
                                      return KeyEventResult.handled;
                                    }

                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowLeft) {
                                      cancelFocusNode.requestFocus();
                                      return KeyEventResult.handled;
                                    }

                                    return KeyEventResult.ignored;
                                  },
                                  child: MoviPrimaryButton(
                                    label: l10n.actionConfirm,
                                    focusNode: submitFocusNode,
                                    onPressed: () =>
                                        submitCreate(dialogContext),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ).whenComplete(() {
        nameController.dispose();
        nameFocusNode.dispose();
        cancelFocusNode.dispose();
        submitFocusNode.dispose();
      });
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => submitCreate(dialogContext),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    ).whenComplete(() {
      nameController.dispose();
      nameFocusNode.dispose();
      cancelFocusNode.dispose();
      submitFocusNode.dispose();
    });
  }

  void _showPlaylistMenu(
    BuildContext context,
    WidgetRef ref,
    LibraryPlaylistItem playlist,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = Theme.of(context).colorScheme.primary;
    if (playlist.playlistId == null) return;

    final actions = <MoviTvActionMenuAction>[
      MoviTvActionMenuAction(
        label: playlist.isPinned ? l10n.unpinPlaylist : l10n.pinPlaylist,
        onPressed: () async {
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
                  !playlist.isPinned
                      ? l10n.playlistPinned
                      : l10n.playlistUnpinned,
                ),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.errorGenericWithMessage(e.toString()),
                ),
              ),
            );
          }
        },
      ),
      MoviTvActionMenuAction(
        label: l10n.renamePlaylist,
        onPressed: () => _showRenameDialog(context, ref, playlist),
      ),
      MoviTvActionMenuAction(
        label: l10n.deletePlaylist,
        destructive: true,
        onPressed: () => _showDeleteDialog(context, ref, playlist),
      ),
    ];

    final dialogScreenType = _screenType(context);
    if (dialogScreenType == ScreenType.desktop ||
        dialogScreenType == ScreenType.tv) {
      showMoviTvActionMenu(
        context: context,
        title: playlist.title,
        actions: actions,
        cancelLabel: l10n.actionCancel,
      );
      return;
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(playlist.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              actions.first.onPressed();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.push_pin,
                  size: 18,
                  color: playlist.isPinned ? accentColor : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(playlist.isPinned ? l10n.unpinPlaylist : l10n.pinPlaylist),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              actions[1].onPressed();
            },
            child: Text(l10n.renamePlaylist),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              actions[2].onPressed();
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
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.snackbarPlaylistRenamed(name),
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.errorGenericWithMessage(e.toString()),
                    ),
                  ),
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
        content: Text(l10n.dialogConfirmDeletePlaylist(playlist.title)),
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
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.snackbarPlaylistDeleted,
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.errorGenericWithMessage(e.toString()),
                    ),
                  ),
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
      final personId = playlist.id.replaceFirst(
        LibraryConstants.actorPrefix,
        '',
      );
      unawaited(
        navigateToPersonDetail(
          context,
          ref,
          person: PersonSummary(id: PersonId(personId), name: playlist.title),
        ),
      );
      return;
    }

    if (playlist.id.startsWith(LibraryConstants.sagaPrefix)) {
      final sagaId = playlist.id.replaceFirst(LibraryConstants.sagaPrefix, '');
      unawaited(navigateToSagaDetail(context, ref, sagaId: sagaId));
      return;
    }

    context.push(AppRouteNames.libraryPlaylist, extra: playlist);
  }

  ScreenType _screenType(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ScreenTypeResolver.instance.resolve(size.width, size.height);
  }

  bool _isLargeScreen(BuildContext context) {
    final screenType = _screenType(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  double _horizontalPadding(BuildContext context) {
    return switch (_screenType(context)) {
      ScreenType.mobile => 20,
      ScreenType.tablet => 24,
      ScreenType.desktop => 40,
      ScreenType.tv => 56,
    };
  }

  /// Dégage le dernier élément au-dessus de la barre de navigation flottante du shell mobile.
  double _libraryScrollBottomPadding(BuildContext context) {
    if (_isLargeScreen(context)) {
      return 100;
    }
    return MoviBottomNavBar.height + moviNavBarBottomOffset(context) + 16;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLargeScreen = _isLargeScreen(context);
    final screenType = _screenType(context);
    final horizontalPadding = _horizontalPadding(context);

    final filter = ref.watch(libraryFilterProvider);
    final playlistsAsync = ref.watch(filteredLibraryPlaylistsProvider);
    final searchQuery = ref.watch(librarySearchQueryProvider);
    final searchField = _LibrarySearchField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: l10n.librarySearchPlaceholder,
      clearTooltip: l10n.clear,
      onSubmitted: _focusSearchAction,
      onRequestFirstResultFocus: _focusFirstPlaylist,
      onChanged: (text) {
        ref.read(librarySearchQueryProvider.notifier).setQuery(text);
      },
      onClear: () {
        _searchController.clear();
        ref.read(librarySearchQueryProvider.notifier).setQuery('');
        _searchFocusNode.requestFocus();
      },
    );

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.navLibrary,
                    style:
                        theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ) ??
                        const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (isLargeScreen && (_isSearchVisible || _anim.value > 0)) ...[
                  const SizedBox(width: 12),
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (context, _) {
                      final width = 420 * _opacity.value;
                      if (width <= 1) {
                        return const SizedBox.shrink();
                      }
                      return ClipRect(
                        child: SizedBox(
                          width: width,
                          child: Opacity(
                            opacity: _opacity.value,
                            child: Transform.translate(
                              offset: Offset(18 * (1 - _opacity.value), 0),
                              child: searchField,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                if (!isLargeScreen)
                  Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) => _handleSearchActionKey(event),
                    child: IconButton(
                      focusNode: _searchActionFocusNode,
                      style: IconButton.styleFrom(
                        backgroundColor: _isSearchVisible
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.08),
                        padding: const EdgeInsets.all(10),
                        shape: const CircleBorder(),
                      ),
                      icon: MoviAssetIcon(
                        AppAssets.iconSearch,
                        width: 24,
                        height: 24,
                        color: _isSearchVisible
                            ? theme.colorScheme.primary
                            : Colors.white,
                      ),
                      onPressed: _toggleSearch,
                      tooltip: l10n.searchTitle,
                    ),
                  ),
                if (!isLargeScreen) ...[
                  const SizedBox(width: 6),
                  Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) => _handleAddActionKey(event),
                    child: IconButton(
                      focusNode: _addActionFocusNode,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        padding: const EdgeInsets.all(10),
                        shape: const CircleBorder(),
                      ),
                      icon: const MoviAssetIcon(
                        AppAssets.iconPlus,
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      onPressed: _showCreatePlaylistDialog,
                      tooltip: l10n.createPlaylistTitle,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (!isLargeScreen)
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
                      padding: EdgeInsets.only(
                        top: 8,
                        left: horizontalPadding,
                        right: horizontalPadding,
                      ),
                      child: searchField,
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 12),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: LibraryFilterPills(
                    activeFilter: filter,
                    firstFilterFocusNode: _firstFilterFocusNode,
                    clearFilterFocusNode: _clearFilterFocusNode,
                    artistsFilterFocusNode: _artistsFilterFocusNode,
                    onRequestSidebarFocus: _focusSidebarMenu,
                    onRequestFirstPlaylistFocus: _focusFirstPlaylist,
                    onRequestSearchActionFocus: () {
                      if (_addActionFocusNode.context != null &&
                          _addActionFocusNode.canRequestFocus) {
                        _addActionFocusNode.requestFocus();
                        return;
                      }
                      if (_searchActionFocusNode.context != null &&
                          _searchActionFocusNode.canRequestFocus) {
                        _searchActionFocusNode.requestFocus();
                      }
                    },
                    onFilterChanged: (newFilter) {
                      ref
                          .read(libraryFilterProvider.notifier)
                          .setFilter(newFilter);
                    },
                  ),
                ),
                if (isLargeScreen) ...[
                  const SizedBox(width: 12),
                  Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) => _handleAddActionKey(event),
                    child: IconButton(
                      focusNode: _addActionFocusNode,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        padding: const EdgeInsets.all(10),
                        shape: const CircleBorder(),
                      ),
                      icon: const MoviAssetIcon(
                        AppAssets.iconPlus,
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      onPressed: _showCreatePlaylistDialog,
                      tooltip: l10n.createPlaylistTitle,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (screenType != ScreenType.mobile) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: const LibraryPremiumBanner(),
            ),
            const SizedBox(height: 20),
          ],

          Expanded(
            child: SyncableRefreshIndicator(
              onRefresh: () async {
                ref.invalidate(libraryPlaylistsProvider);
              },
              child: playlistsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.errorGenericWithMessage(error.toString()),
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (playlists) {
                  _syncPlaylistFocusNodes(playlists.length);

                  if (playlists.isEmpty) {
                    if (searchQuery.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            24,
                            horizontalPadding,
                            24 + _libraryScrollBottomPadding(context),
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.libraryNoResultsForQuery(searchQuery),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        _libraryScrollBottomPadding(context),
                      ),
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

                  if (!isLargeScreen) {
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        _libraryScrollBottomPadding(context),
                      ),
                      itemCount: playlists.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return Focus(
                          canRequestFocus: false,
                          onKeyEvent: (_, event) =>
                              _handlePlaylistListDirection(index, event),
                          child: LibraryPlaylistCard(
                            title: playlist.title,
                            itemCount: playlist.itemCount,
                            type: playlist.type,
                            isPinned: playlist.isPinned,
                            photo: playlist.photo,
                            showItemCount: !playlist.id.startsWith(
                              LibraryConstants.sagaPrefix,
                            ),
                            focusNode: _playlistFocusNodes[index],
                            onTap: () => _navigateToPlaylist(playlist),
                            onLongPress:
                                playlist.type ==
                                        LibraryPlaylistType.userPlaylist &&
                                    playlist.playlistId != null
                                ? () =>
                                      _showPlaylistMenu(context, ref, playlist)
                                : null,
                            onMorePressed:
                                playlist.type ==
                                        LibraryPlaylistType.userPlaylist &&
                                    playlist.playlistId != null
                                ? () =>
                                      _showPlaylistMenu(context, ref, playlist)
                                : null,
                          ),
                        );
                      },
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth =
                          constraints.maxWidth - (horizontalPadding * 2);
                      const gap = 24.0;
                      const maxCardWidth = 240.0;
                      const maxColumns = 8;

                      final columns =
                          ((availableWidth + gap) / (maxCardWidth + gap))
                              .floor()
                              .clamp(1, maxColumns);
                      final gridWidth =
                          (columns * maxCardWidth) + ((columns - 1) * gap);
                      final cardWidth = maxCardWidth;

                      return Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: gridWidth.clamp(0.0, availableWidth),
                          child: FocusTraversalGroup(
                            child: GridView.builder(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                10,
                                horizontalPadding,
                                _libraryScrollBottomPadding(context),
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisExtent: 286,
                                    crossAxisSpacing: gap,
                                    mainAxisSpacing: gap,
                                  ),
                              itemCount: playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = playlists[index];
                                return SizedBox(
                                  width: cardWidth,
                                  child: Focus(
                                    canRequestFocus: false,
                                    onKeyEvent: (_, event) =>
                                        _handlePlaylistGridDirection(
                                          context,
                                          index,
                                          columns,
                                          event,
                                        ),
                                    child: LibraryPlaylistCard(
                                      title: playlist.title,
                                      itemCount: playlist.itemCount,
                                      type: playlist.type,
                                      isPinned: playlist.isPinned,
                                      photo: playlist.photo,
                                      layout:
                                          LibraryPlaylistCardLayout.vertical,
                                      isSaga: playlist.id.startsWith(
                                        LibraryConstants.sagaPrefix,
                                      ),
                                      showItemCount: !playlist.id.startsWith(
                                        LibraryConstants.sagaPrefix,
                                      ),
                                      focusNode: _playlistFocusNodes[index],
                                      onTap: () =>
                                          _navigateToPlaylist(playlist),
                                      onLongPress:
                                          playlist.type ==
                                                  LibraryPlaylistType
                                                      .userPlaylist &&
                                              playlist.playlistId != null
                                          ? () => _showPlaylistMenu(
                                              context,
                                              ref,
                                              playlist,
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
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
    required this.onSubmitted,
    required this.onRequestFirstResultFocus,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String clearTooltip;
  final VoidCallback onSubmitted;
  final VoidCallback onRequestFirstResultFocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      onRequestFirstResultFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleKeyEvent(event),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSubmitted(),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: const MoviAssetIcon(
                  AppAssets.iconSearch,
                  width: 25,
                  height: 25,
                  color: Colors.white70,
                ),
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const MoviAssetIcon(
                        AppAssets.iconDelete,
                        width: 25,
                        height: 25,
                        color: Colors.white,
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
          ),
        );
      },
    );
  }
}
