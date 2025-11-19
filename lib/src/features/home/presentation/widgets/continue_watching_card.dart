import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/widgets/movi_pill.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';
import 'package:movi/src/core/utils/app_assets.dart';

class ContinueWatchingCard extends ConsumerWidget {
  const ContinueWatchingCard._({
    required this.title,
    this.backdrop,
    required this.progress,
    this.year,
    this.duration,
    this.rating,
    this.seriesTitle,
    this.seasonEpisode,
    this.isEpisode = false,
    this.onTap,
    this.onLongPress,
  });

  factory ContinueWatchingCard.movie({
    required String title,
    String? backdrop,
    required double progress,
    int? year,
    Duration? duration,
    double? rating,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) => ContinueWatchingCard._(
    title: title,
    backdrop: backdrop,
    progress: progress,
    year: year,
    duration: duration,
    rating: rating,
    isEpisode: false,
    onTap: onTap,
    onLongPress: onLongPress,
  );

  factory ContinueWatchingCard.episode({
    required String title,
    String? backdrop,
    required double progress,
    required String seasonEpisode,
    Duration? duration,
    String? seriesTitle,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) => ContinueWatchingCard._(
    title: title,
    backdrop: backdrop,
    progress: progress,
    duration: duration,
    seriesTitle: seriesTitle,
    seasonEpisode: seasonEpisode,
    isEpisode: true,
    onTap: onTap,
    onLongPress: onLongPress,
  );

  final String title;
  final String? backdrop;
  final double progress; // 0..1
  final int? year;
  final Duration? duration;
  final double? rating;
  final String? seriesTitle;
  final String? seasonEpisode;
  final bool isEpisode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  String _formatDuration(Duration? d) {
    if (d == null) return '';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  String _formatRating(double? r) {
    if (r == null) return '';
    return r.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double width = 300;
    const double height = 165;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                // Background image (backdrop paysage)
                Positioned.fill(
                  child: _buildBackdropImage(context, ref, backdrop),
                ),
                // Bottom gradient overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
                // Progress line (5px)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      children: [
                        Container(color: const Color(0xFFA6A6A6)),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content based on type
                if (isEpisode)
                  _buildEpisodeContent(width)
                else
                  _buildMovieContent(width),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieContent(double width) {
    // Ordre du haut vers le bas :
    // - Titre film
    // - 8px gap
    // - Pills
    // - 16px gap
    // - Bottom (progress bar à 5px)

    return Stack(
      children: [
        // Pills row (16px from bottom = 5px progress + 11px)
        Positioned(
          left: 10,
          bottom: 16,
          child: Row(
            children: [
              if (year != null) MoviPill(year.toString()),
              if (year != null && (duration != null || rating != null))
                const SizedBox(width: 8),
              if (duration != null) ...[
                MoviPill(_formatDuration(duration)),
                if (rating != null) const SizedBox(width: 8),
              ],
              if (rating != null)
                MoviPill(
                  _formatRating(rating),
                  trailingIcon: Image.asset(
                    AppAssets.iconStarFilled,
                    width: 14,
                    height: 14,
                  ),
                ),
            ],
          ),
        ),
        // Title (8px above pills = 16 + 8 + ~24px pill height = 48px from bottom)
        Positioned(
          left: 10,
          bottom: 48, // 16 (pills bottom) + 8 (gap) + ~24 (pill height)
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width - 20),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeContent(double width) {
    // Ordre du haut vers le bas :
    // - Titre série
    // - 8px gap
    // - Titre épisode
    // - 8px gap
    // - Pills
    // - 16px gap
    // - Bottom (progress bar à 5px)

    // Calculer les positions depuis le bas
    // Pills = 16px from bottom
    // Episode title = 16 + 8 + ~24px pill height = 48px from bottom
    // Series title = 48 + 8 + ~20px text height = 76px from bottom

    return Stack(
      children: [
        // Pills row (16px from bottom)
        Positioned(
          left: 10,
          bottom: 16,
          child: Row(
            children: [
              if (seasonEpisode != null && seasonEpisode!.isNotEmpty)
                MoviPill(seasonEpisode!),
              if (seasonEpisode != null &&
                  seasonEpisode!.isNotEmpty &&
                  duration != null)
                const SizedBox(width: 8),
              if (duration != null) MoviPill(_formatDuration(duration)),
            ],
          ),
        ),
        // Episode title (8px above pills = 48px from bottom)
        Positioned(
          left: 10,
          bottom: 48, // 16 (pills bottom) + 8 (gap) + ~24 (pill height)
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width - 20),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Series title (8px above episode title = 76px from bottom)
        if (seriesTitle != null)
          Positioned(
            left: 10,
            bottom: 76, // 48 (episode bottom) + 8 (gap) + ~20 (text height)
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width - 20),
              child: Text(
                seriesTitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBackdropImage(
    BuildContext context,
    WidgetRef ref,
    String? source,
  ) {
    if (source != null && source.isNotEmpty && source.startsWith('http')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => MoviPlaceholderCard(
          type: PlaceholderType.movie,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.zero,
        ),
      );
    }
    return MoviPlaceholderCard(
      type: PlaceholderType.movie,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.zero,
    );
  }
}
