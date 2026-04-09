// lib/src/features/shell/presentation/layouts/app_shell_large_layout.dart

import 'package:flutter/material.dart';
import 'package:movi/src/features/shell/presentation/widgets/navigation/sidebar_nav.dart';
import 'package:movi/src/features/shell/presentation/widgets/regions/shell_content_host.dart';

/// Layout "Large" (Desktop) : sidebar verticale à gauche + divider + contenu.
///
/// Choix validés :
/// - Structure : Row(sidebar + divider + Expanded(content))
/// - Fond contenu : Theme.scaffoldBackgroundColor (par défaut)
/// - Pas de padding global à gauche du contenu pour éviter un gutter visible
///   entre la sidebar et le hero Home
/// - FocusNode : juste passé à la sidebar (pas d'autofocus forcé)
/// - ContentHost : keepAliveIndices + pageBuilders + selectedIndex, loadingLabel null
/// - SafeArea sur la zone contenu : oui
class AppShellLargeLayout extends StatelessWidget {
  const AppShellLargeLayout({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
    required this.destinations,
    required this.pageBuilders,
    required this.keepAliveIndices,
    required this.sidebarFocusNode,
    this.onSidebarFocusedIndexChanged,
    this.scrollControllerForIndex,
    this.sidebarLogo,
  });

  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  /// Destinations (SVG + tooltip localisé) construites via buildSidebarDestinations(context).
  final List<SidebarDestination> destinations;

  /// Pages du shell (Home/Search/Library/Settings) sous forme de builders.
  final List<WidgetBuilder> pageBuilders;

  /// Optionnel : ScrollController primaire par onglet (pour scroll-to-top).
  final ScrollController Function(int index)? scrollControllerForIndex;

  /// Indices keepAlive (Home + Search).
  final Set<int> keepAliveIndices;

  /// Focus node du scope sidebar (utilisé aussi par ShellShortcuts).
  final FocusNode sidebarFocusNode;
  final ValueChanged<int>? onSidebarFocusedIndexChanged;

  /// Logo optionnel en haut de la sidebar.
  final Widget? sidebarLogo;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return ColoredBox(
      color: surfaceColor,
      child: Row(
        children: [
          SidebarNav(
            selectedIndex: selectedIndex,
            onDestinationSelected: onNavTap,
            onFocusedIndexChanged: onSidebarFocusedIndexChanged,
            destinations: destinations,
            logo: sidebarLogo,
            focusNode: sidebarFocusNode,
            autofocus: false,
          ),
          Expanded(
            child: SafeArea(
              child: ShellContentHost(
                selectedIndex: selectedIndex,
                pageBuilders: pageBuilders,
                scrollControllerForIndex: scrollControllerForIndex,
                keepAliveIndices: keepAliveIndices,
                showEphemeralSwitchLoading: true,
                loadingLabel: null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
