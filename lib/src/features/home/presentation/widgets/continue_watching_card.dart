import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';
import 'package:movi/src/core/theme/app_colors.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_network_image.dart';
import 'package:movi/src/core/widgets/movi_pill.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';

class ContinueWatchingCard extends ConsumerStatefulWidget {
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
  final double progress;
  final int? year;
  final Duration? duration;
  final double? rating;
  final String? seriesTitle;
  final String? seasonEpisode;
  final bool isEpisode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  ConsumerState<ContinueWatchingCard> createState() =>
      _ContinueWatchingCardState();
}

class _ContinueWatchingCardState extends ConsumerState<ContinueWatchingCard> {
  bool _focused = false;

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
  Widget build(BuildContext context) {
    final uiScale = context.tvUiScale;
    final width = 300.0 * uiScale;
    final height = 165.0 * uiScale;
    final focusBorderWidth = 2.0 * uiScale;
    final radiusValue = 16.0 * uiScale;
    final focusShadowBlur = 18.0 * uiScale;
    final focusShadowSpread = 1.0 * uiScale;
    final progressBarHeight = 5.0 * uiScale;
    final gradientHeight = 150.0 * uiScale;
    final contentInset = 10.0 * uiScale;
    final pillsBottom = 16.0 * uiScale;
    final titleBottom = 52.0 * uiScale;
    final seriesTitleBottom = 76.0 * uiScale;
    final horizontalGap = 8.0 * uiScale;
    final borderRadius = BorderRadius.circular(radiusValue);
    final innerBorderRadius = BorderRadius.circular(
      radiusValue - focusBorderWidth,
    );
    final accent = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onFocusChange: (focused) {
          if (_focused == focused) return;
          setState(() => _focused = focused);
        },
        borderRadius: borderRadius,
        child: AnimatedScale(
          scale: _focused ? 1.035 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(focusBorderWidth),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: _focused ? accent : Colors.transparent,
                width: focusBorderWidth,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18),
                        blurRadius: focusShadowBlur,
                        spreadRadius: focusShadowSpread,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: innerBorderRadius,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildBackdropImage(widget.backdrop),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: gradientHeight,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFF000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SizedBox(
                        height: progressBarHeight,
                        child: Stack(
                          children: [
                            Container(
                              color: const Color.fromARGB(255, 97, 97, 97),
                            ),
                            FractionallySizedBox(
                              widthFactor: widget.progress.clamp(0.0, 1.0),
                              alignment: Alignment.centerLeft,
                              child: Container(color: accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.isEpisode)
                      _buildEpisodeContent(
                        width,
                        contentInset: contentInset,
                        pillsBottom: pillsBottom,
                        titleBottom: titleBottom,
                        seriesTitleBottom: seriesTitleBottom,
                        horizontalGap: horizontalGap,
                        uiScale: uiScale,
                      )
                    else
                      _buildMovieContent(
                        width,
                        contentInset: contentInset,
                        pillsBottom: pillsBottom,
                        titleBottom: titleBottom,
                        horizontalGap: horizontalGap,
                        uiScale: uiScale,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieContent(
    double width, {
    required double contentInset,
    required double pillsBottom,
    required double titleBottom,
    required double horizontalGap,
    required double uiScale,
  }) {
    return Stack(
      children: [
        Positioned(
          left: contentInset,
          bottom: pillsBottom,
          child: Row(
            children: [
              if (widget.year != null) MoviPill(widget.year.toString()),
              if (widget.year != null &&
                  (widget.duration != null || widget.rating != null))
                SizedBox(width: horizontalGap),
              if (widget.duration != null) ...[
                MoviPill(_formatDuration(widget.duration)),
                if (widget.rating != null) SizedBox(width: horizontalGap),
              ],
              if (widget.rating != null)
                MoviPill(
                  _formatRating(widget.rating),
                  trailingIcon: MoviAssetIcon(
                    AppAssets.iconStarFilled,
                    width: 14 * uiScale,
                    height: 14 * uiScale,
                    color: AppColors.ratingAccent,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: contentInset,
          bottom: titleBottom,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width - (contentInset * 2)),
            child: Text(
              widget.title,
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

  Widget _buildEpisodeContent(
    double width, {
    required double contentInset,
    required double pillsBottom,
    required double titleBottom,
    required double seriesTitleBottom,
    required double horizontalGap,
    required double uiScale,
  }) {
    return Stack(
      children: [
        Positioned(
          left: contentInset,
          bottom: pillsBottom,
          child: Row(
            children: [
              if (widget.seasonEpisode != null &&
                  widget.seasonEpisode!.isNotEmpty)
                MoviPill(widget.seasonEpisode!),
              if (widget.seasonEpisode != null &&
                  widget.seasonEpisode!.isNotEmpty &&
                  widget.duration != null)
                SizedBox(width: horizontalGap),
              if (widget.duration != null)
                MoviPill(_formatDuration(widget.duration)),
            ],
          ),
        ),
        Positioned(
          left: contentInset,
          bottom: titleBottom,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width - (contentInset * 2)),
            child: Text(
              widget.title,
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
        if (widget.seriesTitle != null)
          Positioned(
            left: contentInset,
            bottom: seriesTitleBottom,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width - (contentInset * 2)),
              child: Text(
                widget.seriesTitle!,
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

  Widget _buildBackdropImage(String? source) {
    if (source != null && source.isNotEmpty && source.startsWith('http')) {
      return MoviNetworkImage(
        source,
        fit: BoxFit.cover,
        cacheWidth: 900,
        cacheHeight: 495,
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
