// lib/src/features/search/presentation/widgets/genres_grid.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
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

class GenresGrid extends ConsumerWidget {
  const GenresGrid({
    super.key,
    this.horizontalPadding = 20,
    this.maxContentWidth = double.infinity,
    this.firstItemFocusNode,
  });

  final double horizontalPadding;
  final double maxContentWidth;
  final FocusNode? firstItemFocusNode;

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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    ScreenType screenType,
    Color accent,
    List<TmdbGenre> items,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = _columnCount(
                screenType,
                constraints.maxWidth,
                items.length,
              );
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
                  crossAxisCount: columns,
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final genre = items[index];
                  return _GenreCard(
                    genre: genre,
                    accent: accent,
                    focusNode: index == 0 ? firstItemFocusNode : null,
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
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenType = _screenTypeFor(context);
    final genresAsync = ref.watch(tmdbGenresProvider);

    return genresAsync.when(
      data: (genres) {
        if (genres.movie.isEmpty && genres.series.isEmpty) {
          return const SizedBox.shrink();
        }

        final accent = ref.watch(asp.currentAccentColorProvider);

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
              _buildGrid(context, screenType, accent, genres.movie),
              const SizedBox(height: 16),
            ],
            if (genres.series.isNotEmpty) ...[
              _buildSubTitle(
                context,
                AppLocalizations.of(context)!.seriesTitle,
              ),
              _buildGrid(context, screenType, accent, genres.series),
            ],
          ],
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _GenreCard extends StatelessWidget {
  const _GenreCard({
    required this.genre,
    required this.accent,
    required this.onTap,
    required this.darkenColor,
    this.focusNode,
  });

  final TmdbGenre genre;
  final Color accent;
  final VoidCallback onTap;
  final Color Function(Color color) darkenColor;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return MoviFocusableAction(
      focusNode: focusNode,
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
