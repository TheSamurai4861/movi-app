import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/features/search/presentation/controllers/search_instant_controller.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';

class AddMediaSearchModal extends ConsumerStatefulWidget {
  const AddMediaSearchModal({super.key, required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<AddMediaSearchModal> createState() =>
      _AddMediaSearchModalState();
}

class _AddMediaSearchModalState extends ConsumerState<AddMediaSearchModal> {
  final _textCtrl = TextEditingController();
  final _addedMediaIds = <String>{};

  @override
  void initState() {
    super.initState();
    // Charger les items existants de la playlist pour vérifier les doublons
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingItems();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingItems() async {
    try {
      final itemsAsync = await ref.read(
        playlistItemsProvider(widget.playlistId).future,
      );
      setState(() {
        _addedMediaIds.addAll(itemsAsync.map((item) => item.reference.id));
      });
    } catch (_) {
      // Ignorer les erreurs
    }
  }

  Future<void> _addMediaToPlaylist(ContentReference reference) async {
    // Vérifier si le média est déjà dans la playlist
    if (_addedMediaIds.contains(reference.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce média est déjà dans la playlist'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      final addPlaylistItem = ref.read(addPlaylistItemUseCaseProvider);

      await addPlaylistItem.call(
        playlistId: PlaylistId(widget.playlistId),
        item: PlaylistItem(reference: reference, addedAt: DateTime.now()),
      );

      setState(() {
        _addedMediaIds.add(reference.id);
      });

      // Invalider le provider des items de la playlist pour forcer le rafraîchissement
      ref.invalidate(playlistItemsProvider(widget.playlistId));
      ref.invalidate(playlistContentReferencesProvider(widget.playlistId));
      ref.invalidate(libraryPlaylistsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajouté à la playlist'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  ContentReference _movieToContentReference(MovieSummary movie) {
    return ContentReference(
      id: movie.id.value,
      title: movie.title,
      type: ContentType.movie,
      poster: movie.poster,
      year: movie.releaseYear,
    );
  }

  ContentReference _showToContentReference(TvShowSummary show) {
    return ContentReference(
      id: show.id.value,
      title: show.title,
      type: ContentType.series,
      poster: show.poster,
      year: null, // TvShowSummary n'a pas de year
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final ctrl = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête avec titre et bouton fermer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ajouter des médias',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Champ de recherche
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Builder(
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return TextField(
                    controller: _textCtrl,
                    onChanged: (value) {
                      ctrl.setQuery(value);
                    },
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHint,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Image.asset(
                          'assets/icons/search.png',
                          width: 25,
                          height: 25,
                        ),
                      ),
                      suffixIcon: _textCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Image.asset(
                                'assets/icons/supprimer.png',
                                width: 25,
                                height: 25,
                              ),
                              onPressed: () {
                                _textCtrl.clear();
                                ctrl.setQuery('');
                              },
                              tooltip: AppLocalizations.of(context)!.clear,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // Résultats de recherche
            Expanded(child: _buildResults(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, SearchState state) {
    if (state.query.trim().length < 3) {
      return Center(
        child: Text(
          'Tapez au moins 3 caractères pour rechercher',
          style:
              Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white70) ??
              const TextStyle(fontSize: 16, color: Colors.white70),
        ),
      );
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text(state.error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (state.movies.isEmpty && state.shows.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noResults,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (state.movies.isNotEmpty) ...[
          MoviItemsList(
            title: AppLocalizations.of(context)!.moviesTitle,
            subtitle: AppLocalizations.of(
              context,
            )!.resultsCount(state.movies.length),
            estimatedItemWidth: 150,
            estimatedItemHeight: 300,
            titlePadding: 0,
            horizontalPadding: EdgeInsets.zero,
            items: state.movies
                .take(20)
                .toList()
                .asMap()
                .entries
                .map(
                  (entry) => _MediaCardWithBadge(
                    media: MoviMedia(
                      id: entry.value.id.value,
                      title: entry.value.title.display,
                      poster: entry.value.poster,
                      type: MoviMediaType.movie,
                    ),
                    isAdded: _addedMediaIds.contains(entry.value.id.value),
                    onTap: (media) {
                      final ref = _movieToContentReference(entry.value);
                      _addMediaToPlaylist(ref);
                    },
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (state.shows.isNotEmpty) ...[
          const SizedBox(height: 16),
          MoviItemsList(
            title: AppLocalizations.of(context)!.seriesTitle,
            subtitle: AppLocalizations.of(
              context,
            )!.resultsCount(state.shows.length),
            estimatedItemWidth: 150,
            estimatedItemHeight: 300,
            titlePadding: 0,
            horizontalPadding: EdgeInsets.zero,
            items: state.shows
                .take(20)
                .toList()
                .asMap()
                .entries
                .map(
                  (entry) => _MediaCardWithBadge(
                    media: MoviMedia(
                      id: entry.value.id.value,
                      title: entry.value.title.display,
                      poster: entry.value.poster,
                      type: MoviMediaType.series,
                    ),
                    isAdded: _addedMediaIds.contains(entry.value.id.value),
                    onTap: (media) {
                      final ref = _showToContentReference(entry.value);
                      _addMediaToPlaylist(ref);
                    },
                  ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 100),
      ],
    );
  }
}

class _MediaCardWithBadge extends StatelessWidget {
  const _MediaCardWithBadge({
    required this.media,
    required this.isAdded,
    required this.onTap,
  });

  final MoviMedia media;
  final bool isAdded;
  final ValueChanged<MoviMedia> onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MoviMediaCard(media: media, onTap: (m) => onTap(m)),
        if (isAdded)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Ajouté',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
