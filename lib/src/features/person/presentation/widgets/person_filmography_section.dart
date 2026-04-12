import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

/// Displays the filmography lists (movies and series), if available.
class PersonFilmographySection extends StatelessWidget {
  const PersonFilmographySection({
    super.key,
    required this.movies,
    required this.shows,
    this.firstMovieFocusNode,
    this.firstShowFocusNode,
    this.onFirstMovieKeyEvent,
    this.onFirstShowKeyEvent,
  });

  final List<MoviMedia> movies;
  final List<MoviMedia> shows;
  final FocusNode? firstMovieFocusNode;
  final FocusNode? firstShowFocusNode;
  final KeyEventResult Function(KeyEvent event)? onFirstMovieKeyEvent;
  final KeyEventResult Function(KeyEvent event)? onFirstShowKeyEvent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (movies.isNotEmpty) ...[
          MoviItemsList(
            title: AppLocalizations.of(context)!.personMoviesList,
            estimatedItemWidth: 150,
            estimatedItemHeight: 300,
            horizontalFocusAlignment: 0.18,
            titlePadding: 0,
            horizontalPadding: EdgeInsets.zero,
            consumeLeadingEdgeLeftKey: true,
            items: movies
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final media = entry.value;
                  final card = MoviMediaCard(
                    media: media,
                    focusNode: index == 0 ? firstMovieFocusNode : null,
                    onTap: (m) => context.push(
                      AppRouteNames.movie,
                      extra: ContentRouteArgs.movie(m.id),
                    ),
                  );
                  if (index != 0 || onFirstMovieKeyEvent == null) {
                    return card;
                  }
                  return Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) =>
                        onFirstMovieKeyEvent?.call(event) ??
                        KeyEventResult.ignored,
                    child: card,
                  );
                })
                .toList(growable: false),
          ),
        ],
        if (shows.isNotEmpty) ...[
          MoviItemsList(
            title: AppLocalizations.of(context)!.personSeriesList,
            estimatedItemWidth: 150,
            estimatedItemHeight: 300,
            horizontalFocusAlignment: 0.18,
            titlePadding: 0,
            horizontalPadding: EdgeInsets.zero,
            consumeLeadingEdgeLeftKey: true,
            items: shows
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final media = entry.value;
                  final card = MoviMediaCard(
                    media: media,
                    focusNode: index == 0 ? firstShowFocusNode : null,
                    onTap: (m) => context.push(
                      AppRouteNames.tv,
                      extra: ContentRouteArgs.series(m.id),
                    ),
                  );
                  return Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) =>
                        _handleShowCardKeyEvent(event, isFirst: index == 0),
                    child: card,
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  KeyEventResult _handleShowCardKeyEvent(
    KeyEvent event, {
    required bool isFirst,
  }) {
    if (isFirst) {
      final result = onFirstShowKeyEvent?.call(event) ?? KeyEventResult.ignored;
      if (result != KeyEventResult.ignored) {
        return result;
      }
    }
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
