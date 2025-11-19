// lib/src/features/home/presentation/pages/home_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/widgets/movi_bottom_nav_bar.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/search/presentation/pages/search_page.dart';
import 'package:movi/src/features/library/presentation/pages/library_page.dart';
import 'package:movi/src/features/settings/presentation/pages/settings_page.dart';
import 'package:movi/src/features/home/presentation/widgets/home_error_banner.dart';
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
import 'package:movi/src/features/home/presentation/widgets/home_hero_section.dart';
import 'package:movi/src/features/home/presentation/widgets/home_continue_watching_section.dart';
import 'package:movi/src/features/home/presentation/widgets/home_iptv_section.dart';
import 'package:movi/src/features/home/presentation/widgets/home_loading_overlay.dart';
import 'package:movi/src/features/home/presentation/widgets/mark_as_unwatched_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _navBottomOffset = 0;

  int _selectedIndex = 0;
  final PageStorageBucket _bucket = PageStorageBucket();

  void _handleNavTap(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final navIndex = ref.watch(hp.homeNavIndexProvider);
    if (_selectedIndex != navIndex) _selectedIndex = navIndex;

    final pages = <Widget>[
      _HomeContent(key: const PageStorageKey('tab-home')),
      const SearchPage(),
      const LibraryPage(key: PageStorageKey('tab-library')),
      const SettingsPage(key: PageStorageKey('tab-settings')),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            PageStorage(
              bucket: _bucket,
              child: IndexedStack(index: _selectedIndex, children: pages),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: _navBottomOffset + media.padding.bottom,
              child: MoviBottomNavBar(
                selectedIndex: _selectedIndex,
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
                onItemSelected: (i) {
                  _handleNavTap(i);
                  ref.read(hp.homeNavIndexProvider.notifier).set(i);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent({super.key});

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

/// Gère le contenu Home avec overlay de démarrage.
class _HomeContentState extends ConsumerState<_HomeContent> {
  bool _isHeroLoadingMeta = false;

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
  Widget build(BuildContext context) {
    final state = ref.watch(hp.homeControllerProvider);
    final controller = ref.read(hp.homeControllerProvider.notifier);

    // Précache héro pour accélérer les réaffichages
    _postFrame(() {
      if (state.hero.isNotEmpty) {
        var heroUrl = ((state.hero.first.backdrop) ?? (state.hero.first.poster))
            .toString();
        if (heroUrl == 'null') heroUrl = '';
        if (heroUrl.isNotEmpty) {
          unawaited(_precacheImageUrl(heroUrl));
        }
      }
    });

    final showLoadingOverlay =
        (state.isLoading && state.hero.isEmpty) || _isHeroLoadingMeta;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await controller.refresh();
          },
          child: CustomScrollView(
            slivers: [
              if (state.error != null)
                const SliverToBoxAdapter(child: HomeErrorBanner()),

              HomeHeroSection(
                heroMovies: state.hero,
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

              HomeContinueWatchingSection(
                onMarkAsUnwatched: showMarkAsUnwatchedDialog,
              ),

              const HomeContinueWatchingSpacer(),

              if (state.isLoading && state.iptvLists.isEmpty)
                SliverToBoxAdapter(child: const HomeIptvLoadingSections())
              else if (state.iptvLists.isEmpty)
                const SliverToBoxAdapter(child: HomeNoIptvSourcesMessage()),

              for (final entry in state.iptvLists.entries) ...[
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

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        HomeLoadingOverlay(show: showLoadingOverlay),
      ],
    );
  }
}
