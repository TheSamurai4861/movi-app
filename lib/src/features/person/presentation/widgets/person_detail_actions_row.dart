import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/person/presentation/providers/person_detail_providers.dart';

/// Displays action buttons: Play randomly and Favorite toggle.
class PersonDetailActionsRow extends ConsumerWidget {
  const PersonDetailActionsRow({
    super.key,
    required this.personId,
    required this.movies,
    required this.shows,
    this.primaryActionFocusNode,
    this.favoriteActionFocusNode,
    this.onPrimaryActionKeyEvent,
    this.onFavoriteActionKeyEvent,
  });

  final String personId;
  final List<MoviMedia> movies;
  final List<MoviMedia> shows;
  final FocusNode? primaryActionFocusNode;
  final FocusNode? favoriteActionFocusNode;
  final KeyEventResult Function(KeyEvent event)? onPrimaryActionKeyEvent;
  final KeyEventResult Function(KeyEvent event)? onFavoriteActionKeyEvent;
  static const double _heroFocusVerticalAlignment = 0.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const iconActionFocusedBackground = Color(0x807A7A7A);
    return Row(
      children: [
        Expanded(
          child: MoviEnsureVisibleOnFocus(
            verticalAlignment: _heroFocusVerticalAlignment,
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: (_, event) =>
                  onPrimaryActionKeyEvent?.call(event) ??
                  KeyEventResult.ignored,
              child: MoviPrimaryButton(
                focusNode: primaryActionFocusNode,
                label: AppLocalizations.of(context)!.personPlayRandomly,
                assetIcon: AppAssets.iconPlay,
                onPressed: () {
                  final allMedia = [...movies, ...shows];
                  if (allMedia.isNotEmpty) {
                    final random = Random();
                    final randomMedia = allMedia[random.nextInt(allMedia.length)];
                    context.push(
                      randomMedia.type == MoviMediaType.movie
                          ? AppRouteNames.movie
                          : AppRouteNames.tv,
                      extra: randomMedia,
                    );
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Consumer(
          builder: (context, ref, _) {
            final isFavoriteAsync = ref.watch(
              personIsFavoriteProvider(personId),
            );
            return isFavoriteAsync.when(
              data: (isFavorite) => MoviEnsureVisibleOnFocus(
                verticalAlignment: _heroFocusVerticalAlignment,
                child: Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, event) =>
                      onFavoriteActionKeyEvent?.call(event) ??
                      KeyEventResult.ignored,
                  child: MoviFavoriteButton(
                    focusNode: favoriteActionFocusNode,
                    isFavorite: isFavorite,
                    size: 44,
                    iconSize: 28,
                    focusPadding: const EdgeInsets.all(5),
                    focusedBackgroundColor: iconActionFocusedBackground,
                    focusedBorderColor: Theme.of(context).colorScheme.primary,
                    borderWidth: 2,
                    onPressed: () async {
                      await ref
                          .read(personToggleFavoriteProvider.notifier)
                          .toggle(personId);
                    },
                  ),
                ),
              ),
              loading: () => MoviEnsureVisibleOnFocus(
                verticalAlignment: _heroFocusVerticalAlignment,
                child: Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, event) =>
                      onFavoriteActionKeyEvent?.call(event) ??
                      KeyEventResult.ignored,
                  child: MoviFavoriteButton(
                    focusNode: favoriteActionFocusNode,
                    isFavorite: false,
                    size: 44,
                    iconSize: 28,
                    focusPadding: const EdgeInsets.all(5),
                    focusedBackgroundColor: iconActionFocusedBackground,
                    focusedBorderColor: Theme.of(context).colorScheme.primary,
                    borderWidth: 2,
                    onPressed: () {},
                  ),
                ),
              ),
              error: (_, __) => MoviEnsureVisibleOnFocus(
                verticalAlignment: _heroFocusVerticalAlignment,
                child: Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, event) =>
                      onFavoriteActionKeyEvent?.call(event) ??
                      KeyEventResult.ignored,
                  child: MoviFavoriteButton(
                    focusNode: favoriteActionFocusNode,
                    isFavorite: false,
                    size: 44,
                    iconSize: 28,
                    focusPadding: const EdgeInsets.all(5),
                    focusedBackgroundColor: iconActionFocusedBackground,
                    focusedBorderColor: Theme.of(context).colorScheme.primary,
                    borderWidth: 2,
                    onPressed: () {},
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
