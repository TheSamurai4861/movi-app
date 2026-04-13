import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/config/providers/config_provider.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
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
    final navIconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final navSelectedColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onNavTap,
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: MoviAssetIcon(
                  AppAssets.navHome,
                  width: 24,
                  height: 24,
                  color: navIconColor,
                ),
                selectedIcon: MoviAssetIcon(
                  AppAssets.navHome,
                  width: 24,
                  height: 24,
                  color: navSelectedColor,
                ),
                label: Text(AppLocalizations.of(context)!.navHome),
              ),
              NavigationRailDestination(
                icon: MoviAssetIcon(
                  AppAssets.navSearch,
                  width: 24,
                  height: 24,
                  color: navIconColor,
                ),
                selectedIcon: MoviAssetIcon(
                  AppAssets.navSearch,
                  width: 24,
                  height: 24,
                  color: navSelectedColor,
                ),
                label: Text(AppLocalizations.of(context)!.navSearch),
              ),
              NavigationRailDestination(
                icon: MoviAssetIcon(
                  AppAssets.navLibrary,
                  width: 24,
                  height: 24,
                  color: navIconColor,
                ),
                selectedIcon: MoviAssetIcon(
                  AppAssets.navLibrary,
                  width: 24,
                  height: 24,
                  color: navSelectedColor,
                ),
                label: Text(AppLocalizations.of(context)!.navLibrary),
              ),
              NavigationRailDestination(
                icon: MoviAssetIcon(
                  AppAssets.navSettings,
                  width: 24,
                  height: 24,
                  color: navIconColor,
                ),
                selectedIcon: MoviAssetIcon(
                  AppAssets.navSettings,
                  width: 24,
                  height: 24,
                  color: navSelectedColor,
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

class _HomeDesktopContentState extends ConsumerState<HomeDesktopContent>
    with AutomaticKeepAliveClientMixin<HomeDesktopContent> {
  static bool _sessionAutoRefreshDone = false;
  static bool _sessionInitialHeroFocusDone = false;
  static const PageStorageKey<String> _scrollStorageKey =
      PageStorageKey<String>('home-desktop-scroll');

  bool _isHeroLoadingMeta = false;
  bool _hasAutoRefreshed = false;
  final FocusNode _heroPrimaryActionFocusNode = FocusNode(
    debugLabel: 'HomeHeroPrimaryAction',
  );
  final FocusNode _heroMoviesFilterFocusNode = FocusNode(
    debugLabel: 'HomeHeroMoviesFilter',
  );
  bool get _allowLegacyHeroOverlayPrecache =>
      defaultTargetPlatform != TargetPlatform.windows;
  String? _lastLoggedHeroBuildSignature;
  String? _lastLoggedHeroOverlayUrl;
  late final VoidCallback _heroPrimaryActionFocusListener =
      _onHeroPrimaryActionFocusChanged;

  bool _isScheduled = false;
  void _logHomeHeroDebug(
    String event, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    final message = <String>[
      '[HomeHeroDebug]',
      'surface=desktop_layout',
      'event=$event',
      'platform=${defaultTargetPlatform.name}',
      for (final entry in context.entries)
        if (entry.value != null) '${entry.key}=${entry.value}',
    ].join(' ');
    unawaited(LoggingService.log(message, category: 'home_hero_debug'));
  }

  void _postFrame(VoidCallback fn) {
    if (_isScheduled) return;
    _isScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fn();
      _isScheduled = false;
    });
  }

  Future<void> _precacheImageUrl(String url) async {
    if (!_allowLegacyHeroOverlayPrecache || url.isEmpty) {
      _logHomeHeroDebug(
        'legacy_precache_skipped',
        context: <String, Object?>{
          'allowLegacyPrecache': _allowLegacyHeroOverlayPrecache,
          'urlEmpty': url.isEmpty,
        },
      );
      return;
    }
    _logHomeHeroDebug(
      'legacy_precache_start',
      context: <String, Object?>{'url': url},
    );
    try {
      await precacheImage(NetworkImage(url), context);
      _logHomeHeroDebug(
        'legacy_precache_done',
        context: <String, Object?>{'url': url},
      );
    } catch (_) {
      _logHomeHeroDebug(
        'legacy_precache_error',
        context: <String, Object?>{'url': url},
      );
      // ignore erreurs réseau; l'overlay ne doit pas bloquer
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _logHomeHeroDebug('init_state');
    _heroPrimaryActionFocusNode.addListener(_heroPrimaryActionFocusListener);
    if (!_sessionInitialHeroFocusDone) {
      _sessionInitialHeroFocusDone = true;
      _requestInitialHeroFocus();
    }
    // Déclencher automatiquement le refresh après le premier frame si les données sont vides
    // Simule un pull-to-refresh complet (sync + refresh home)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasAutoRefreshed || _sessionAutoRefreshDone) return;
      final state = ref.read(hp.homeControllerProvider);
      final disableHero = ref.read(
        featureFlagsProvider.select((f) => f.home.disableHero),
      );

      if (!state.isLoading) {
        final isEmpty =
            (!disableHero && state.hero.isEmpty) || state.iptvLists.isEmpty;
        if (isEmpty && !_hasAutoRefreshed) {
          _hasAutoRefreshed = true;
          _sessionAutoRefreshDone = true;
          // Simuler exactement le comportement du pull-to-refresh
          unawaited(_simulatePullToRefresh(ref));
        }
      }
    });
  }

  void _requestInitialHeroFocus([int attempts = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_heroPrimaryActionFocusNode.context != null) {
        _heroPrimaryActionFocusNode.requestFocus();
        return;
      }
      if (attempts < 10) {
        _requestInitialHeroFocus(attempts + 1);
      }
    });
  }

  void _onHeroPrimaryActionFocusChanged() {
    if (!mounted || !_heroPrimaryActionFocusNode.hasFocus) {
      return;
    }
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null ||
        !controller.hasClients ||
        controller.offset <= 0) {
      return;
    }
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _heroPrimaryActionFocusNode.removeListener(_heroPrimaryActionFocusListener);
    _heroPrimaryActionFocusNode.dispose();
    _heroMoviesFilterFocusNode.dispose();
    super.dispose();
  }

  /// Simule un pull-to-refresh complet comme dans SyncableRefreshIndicator
  Future<void> _simulatePullToRefresh(WidgetRef ref) async {
    try {
      // 1. Déclencher la synchronisation complète avec 'manual' pour forcer le refresh IPTV
      final syncController = ref.read(
        libraryCloudSyncControllerProvider.notifier,
      );
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
    super.build(context);
    final state = ref.watch(hp.homeControllerProvider);
    final controller = ref.read(hp.homeControllerProvider.notifier);
    final iptvFilter = ref.watch(hp.homeIptvMediaFilterProvider);
    final inProgressAsync = ref.watch(hp.homeInProgressProvider);
    final disableHero = ref.watch(
      featureFlagsProvider.select((f) => f.home.disableHero),
    );
    final bool firstSectionNeedsHeroTransition =
        !disableHero &&
        inProgressAsync.maybeWhen(
          data: (inProgress) => inProgress.isEmpty,
          orElse: () => true,
        );
    final buildSignature = [
      state.hero.length,
      state.iptvLists.length,
      state.isLoading,
      disableHero,
      _isHeroLoadingMeta,
      firstSectionNeedsHeroTransition,
    ].join('|');
    if (_lastLoggedHeroBuildSignature != buildSignature) {
      _lastLoggedHeroBuildSignature = buildSignature;
      _logHomeHeroDebug(
        'build_state',
        context: <String, Object?>{
          'heroCount': state.hero.length,
          'iptvSections': state.iptvLists.length,
          'isLoading': state.isLoading,
          'disableHero': disableHero,
          'heroMetaLoading': _isHeroLoadingMeta,
          'firstSectionNeedsHeroTransition': firstSectionNeedsHeroTransition,
        },
      );
    }

    // Précache héro pour accélérer les réaffichages
    _postFrame(() {
      if (_allowLegacyHeroOverlayPrecache &&
          !disableHero &&
          state.hero.isNotEmpty) {
        var heroUrl = (state.hero.first.poster?.toString() ?? '');
        if (heroUrl == 'null') heroUrl = '';
        if (_lastLoggedHeroOverlayUrl != heroUrl) {
          _lastLoggedHeroOverlayUrl = heroUrl;
          _logHomeHeroDebug(
            'legacy_precache_candidate',
            context: <String, Object?>{
              'heroUrl': heroUrl,
              'heroId': state.hero.first.id,
              'heroType': state.hero.first.type.name,
            },
          );
        }
        if (heroUrl.isNotEmpty) {
          unawaited(_precacheImageUrl(heroUrl));
        }
      }
    });

    final showLoadingOverlay =
        (state.isLoading &&
            (disableHero ? state.iptvLists.isEmpty : state.hero.isEmpty)) ||
        (!disableHero && _isHeroLoadingMeta);

    final iptvEntries = state.iptvLists.entries
        .where((entry) => _matchesIptvFilter(entry.value, iptvFilter))
        .toList(growable: false);

    return FocusRegionScope(
      regionId: AppFocusRegionId.homePrimary,
      binding: FocusRegionBinding(
        resolvePrimaryEntryNode: () => _heroPrimaryActionFocusNode,
        resolveFallbackEntryNode: () => _heroMoviesFilterFocusNode,
      ),
      exitMap: FocusRegionExitMap({
        DirectionalEdge.left: AppFocusRegionId.shellSidebar,
        DirectionalEdge.back: AppFocusRegionId.shellSidebar,
      }),
      debugLabel: 'HomePrimaryRegion',
      child: Stack(
        children: [
          SyncableRefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                controller.refresh(),
                ref.refresh(hp.homeInProgressProvider.future),
              ]);
            },
            child: CustomScrollView(
              key: _scrollStorageKey,
              slivers: [
                if (state.error != null)
                  const SliverToBoxAdapter(child: HomeErrorBanner()),

                if (!disableHero) ...[
                  HomeHeroSection(
                    heroItems: state.hero,
                    primaryActionFocusNode: _heroPrimaryActionFocusNode,
                    moviesFilterFocusNode: _heroMoviesFilterFocusNode,
                    onLoadingChanged: (isLoading) {
                      if (mounted && _isHeroLoadingMeta != isLoading) {
                        _logHomeHeroDebug(
                          'hero_loading_changed',
                          context: <String, Object?>{'isLoading': isLoading},
                        );
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
                  applyHeroTransition:
                      !disableHero && !firstSectionNeedsHeroTransition,
                ),

                const HomeContinueWatchingSpacer(),

                if (state.isLoading && state.iptvLists.isEmpty)
                  SliverToBoxAdapter(
                    child: HomeIptvLoadingSections(
                      applyHeroTransition: firstSectionNeedsHeroTransition,
                    ),
                  )
                else if (state.iptvLists.isEmpty)
                  SliverToBoxAdapter(
                    child: HomeNoIptvSourcesMessage(
                      applyHeroTransition: firstSectionNeedsHeroTransition,
                    ),
                  )
                else ...[
                  for (var i = 0; i < iptvEntries.length; i++) ...[
                    SliverToBoxAdapter(
                      child: HomeIptvSection(
                        categoryTitle: iptvEntries[i].key,
                        items: iptvEntries[i].value,
                        applyHeroTransition:
                            firstSectionNeedsHeroTransition && i == 0,
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
      ),
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
  if (filter == hp.HomeIptvMediaFilter.series) {
    return type == ContentType.series;
  }
  return false;
}
