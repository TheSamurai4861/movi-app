import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

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
    final cs = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(
      hp.mediaHistoryProvider((contentId: movieId, type: ContentType.movie)),
    );
    final isFavoriteAsync = ref.watch(movieIsFavoriteProvider(movieId));

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
                trailingIcon: Image.asset(
                  AppAssets.iconStarFilled,
                  width: 18,
                  height: 18,
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
                child: MoviPrimaryButton(
                  label: historyAsync.when(
                    data: (entry) => entry != null
                        ? AppLocalizations.of(context)!.resumePlayback
                        : AppLocalizations.of(context)!.homeWatchNow,
                    loading: () => AppLocalizations.of(context)!.homeWatchNow,
                    error: (_, __) =>
                        AppLocalizations.of(context)!.homeWatchNow,
                  ),
                  assetIcon: AppAssets.iconPlay,
                  buttonStyle: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  onPressed: onPlay,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 40,
                height: 40,
                child: isFavoriteAsync.when(
                  data: (isFavorite) => MoviFavoriteButton(
                    isFavorite: isFavorite,
                    onPressed: () async {
                      await ref
                          .read(movieToggleFavoriteProvider.notifier)
                          .toggle(movieId);
                    },
                  ),
                  loading: () =>
                      MoviFavoriteButton(isFavorite: false, onPressed: () {}),
                  error: (_, __) =>
                      MoviFavoriteButton(isFavorite: false, onPressed: () {}),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
