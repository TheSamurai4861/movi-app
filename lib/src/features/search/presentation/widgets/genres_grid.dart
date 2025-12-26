// lib/src/features/search/presentation/widgets/genres_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/features/search/domain/entities/tmdb_genre.dart';
import 'package:movi/src/features/search/presentation/models/genre_all_results_args.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

class GenresGrid extends ConsumerWidget {
  const GenresGrid({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(tmdbGenresProvider);

    return genresAsync.when(
      data: (genres) {
        if (genres.movie.isEmpty && genres.series.isEmpty) {
          return const SizedBox.shrink();
        }

        final accent = ref.watch(asp.currentAccentColorProvider);

        Widget buildGrid(List<TmdbGenre> items) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final genre = items[index];
                return InkWell(
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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [accent, _darkenColor(accent)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: accent.withValues(alpha: 0.5),
                          ),
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
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                AppLocalizations.of(context)!.searchByGenresTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (genres.movie.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  AppLocalizations.of(context)!.moviesTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              buildGrid(genres.movie),
              const SizedBox(height: 16),
            ],
            if (genres.series.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  AppLocalizations.of(context)!.seriesTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              buildGrid(genres.series),
            ],
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
