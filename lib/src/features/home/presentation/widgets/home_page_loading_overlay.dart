import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/config/providers/config_provider.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/home/presentation/widgets/home_loading_overlay.dart';

/// Overlay de chargement Home isolé : seul ce widget rebuild quand le hero meta charge.
class HomePageLoadingOverlay extends ConsumerWidget {
  const HomePageLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hp.homeControllerProvider);
    final disableHero = ref.watch(
      featureFlagsProvider.select((flags) => flags.home.disableHero),
    );
    final heroMetaLoading = ref.watch(hp.homeHeroMetaLoadingProvider);

    final showFeedLoading =
        state.isLoading &&
        (disableHero ? state.iptvLists.isEmpty : state.hero.isEmpty);
    final show = showFeedLoading || (!disableHero && heroMetaLoading);

    return HomeLoadingOverlay(show: show);
  }
}
