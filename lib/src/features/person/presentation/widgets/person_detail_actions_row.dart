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
  });

  final String personId;
  final List<MoviMedia> movies;
  final List<MoviMedia> shows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: MoviPrimaryButton(
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
        const SizedBox(width: 16),
        Consumer(
          builder: (context, ref, _) {
            final isFavoriteAsync = ref.watch(
              personIsFavoriteProvider(personId),
            );
            return isFavoriteAsync.when(
              data: (isFavorite) => MoviFavoriteButton(
                isFavorite: isFavorite,
                onPressed: () async {
                  await ref
                      .read(personToggleFavoriteProvider.notifier)
                      .toggle(personId);
                },
              ),
              loading: () =>
                  MoviFavoriteButton(isFavorite: false, onPressed: () {}),
              error: (_, __) =>
                  MoviFavoriteButton(isFavorite: false, onPressed: () {}),
            );
          },
        ),
      ],
    );
  }
}
