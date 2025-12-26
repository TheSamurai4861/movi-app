import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/config/providers/config_provider.dart';
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/syncable_refresh_indicator.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/home/presentation/widgets/home_error_banner.dart';
import 'package:movi/src/features/home/presentation/widgets/home_hero_section.dart';
import 'package:movi/src/features/home/presentation/widgets/home_continue_watching_section.dart';
import 'package:movi/src/features/home/presentation/widgets/home_iptv_section.dart';
import 'package:movi/src/features/home/presentation/widgets/home_loading_overlay.dart';
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
import 'package:movi/src/features/home/presentation/widgets/mark_as_unwatched_dialog.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Layout desktop pour la page d'accueil.
///
/// Utilise une navigation rail (sidebar) et un layout adapté aux grands écrans.
class HomeDesktopLayout extends ConsumerWidget {
  const HomeDesktopLayout({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
    required this.pages,
  });

  final int selectedIndex;
  final ValueChanged<int> onNavTap;
  final List<Widget> pages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onNavTap,
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: Image.asset(
                  AppAssets.navHome,
                  width: 24,
                  height: 24,
                ),
                selectedIcon: Image.asset(
                  AppAssets.navHome,
                  width: 24,
                  height: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(AppLocalizations.of(context)!.navHome),
              ),
              NavigationRailDestination(
                icon: Image.asset(
                  AppAssets.navSearch,
                  width: 24,
                  height: 24,
                ),
                selectedIcon: Image.asset(
                  AppAssets.navSearch,
                  width: 24,
                  height: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(AppLocalizations.of(context)!.navSearch),
              ),
              NavigationRailDestination(
                icon: Image.asset(
                  AppAssets.navLibrary,
                  width: 24,
                  height: 24,
                ),
                selectedIcon: Image.asset(
                  AppAssets.navLibrary,
                  width: 24,
                  height: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(AppLocalizations.of(context)!.navLibrary),
              ),
              NavigationRailDestination(
                icon: Image.asset(
                  AppAssets.navSettings,
                  width: 24,
                  height: 24,
                ),
                selectedIcon: Image.asset(
                  AppAssets.navSettings,
                  width: 24,
                  height: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(AppLocalizations.of(context)!.navSettings),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(index: selectedIndex, children: pages),
          ),
        ],
      ),
    );
  }
}

/// Contenu desktop pour la page d'accueil.
///
/// Layout optimisé pour les grands écrans avec plus d'espace et une meilleure organisation.
class HomeDesktopContent extends ConsumerStatefulWidget {
  const HomeDesktopContent({super.key});

  @override
  ConsumerState<HomeDesktopContent> createState() => _HomeDesktopContentState();
}

class _HomeDesktopContentState extends ConsumerState<HomeDesktopContent> {
  bool _isHeroLoadingMeta = false;
  bool _hasAutoRefreshed = false;

  bool _isScheduled = false;
  void _postFrame(VoidCallback fn) {
    if (_isScheduled) return;
    _isScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fn();
      _isScheduled = false;
    });
  }

  Future<void> _precacheImageUrl(String url) async {
    if (url.isEmpty) return;
    try {
      await precacheImage(NetworkImage(url), context);
    } catch (_) {
      // ignore erreurs réseau; l'overlay ne doit pas bloquer
    }
  }

  @override
  void initState() {
    super.initState();
    // Déclencher automatiquement le refresh après le premier frame si les données sont vides
    // Simule un pull-to-refresh complet (sync + refresh home)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(hp.homeControllerProvider);
      final disableHero = ref.read(
        featureFlagsProvider.select((f) => f.home.disableHero),
      );
      
      if (!state.isLoading) {
        final isEmpty = (!disableHero && state.hero.isEmpty) || state.iptvLists.isEmpty;
        if (isEmpty && !_hasAutoRefreshed) {
          _hasAutoRefreshed = true;
          // Simuler exactement le comportement du pull-to-refresh
          unawaited(_simulatePullToRefresh(ref));
        }
      }
    });
  }

  /// Simule un pull-to-refresh complet comme dans SyncableRefreshIndicator
  Future<void> _simulatePullToRefresh(WidgetRef ref) async {
    try {
      // 1. Déclencher la synchronisation complète avec 'manual' pour forcer le refresh IPTV
      final syncController = ref.read(libraryCloudSyncControllerProvider.notifier);
      await syncController.syncNow(reason: 'manual');
      
      // 2. Rafraîchir le home (comme dans le callback onRefresh du SyncableRefreshIndicator)
      final controller = ref.read(hp.homeControllerProvider.notifier);
      await Future.wait([
        controller.refresh(),
        ref.refresh(hp.homeInProgressProvider.future),
      ]);
    } catch (_) {
      // Ignorer les erreurs silencieusement
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hp.homeControllerProvider);
    final controller = ref.read(hp.homeControllerProvider.notifier);
    final iptvFilter = ref.watch(hp.homeIptvMediaFilterProvider);
    final disableHero = ref.watch(
      featureFlagsProvider.select((f) => f.home.disableHero),
    );

    // Précache héro pour accélérer les réaffichages
    _postFrame(() {
      if (!disableHero && state.hero.isNotEmpty) {
        var heroUrl = (state.hero.first.poster?.toString() ?? '');
        if (heroUrl == 'null') heroUrl = '';
        if (heroUrl.isNotEmpty) {
          unawaited(_precacheImageUrl(heroUrl));
        }
      }
    });

    final showLoadingOverlay =
        (state.isLoading && (disableHero ? state.iptvLists.isEmpty : state.hero.isEmpty)) ||
        (!disableHero && _isHeroLoadingMeta);

    final iptvEntries = state.iptvLists.entries
        .where((entry) => _matchesIptvFilter(entry.value, iptvFilter))
        .toList(growable: false);

    return Stack(
      children: [
        SyncableRefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              controller.refresh(),
              ref.refresh(hp.homeInProgressProvider.future),
            ]);
          },
          child: CustomScrollView(
            slivers: [
              if (state.error != null)
                const SliverToBoxAdapter(child: HomeErrorBanner()),

              if (!disableHero) ...[
                HomeHeroSection(
                  heroItems: state.hero,
                  onLoadingChanged: (isLoading) {
                    if (mounted && _isHeroLoadingMeta != isLoading) {
                      setState(() {
                        _isHeroLoadingMeta = isLoading;
                      });
                    }
                  },
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: HomeLayoutConstants.sectionGap),
                ),
              ],

              HomeContinueWatchingSection(
                onMarkAsUnwatched: showMarkAsUnwatchedDialog,
              ),

              const HomeContinueWatchingSpacer(),

              if (state.isLoading && state.iptvLists.isEmpty)
                SliverToBoxAdapter(child: const HomeIptvLoadingSections())
              else if (state.iptvLists.isEmpty)
                const SliverToBoxAdapter(child: HomeNoIptvSourcesMessage())
              else ...[
                for (final entry in iptvEntries) ...[
                  SliverToBoxAdapter(
                    child: HomeIptvSection(
                      categoryTitle: entry.key,
                      items: entry.value,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: HomeLayoutConstants.sectionGap),
                  ),
                ],
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        HomeLoadingOverlay(show: showLoadingOverlay),
      ],
    );
  }
}

bool _matchesIptvFilter(
  List<ContentReference> items,
  hp.HomeIptvMediaFilter filter,
) {
  if (filter == hp.HomeIptvMediaFilter.all) return true;
  if (items.isEmpty) return false;

  final type = items.first.type;
  if (filter == hp.HomeIptvMediaFilter.movies) return type == ContentType.movie;
  if (filter == hp.HomeIptvMediaFilter.series) return type == ContentType.series;
  return false;
}

