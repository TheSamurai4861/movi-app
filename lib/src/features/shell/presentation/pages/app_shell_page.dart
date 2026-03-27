// lib/src/features/shell/presentation/pages/app_shell_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Shell
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_shortcuts.dart';
import 'package:movi/src/features/shell/presentation/providers/shell_providers.dart';
import 'package:movi/src/features/shell/presentation/layouts/app_shell_large_layout.dart';
import 'package:movi/src/features/shell/presentation/layouts/app_shell_mobile_layout.dart';
import 'package:movi/src/features/shell/presentation/layouts/app_shell_tv_layout.dart';

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

  @override
  void initState() {
    super.initState();
    ref.read(shellFocusCoordinatorProvider).attachSidebar(_sidebarFocusNode);
  }

  @override
  void dispose() {
    ref.read(shellFocusCoordinatorProvider).detachSidebar(_sidebarFocusNode);
    _sidebarFocusNode.dispose();
    super.dispose();
  }

  bool _isTvMode(BuildContext context) {
    // Override explicite (flag) en priorité (recommandé)
    final override = widget.forceTvMode;
    if (override != null) return override;

    // Fallback platform : heuristique simple (à affiner si tu ajoutes un vrai détecteur Android TV).
    // On évite toute string/texte brut ici.
    if (kIsWeb) return false;
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android) {
      // Heuristique : grands écrans Android => potentiellement TV.
      final shortestSide = MediaQuery.sizeOf(context).shortestSide;
      return shortestSide >= 600;
    }
    return false;
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

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    final keepAliveIndices = ref.watch(keepAliveIndicesProvider);
    final sidebarDestinations = buildSidebarDestinations(context);
    final pageBuilders = _buildPageBuilders();

    final isLarge = MediaQuery.sizeOf(context).width >= widget.largeBreakpoint;
    final isTv = isLarge && _isTvMode(context);
    final selectedTab = shellTabFromIndex(selectedIndex);
    final focusCoordinator = ref.read(shellFocusCoordinatorProvider);
    void handleNavTap(int index) {
      if (index == selectedIndex) {
        focusCoordinator.focusTabEntry(selectedTab);
        return;
      }
      shellSelectIndex(ref, index);
    }

    // Wrap global shortcuts (Ctrl+1..4 + Escape + Up/Down pour sidebar quand focus).
    // Pas de texte brut : pas de loadingLabel ici.
    return Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (_isTextInputFocused()) return KeyEventResult.ignored;

        if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
            _sidebarFocusNode.hasFocus) {
          final focused = focusCoordinator.focusTabEntry(selectedTab);
          return focused ? KeyEventResult.handled : KeyEventResult.ignored;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
            !_sidebarFocusNode.hasFocus) {
          final focusedNode = FocusManager.instance.primaryFocus;
          if (focusedNode == null) return KeyEventResult.ignored;
          final moved = focusedNode.focusInDirection(TraversalDirection.left);
          if (moved) return KeyEventResult.handled;
          focusCoordinator.rememberContentFocus(selectedTab, focusedNode);
          _sidebarFocusNode.requestFocus();
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
                      sidebarLogo: widget.sidebarLogo,
                    )
                  : AppShellLargeLayout(
                      selectedIndex: selectedIndex,
                      onNavTap: handleNavTap,
                      destinations: sidebarDestinations,
                      pageBuilders: pageBuilders,
                      keepAliveIndices: keepAliveIndices,
                      sidebarFocusNode: _sidebarFocusNode,
                      sidebarLogo: widget.sidebarLogo,
                    ))
            : AppShellMobileLayout(
                selectedIndex: selectedIndex,
                onNavTap: (i) => shellSelectIndex(ref, i),
                destinations: sidebarDestinations,
                pageBuilders: pageBuilders,
              ),
      ),
    );
  }
}
