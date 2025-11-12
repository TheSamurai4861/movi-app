import 'package:flutter/material.dart';
import 'package:movi/src/core/widgets/widgets.dart';

class ContinueWatchingCard extends StatelessWidget {
  const ContinueWatchingCard._({
    required this.title,
    required this.poster,
    required this.progress,
    this.year,
    this.duration,
    this.rating,
    this.seriesTitle,
    this.seasonEpisode,
    this.onTap,
  });

  factory ContinueWatchingCard.movie({
    required String title,
    required String poster,
    required double progress,
    String? year,
    String? duration,
    String? rating,
    VoidCallback? onTap,
  }) => ContinueWatchingCard._(
    title: title,
    poster: poster,
    progress: progress,
    year: year,
    duration: duration,
    rating: rating,
    onTap: onTap,
  );

  factory ContinueWatchingCard.episode({
    required String title,
    required String poster,
    required double progress,
    required String seasonEpisode,
    String? duration,
    String? rating,
    String? seriesTitle,
    VoidCallback? onTap,
  }) => ContinueWatchingCard._(
    title: title,
    poster: poster,
    progress: progress,
    duration: duration,
    rating: rating,
    seriesTitle: seriesTitle,
    seasonEpisode: seasonEpisode,
    onTap: onTap,
  );

  final String title;
  final String poster;
  final double progress; // 0..1
  final String? year;
  final String? duration;
  final String? rating;
  final String? seriesTitle;
  final String? seasonEpisode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const double width = 300;
    const double height = 165;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              // Background image
              Positioned.fill(child: _buildPosterImage(poster)),
              // Bottom gradient overlay (double overlay 404040)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF404040), Color(0x00404040)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF404040), Color(0x00404040)],
                    ),
                  ),
                ),
              ),
              // Progress lines (5px): background then accent (progress)
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
              // Pills row (8px above progress)
              Positioned(
                left: 16,
                bottom: 5 + 8 + 24, // approx pill height
                child: Row(
                  children: [
                    if (seasonEpisode != null) MoviPill(seasonEpisode!),
                    if (seasonEpisode == null && year != null) MoviPill(year!),
                    if ((seasonEpisode != null) || (year != null))
                      const SizedBox(width: 8),
                    if (duration != null) ...[
                      MoviPill(duration!),
                      const SizedBox(width: 8),
                    ],
                    if (rating != null) MoviPill(rating!),
                  ],
                ),
              ),
              // Title (8px above pills)
              Positioned(
                left: 16,
                bottom:
                    5 +
                    8 +
                    24 +
                    8 +
                    20, // line + gap + pill + gap + approx title
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: width - 32),
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
              // Series title if episode (8px above title)
              if (seriesTitle != null)
                Positioned(
                  left: 16,
                  bottom: 5 + 8 + 24 + 8 + 20 + 8 + 18,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: width - 32),
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
          ),
        ),
      ),
    );
  }
}

Widget _buildPosterImage(String source) {
  if (source.startsWith('http')) {
    return Image.network(source, fit: BoxFit.cover);
  }
  return Image.asset(source, fit: BoxFit.cover);
}
