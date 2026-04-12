// lib/src/features/shell/presentation/pages/app_shell_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Shell
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/startup/presentation/widgets/launch_recovery_banner.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_scroll_to_top_controller.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_shortcuts.dart';
import 'package:movi/src/features/shell/presentation/providers/shell_providers.dart';
import 'package:movi/src/features/shell/presentation/layouts/app_shell_large_layout.dart';
import 'package:movi/src/features/shell/presentation/layouts/app_shell_mobile_layout.dart';
import 'package:movi/src/features/shell/presentation/layouts/app_shell_tv_layout.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

// Pages (adapte les imports si tes features ont des chemins différents)
import 'package:movi/src/features/home/presentation/pages/home_page.dart';
import 'package:movi/src/features/search/presentation/pages/search_page.dart';
import 'package:movi/src/features/library/presentation/pages/library_page.dart';
import 'package:movi/src/features/settings/presentation/pages/settings_page.dart';

/// Page d'entrée du Shell : choisit le layout (mobile / large / TV),
/// branche le controller, les shortcuts, les destinations (SVG + tooltips l10n)
/// et applique la policy de rétention.
///
/// Choix validés :
/// - Breakpoint large : recommandé (900px)
/// - TV mode : recommandé (override flag + fallback platform)
/// - Type : recommandé (Stateful) pour porter un FocusNode partagé (sidebar + shortcuts)
/// - Logo : recommandé (fourni par la page -> passé au layout)
/// - Pages : recommandé (imports directs)
/// - Loading label : null (pas de texte brut)
/// - Mobile layout : oui (tu l'as déjà, on l'utilise)
class AppShellPage extends ConsumerStatefulWidget {
  const AppShellPage({
    super.key,
    this.largeBreakpoint = 900,
    this.forceTvMode,
    this.sidebarLogo,
  });

  /// Large breakpoint (px) : < => mobile, >= => large/TV.
  final double largeBreakpoint;

  /// Override TV mode (flag).
  ///
  /// - true  => force TV layout
  /// - false => force non-TV layout
  /// - null  => fallback heuristique (platform)
  final bool? forceTvMode;

  /// Logo optionnel affiché en haut de la sidebar.
  final Widget? sidebarLogo;

  @override
  ConsumerState<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends ConsumerState<AppShellPage> {
  late final FocusNode _sidebarFocusNode = FocusNode(
    debugLabel: 'ShellSidebarScope',
  );
  late final ShellFocusCoordinator _shellFocusCoordinator;
  late final ShellScrollToTopController _scrollToTopController =
      ShellScrollToTopController();

  @override
  void initState() {
    super.initState();
    _shellFocusCoordinator = ref.read(shellFocusCoordinatorProvider);
    _shellFocusCoordinator.attachSidebar(_sidebarFocusNode);
  }

  @override
  void dispose() {
    _shellFocusCoordinator.detachSidebar(_sidebarFocusNode);
    _sidebarFocusNode.dispose();
    _scrollToTopController.dispose();
    super.dispose();
  }

  ScreenType _resolveScreenType(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final detected = ScreenTypeResolver.instance.resolve(
      size.width,
      size.height,
    );
    final override = widget.forceTvMode;
    if (override == true) return ScreenType.tv;
    if (override == false && detected == ScreenType.tv) {
      return ScreenType.desktop;
    }
    return detected;
  }

  List<WidgetBuilder> _buildPageBuilders() {
    // Ordre doit correspondre à shellDestinations (ShellTab.values).
    return const <WidgetBuilder>[
      _homeBuilder,
      _searchBuilder,
      _libraryBuilder,
      _settingsBuilder,
    ];
  }

  static Widget _homeBuilder(BuildContext _) => const HomePage();
  static Widget _searchBuilder(BuildContext _) => const SearchPage();
  static Widget _libraryBuilder(BuildContext _) => const LibraryPage();
  static Widget _settingsBuilder(BuildContext _) => const SettingsPage();

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) return false;
    return ctx.findAncestorStateOfType<EditableTextState>() != null;
  }

  void _focusPrimaryEntryWithRetry(
    ShellFocusCoordinator coordinator,
    ShellTab tab, {
    int attempts = 0,
  }) {
    if (!mounted) return;
    final focused = coordinator.focusTabPrimaryEntry(tab);
    if (focused || attempts >= 8) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusPrimaryEntryWithRetry(coordinator, tab, attempts: attempts + 1);
    });
  }

  void _focusTabEntryWithRetry(
    ShellFocusCoordinator coordinator,
    ShellTab tab, {
    int attempts = 0,
  }) {
    if (!mounted) return;
    final focused = coordinator.focusTabEntry(tab);
    if (focused || attempts >= 8) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusTabEntryWithRetry(coordinator, tab, attempts: attempts + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final launchRecovery = ref.watch(appLaunchStateProvider).recovery;

    final keepAliveIndices = ref.watch(keepAliveIndicesProvider);
    final sidebarDestinations = buildSidebarDestinations(context);
    final pageBuilders = _buildPageBuilders();

    final screenType = _resolveScreenType(context);
    final isLarge = screenType != ScreenType.mobile;
    final isTv = screenType == ScreenType.tv;
    final selectedTab = shellTabFromIndex(selectedIndex);
    final focusCoordinator = ref.read(shellFocusCoordinatorProvider);
    void handleSidebarFocusedIndexChanged(int index) {
      focusCoordinator.setSidebarFocusedIndex(index);
    }

    void handleNavTap(int index) {
      final targetTab = shellTabFromIndex(index);
      if (index == selectedIndex) {
        // Re-tap onglet actif => remonter en haut.
        // (Si la page n'a pas de scroll primaire, c'est un no-op.)
        _scrollToTopController.scrollToTop(index);
        focusCoordinator.focusTabEntry(targetTab);
        return;
      }
      shellSelectIndex(ref, index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        focusCoordinator.focusTabEntry(targetTab);
      });
    }

    // Wrap global shortcuts (Ctrl+1..4 + Escape + Up/Down pour sidebar quand focus).
    // Pas de texte brut : pas de loadingLabel ici.
    final shellBody = Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (_isTextInputFocused()) return KeyEventResult.ignored;

        if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
            focusCoordinator.isSidebarFocused) {
          final targetIndex =
              focusCoordinator.sidebarFocusedIndex ?? selectedIndex;
          final targetTab = shellTabFromIndex(targetIndex);
          final preferPrimaryEntry = targetTab == ShellTab.library;
          if (targetIndex != selectedIndex) {
            shellSelectIndex(ref, targetIndex);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (preferPrimaryEntry) {
                _focusPrimaryEntryWithRetry(focusCoordinator, targetTab);
              } else {
                _focusTabEntryWithRetry(focusCoordinator, targetTab);
              }
            });
            return KeyEventResult.handled;
          }
          final focused = preferPrimaryEntry
              ? focusCoordinator.focusTabPrimaryEntry(targetTab)
              : focusCoordinator.focusTabEntry(targetTab);
          if (!focused) {
            if (preferPrimaryEntry) {
              _focusPrimaryEntryWithRetry(focusCoordinator, targetTab);
            } else {
              _focusTabEntryWithRetry(focusCoordinator, targetTab);
            }
          }
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
            !focusCoordinator.isSidebarFocused) {
          final focusedNode = FocusManager.instance.primaryFocus;
          if (focusedNode == null) return KeyEventResult.ignored;
          final moved = focusedNode.focusInDirection(TraversalDirection.left);
          if (moved) return KeyEventResult.handled;
          focusCoordinator.resolveTabExit(selectedTab, DirectionalEdge.left);
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.backspace &&
            (selectedTab == ShellTab.home ||
                selectedTab == ShellTab.search ||
                selectedTab == ShellTab.library) &&
            !focusCoordinator.isSidebarFocused) {
          final focusedNode = FocusManager.instance.primaryFocus;
          if (focusedNode == null) return KeyEventResult.ignored;
          focusCoordinator.resolveTabExit(selectedTab, DirectionalEdge.back);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: ShellShortcuts(
        onSelectTab: (tab) => shellSelectTab(ref, tab),
        child: isLarge
            ? (isTv
                  ? AppShellTvLayout(
                      selectedIndex: selectedIndex,
                      onNavTap: handleNavTap,
                      destinations: sidebarDestinations,
                      pageBuilders: pageBuilders,
                      keepAliveIndices: keepAliveIndices,
                      sidebarFocusNode: _sidebarFocusNode,
                      scrollControllerForIndex:
                          _scrollToTopController.controllerForIndex,
                      sidebarLogo: widget.sidebarLogo,
                      onSidebarFocusedIndexChanged:
                          handleSidebarFocusedIndexChanged,
                    )
                  : AppShellLargeLayout(
                      selectedIndex: selectedIndex,
                      onNavTap: handleNavTap,
                      destinations: sidebarDestinations,
                      pageBuilders: pageBuilders,
                      keepAliveIndices: keepAliveIndices,
                      sidebarFocusNode: _sidebarFocusNode,
                      scrollControllerForIndex:
                          _scrollToTopController.controllerForIndex,
                      sidebarLogo: widget.sidebarLogo,
                      onSidebarFocusedIndexChanged:
                          handleSidebarFocusedIndexChanged,
                    ))
            : AppShellMobileLayout(
                selectedIndex: selectedIndex,
                onNavTap: handleNavTap,
                destinations: sidebarDestinations,
                pageBuilders: pageBuilders,
                scrollControllerForIndex:
                    _scrollToTopController.controllerForIndex,
              ),
      ),
    );

    if (!(launchRecovery?.isRetryable ?? false)) {
      return shellBody;
    }

    return Stack(
      children: [
        Positioned.fill(child: shellBody),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SafeArea(
            bottom: false,
            child: LaunchRecoveryBanner(
              message: launchRecovery!.message,
              onRetry: () {
                if (!context.mounted) return;
                ref.read(appLaunchOrchestratorProvider.notifier).reset();
                context.go(AppRouteNames.launch);
              },
            ),
          ),
        ),
      ],
    );
  }
}
