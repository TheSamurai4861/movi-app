import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/theme/app_colors.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class MovieDetailMainActions extends ConsumerWidget {
  const MovieDetailMainActions({
    super.key,
    required this.mediaTitle,
    required this.yearText,
    required this.durationText,
    required this.ratingText,
    required this.movieId,
    required this.onPlay,
  });

  final String mediaTitle;
  final String yearText;
  final String durationText;
  final String ratingText;
  final String movieId;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(
      hp.mediaHistoryProvider((contentId: movieId, type: ContentType.movie)),
    );
    final isFavoriteAsync = ref.watch(movieIsFavoriteProvider(movieId));

    final playLabel = historyAsync.maybeWhen(
      data: (history) => history == null
          ? localizations.homeWatchNow
          : localizations.homeContinueWatching,
      orElse: () => localizations.homeWatchNow,
    );

    Future<void> toggleFavorite() async {
      final repository = ref.read(movieRepositoryProvider);
      final isFavorite = await ref.read(
        movieIsFavoriteProvider(movieId).future,
      );
      await repository.setWatchlist(MovieId(movieId), saved: !isFavorite);
      ref.invalidate(movieIsFavoriteProvider(movieId));
    }

    return Column(
      children: [
        SizedBox(
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MoviPill(
                yearText,
                large: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: const Color(0xFF292929),
              ),
              const SizedBox(width: 8),
              MoviPill(
                durationText,
                large: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: const Color(0xFF292929),
              ),
              const SizedBox(width: 8),
              MoviPill(
                ratingText,
                large: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: const Color(0xFF292929),
                trailingIcon: const MoviAssetIcon(
                  AppAssets.iconStarFilled,
                  width: 18,
                  height: 18,
                  color: AppColors.ratingAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 55,
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: '$playLabel $mediaTitle',
                  button: true,
                  child: MoviPrimaryButton(
                    label: playLabel,
                    assetIcon: AppAssets.iconPlay,
                    onPressed: onPlay,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              isFavoriteAsync.when(
                data: (isFavorite) => MoviFavoriteButton(
                  isFavorite: isFavorite,
                  onPressed: () {
                    toggleFavorite();
                  },
                ),
                loading: () =>
                    MoviFavoriteButton(isFavorite: false, onPressed: () {}),
                error: (_, __) =>
                    MoviFavoriteButton(isFavorite: false, onPressed: () {}),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
