import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_favorite_button.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Bouton favori du hero : seul ce widget écoute les providers favoris.
class HomeHeroFavoriteButton extends ConsumerWidget {
  const HomeHeroFavoriteButton({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.iconActionFocusedBackground,
  });

  final String contentId;
  final ContentType contentType;
  final Color iconActionFocusedBackground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = contentId.trim();
    if (id.isEmpty) {
      return _HomeHeroFavoritePlaceholder(
        iconActionFocusedBackground: iconActionFocusedBackground,
      );
    }

    if (contentType == ContentType.series) {
      final isFavoriteAsync = ref.watch(tvIsFavoriteProvider(id));
      return isFavoriteAsync.when(
        data: (isFavorite) => _HomeHeroFavoriteResolved(
          iconActionFocusedBackground: iconActionFocusedBackground,
          isFavorite: isFavorite,
          onPressed: () async {
            await ref.read(tvToggleFavoriteProvider.notifier).toggle(id);
          },
        ),
        loading: () => _HomeHeroFavoritePlaceholder(
          iconActionFocusedBackground: iconActionFocusedBackground,
        ),
        error: (_, __) => _HomeHeroFavoritePlaceholder(
          iconActionFocusedBackground: iconActionFocusedBackground,
        ),
      );
    }

    final isFavoriteAsync = ref.watch(movieIsFavoriteProvider(id));
    return isFavoriteAsync.when(
      data: (isFavorite) => _HomeHeroFavoriteResolved(
        iconActionFocusedBackground: iconActionFocusedBackground,
        isFavorite: isFavorite,
        onPressed: () async {
          await ref.read(movieToggleFavoriteProvider.notifier).toggle(id);
        },
      ),
      loading: () => _HomeHeroFavoritePlaceholder(
        iconActionFocusedBackground: iconActionFocusedBackground,
      ),
      error: (_, __) => _HomeHeroFavoritePlaceholder(
        iconActionFocusedBackground: iconActionFocusedBackground,
      ),
    );
  }
}

class _HomeHeroFavoriteResolved extends StatelessWidget {
  const _HomeHeroFavoriteResolved({
    required this.iconActionFocusedBackground,
    required this.isFavorite,
    required this.onPressed,
  });

  final Color iconActionFocusedBackground;
  final bool isFavorite;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return MoviFavoriteButton(
      isFavorite: isFavorite,
      size: 44,
      iconSize: 28,
      focusPadding: const EdgeInsets.all(5),
      focusedBackgroundColor: iconActionFocusedBackground,
      focusedBorderColor: Theme.of(context).colorScheme.primary,
      borderWidth: 2,
      onPressed: () => unawaited(onPressed()),
    );
  }
}

class _HomeHeroFavoritePlaceholder extends StatelessWidget {
  const _HomeHeroFavoritePlaceholder({
    required this.iconActionFocusedBackground,
  });

  final Color iconActionFocusedBackground;

  @override
  Widget build(BuildContext context) {
    return MoviFavoriteButton(
      isFavorite: false,
      size: 44,
      iconSize: 28,
      focusPadding: const EdgeInsets.all(5),
      focusedBackgroundColor: iconActionFocusedBackground,
      focusedBorderColor: Theme.of(context).colorScheme.primary,
      borderWidth: 2,
      onPressed: () {},
    );
  }
}
