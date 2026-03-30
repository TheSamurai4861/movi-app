import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/config/providers/config_provider.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_bottom_nav_bar.dart';
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

/// Layout mobile pour la page d'accueil.
///
/// Utilise une bottom navigation bar et un layout vertical avec scroll.
class HomeMobileLayout extends ConsumerWidget {
  const HomeMobileLayout({
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
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(index: selectedIndex, children: pages),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: moviNavBarBottomOffset(context),
              child: MoviBottomNavBar(
                selectedIndex: selectedIndex,
                navItems: [
                  MoviBottomNavItem(
                    label: AppLocalizations.of(context)!.navHome,
                    icon: AppAssets.navHome,
                  ),
                  MoviBottomNavItem(
                    label: AppLocalizations.of(context)!.navSearch,
                    icon: AppAssets.navSearch,
                  ),
                  MoviBottomNavItem(
                    label: AppLocalizations.of(context)!.navLibrary,
                    icon: AppAssets.navLibrary,
                  ),
                  MoviBottomNavItem(
                    label: AppLocalizations.of(context)!.navSettings,
                    icon: AppAssets.navSettings,
                  ),
                ],
                onItemSelected: onNavTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenu mobile pour la page d'accueil.
class HomeMobileContent extends ConsumerStatefulWidget {
  const HomeMobileContent({super.key});

  @override
  ConsumerState<HomeMobileContent> createState() => _HomeMobileContentState();
}

class _HomeMobileContentState extends ConsumerState<HomeMobileContent> {
  bool _isHeroLoadingMeta = false;
  bool _hasAutoRefreshed = false;
  bool get _allowLegacyHeroOverlayPrecache =>
      defaultTargetPlatform != TargetPlatform.windows;
  String? _lastLoggedHeroBuildSignature;
  String? _lastLoggedHeroOverlayUrl;

  bool _isScheduled = false;
  void _logHomeHeroDebug(
    String event, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    final message = <String>[
      '[HomeHeroDebug]',
      'surface=mobile_layout',
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
  void initState() {
    super.initState();
    _logHomeHeroDebug('init_state');
    // Déclencher automatiquement le refresh après le premier frame si les données sont vides
    // Simule un pull-to-refresh complet (sync + refresh home)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(hp.homeControllerProvider);
      final disableHero = ref.read(
        featureFlagsProvider.select((f) => f.home.disableHero),
      );

      if (!state.isLoading) {
        final isEmpty =
            (!disableHero && state.hero.isEmpty) || state.iptvLists.isEmpty;
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
    final state = ref.watch(hp.homeControllerProvider);
    final controller = ref.read(hp.homeControllerProvider.notifier);
    final iptvFilter = ref.watch(hp.homeIptvMediaFilterProvider);
    final disableHero = ref.watch(
      featureFlagsProvider.select((f) => f.home.disableHero),
    );
    final buildSignature = [
      state.hero.length,
      state.iptvLists.length,
      state.isLoading,
      disableHero,
      _isHeroLoadingMeta,
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
  if (filter == hp.HomeIptvMediaFilter.series)
    return type == ContentType.series;
  return false;
}
