// lib/src/features/search/presentation/widgets/genres_grid.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/search/domain/entities/tmdb_genre.dart';
import 'package:movi/src/features/search/presentation/models/genre_all_results_args.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

enum _GenreSection { movie, series }

class GenresGrid extends ConsumerStatefulWidget {
  const GenresGrid({
    super.key,
    this.horizontalPadding = 20,
    this.maxContentWidth = double.infinity,
    this.firstItemFocusNode,
    this.onFirstItemLeft,
    this.onFirstRowUp,
    this.focusRequestId,
    this.focusRequestColumn,
    this.focusVerticalAlignment = 0.22,
  });

  final double horizontalPadding;
  final double maxContentWidth;
  final FocusNode? firstItemFocusNode;
  final VoidCallback? onFirstItemLeft;
  final ValueChanged<int>? onFirstRowUp;
  final int? focusRequestId;
  final int? focusRequestColumn;
  final double focusVerticalAlignment;

  @override
  ConsumerState<GenresGrid> createState() => _GenresGridState();
}

class _GenresGridState extends ConsumerState<GenresGrid> {
  final Map<String, FocusNode> _genreFocusNodes = <String, FocusNode>{};

  ScreenType _screenTypeFor(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ScreenTypeResolver.instance.resolve(size.width, size.height);
  }

  int _columnCount(ScreenType screenType, double width, int itemCount) {
    final maxColumns = switch (screenType) {
      ScreenType.mobile => 2,
      ScreenType.tablet => 3,
      ScreenType.desktop => 4,
      ScreenType.tv => 5,
    };
    final minTileWidth = switch (screenType) {
      ScreenType.mobile => 150.0,
      ScreenType.tablet => 180.0,
      ScreenType.desktop => 220.0,
      ScreenType.tv => 220.0,
    };
    final computed = ((width + 16) / (minTileWidth + 16)).floor();
    return math.max(1, math.min(itemCount, computed.clamp(2, maxColumns)));
  }

  MoviMediaType _toMoviMediaType(ContentType type) {
    return switch (type) {
      ContentType.movie => MoviMediaType.movie,
      ContentType.series => MoviMediaType.series,
      _ => MoviMediaType.movie,
    };
  }

  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.65).clamp(0.0, 1.0)).toColor();
  }

  String _genreKey(TmdbGenre genre) => '${genre.type.name}-${genre.id}';

  bool _isOverallFirst(
    _GenreSection section,
    int index,
    List<TmdbGenre> movieGenres,
  ) {
    if (index != 0) return false;
    return switch (section) {
      _GenreSection.movie => true,
      _GenreSection.series => movieGenres.isEmpty,
    };
  }

  void _syncFocusNodes({
    required List<TmdbGenre> movieGenres,
    required List<TmdbGenre> seriesGenres,
  }) {
    final usesExternalFirst = widget.firstItemFocusNode != null;
    final activeKeys = <String>{};

    for (var index = 0; index < movieGenres.length; index++) {
      if (!(usesExternalFirst && index == 0)) {
        activeKeys.add(_genreKey(movieGenres[index]));
      }
    }
    for (var index = 0; index < seriesGenres.length; index++) {
      if (!(usesExternalFirst && movieGenres.isEmpty && index == 0)) {
        activeKeys.add(_genreKey(seriesGenres[index]));
      }
    }

    final staleKeys = _genreFocusNodes.keys
        .where((key) => !activeKeys.contains(key))
        .toList(growable: false);
    for (final key in staleKeys) {
      _genreFocusNodes.remove(key)?.dispose();
    }
  }

  FocusNode _focusNodeFor(
    TmdbGenre genre, {
    required bool useExternalFirstFocusNode,
  }) {
    if (useExternalFirstFocusNode && widget.firstItemFocusNode != null) {
      return widget.firstItemFocusNode!;
    }
    return _genreFocusNodes.putIfAbsent(
      _genreKey(genre),
      () => FocusNode(debugLabel: 'Genre-${genre.type.name}-${genre.id}'),
    );
  }

  bool _requestGenreFocus(
    TmdbGenre genre, {
    required bool useExternalFirstFocusNode,
  }) {
    final node = _focusNodeFor(
      genre,
      useExternalFirstFocusNode: useExternalFirstFocusNode,
    );
    if (!node.canRequestFocus || node.context == null) {
      return false;
    }
    node.requestFocus();
    return true;
  }

  int _lastRowAlignedIndex({
    required int itemCount,
    required int columns,
    required int column,
  }) {
    final lastRowStart = ((itemCount - 1) ~/ columns) * columns;
    return math.min(lastRowStart + column, itemCount - 1);
  }

  void _applyPendingFocusRequest({
    required List<TmdbGenre> movieGenres,
    required List<TmdbGenre> seriesGenres,
  }) {
    final requestColumn = widget.focusRequestColumn;
    if (widget.focusRequestId == null || requestColumn == null) return;
    if (movieGenres.isEmpty && seriesGenres.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (movieGenres.isNotEmpty) {
        final targetIndex = math.min(requestColumn, movieGenres.length - 1);
        _requestGenreFocus(
          movieGenres[targetIndex],
          useExternalFirstFocusNode: _isOverallFirst(
            _GenreSection.movie,
            targetIndex,
            movieGenres,
          ),
        );
        return;
      }
      final targetIndex = math.min(requestColumn, seriesGenres.length - 1);
      _requestGenreFocus(
        seriesGenres[targetIndex],
        useExternalFirstFocusNode: _isOverallFirst(
          _GenreSection.series,
          targetIndex,
          movieGenres,
        ),
      );
    });
  }

  KeyEventResult _handleGenreKey({
    required KeyEvent event,
    required _GenreSection section,
    required int index,
    required int sectionColumns,
    required int movieColumns,
    required List<TmdbGenre> movieGenres,
    required List<TmdbGenre> seriesGenres,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final sectionGenres = switch (section) {
      _GenreSection.movie => movieGenres,
      _GenreSection.series => seriesGenres,
    };
    final column = index % sectionColumns;

    bool focusMovieIndex(int targetIndex) {
      return _requestGenreFocus(
        movieGenres[targetIndex],
        useExternalFirstFocusNode: _isOverallFirst(
          _GenreSection.movie,
          targetIndex,
          movieGenres,
        ),
      );
    }

    bool focusSeriesIndex(int targetIndex) {
      return _requestGenreFocus(
        seriesGenres[targetIndex],
        useExternalFirstFocusNode: _isOverallFirst(
          _GenreSection.series,
          targetIndex,
          movieGenres,
        ),
      );
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (column == 0) {
          widget.onFirstItemLeft?.call();
          return KeyEventResult.handled;
        }
        if (index > 0) {
          final handled = switch (section) {
            _GenreSection.movie => focusMovieIndex(index - 1),
            _GenreSection.series => focusSeriesIndex(index - 1),
          };
          return handled ? KeyEventResult.handled : KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (index + 1 < sectionGenres.length) {
          final handled = switch (section) {
            _GenreSection.movie => focusMovieIndex(index + 1),
            _GenreSection.series => focusSeriesIndex(index + 1),
          };
          return handled ? KeyEventResult.handled : KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (index - sectionColumns >= 0) {
          final handled = switch (section) {
            _GenreSection.movie => focusMovieIndex(index - sectionColumns),
            _GenreSection.series => focusSeriesIndex(index - sectionColumns),
          };
          return handled ? KeyEventResult.handled : KeyEventResult.ignored;
        }
        if (section == _GenreSection.series && movieGenres.isNotEmpty) {
          final targetIndex = _lastRowAlignedIndex(
            itemCount: movieGenres.length,
            columns: movieColumns,
            column: column,
          );
          final handled = focusMovieIndex(targetIndex);
          return handled ? KeyEventResult.handled : KeyEventResult.ignored;
        }
        if (section == _GenreSection.movie) {
          widget.onFirstRowUp?.call(column);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (index + sectionColumns < sectionGenres.length) {
          final handled = switch (section) {
            _GenreSection.movie => focusMovieIndex(index + sectionColumns),
            _GenreSection.series => focusSeriesIndex(index + sectionColumns),
          };
          return handled ? KeyEventResult.handled : KeyEventResult.ignored;
        }
        if (section == _GenreSection.movie && seriesGenres.isNotEmpty) {
          final targetIndex = math.min(column, seriesGenres.length - 1);
          final handled = focusSeriesIndex(targetIndex);
          return handled ? KeyEventResult.handled : KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSubTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    ScreenType screenType,
    Color accent,
    List<TmdbGenre> items,
    _GenreSection section, {
    required int sectionColumns,
    required int movieColumns,
    required List<TmdbGenre> movieGenres,
    required List<TmdbGenre> seriesGenres,
  }) {
    final aspectRatio = switch (screenType) {
      ScreenType.mobile => 2.0,
      ScreenType.tablet => 2.05,
      ScreenType.desktop => 2.15,
      ScreenType.tv => 2.2,
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: sectionColumns,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final genre = items[index];
        final card = _GenreCard(
          genre: genre,
          accent: accent,
          focusVerticalAlignment: widget.focusVerticalAlignment,
          focusNode: _focusNodeFor(
            genre,
            useExternalFirstFocusNode: _isOverallFirst(
              section,
              index,
              movieGenres,
            ),
          ),
          onTap: () {
            context.push(
              AppRouteNames.genreAllResults,
              extra: GenreAllResultsArgs(
                genreId: genre.id,
                genreName: genre.name,
                type: _toMoviMediaType(genre.type),
              ),
            );
          },
          darkenColor: _darkenColor,
        );

        return Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleGenreKey(
            event: event,
            section: section,
            index: index,
            sectionColumns: sectionColumns,
            movieColumns: movieColumns,
            movieGenres: movieGenres,
            seriesGenres: seriesGenres,
          ),
          child: card,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenType = _screenTypeFor(context);
    final genresAsync = ref.watch(tmdbGenresProvider);

    return genresAsync.when(
      data: (genres) {
        if (genres.movie.isEmpty && genres.series.isEmpty) {
          return const SizedBox.shrink();
        }

        _syncFocusNodes(movieGenres: genres.movie, seriesGenres: genres.series);

        final accent = ref.watch(asp.currentAccentColorProvider);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final movieColumns = genres.movie.isEmpty
                      ? 1
                      : _columnCount(
                          screenType,
                          constraints.maxWidth,
                          genres.movie.length,
                        );
                  final seriesColumns = genres.series.isEmpty
                      ? 1
                      : _columnCount(
                          screenType,
                          constraints.maxWidth,
                          genres.series.length,
                        );
                  _applyPendingFocusRequest(
                    movieGenres: genres.movie,
                    seriesGenres: genres.series,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        context,
                        AppLocalizations.of(context)!.searchByGenresTitle,
                      ),
                      const SizedBox(height: 16),
                      if (genres.movie.isNotEmpty) ...[
                        _buildSubTitle(
                          context,
                          AppLocalizations.of(context)!.moviesTitle,
                        ),
                        _buildGrid(
                          context,
                          screenType,
                          accent,
                          genres.movie,
                          _GenreSection.movie,
                          sectionColumns: movieColumns,
                          movieColumns: movieColumns,
                          movieGenres: genres.movie,
                          seriesGenres: genres.series,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (genres.series.isNotEmpty) ...[
                        _buildSubTitle(
                          context,
                          AppLocalizations.of(context)!.seriesTitle,
                        ),
                        _buildGrid(
                          context,
                          screenType,
                          accent,
                          genres.series,
                          _GenreSection.series,
                          sectionColumns: seriesColumns,
                          movieColumns: movieColumns,
                          movieGenres: genres.movie,
                          seriesGenres: genres.series,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.horizontalPadding,
          vertical: 16,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    for (final node in _genreFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }
}

class _GenreCard extends StatelessWidget {
  const _GenreCard({
    required this.genre,
    required this.accent,
    required this.onTap,
    required this.darkenColor,
    this.focusNode,
    this.focusVerticalAlignment,
  });

  final TmdbGenre genre;
  final Color accent;
  final VoidCallback onTap;
  final Color Function(Color color) darkenColor;
  final FocusNode? focusNode;
  final double? focusVerticalAlignment;

  @override
  Widget build(BuildContext context) {
    return MoviFocusableAction(
      focusNode: focusNode,
      ensureVisibleVerticalAlignment: focusVerticalAlignment,
      onPressed: onTap,
      semanticLabel: genre.name,
      builder: (context, state) {
        return MoviFocusFrame(
          scale: state.focused ? 1.03 : 1,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [accent, darkenColor(accent)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.focused ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: accent.withValues(alpha: 0.5)),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        genre.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
