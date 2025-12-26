// lib/src/features/shell/presentation/layouts/app_shell_large_layout.dart

import 'package:flutter/material.dart';
import 'package:movi/src/features/shell/presentation/widgets/navigation/sidebar_nav.dart';
import 'package:movi/src/features/shell/presentation/widgets/regions/shell_content_host.dart';

/// Layout "Large" (Desktop) : sidebar verticale à gauche + divider + contenu.
///
/// Choix validés :
/// - Structure : Row(sidebar + divider + Expanded(content))
/// - Fond contenu : Theme.scaffoldBackgroundColor (par défaut)
/// - Padding global contenu : 32px à droite du divider
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
    this.sidebarLogo,
  });

  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  /// Destinations (SVG + tooltip localisé) construites via buildSidebarDestinations(context).
  final List<SidebarDestination> destinations;

  /// Pages du shell (Home/Search/Library/Settings) sous forme de builders.
  final List<WidgetBuilder> pageBuilders;

  /// Indices keepAlive (Home + Search).
  final Set<int> keepAliveIndices;

  /// Focus node du scope sidebar (utilisé aussi par ShellShortcuts).
  final FocusNode sidebarFocusNode;

  /// Logo optionnel en haut de la sidebar.
  final Widget? sidebarLogo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SidebarNav(
          selectedIndex: selectedIndex,
          onDestinationSelected: onNavTap,
          destinations: destinations,
          logo: sidebarLogo,
          focusNode: sidebarFocusNode,
          autofocus: false,
        ),
        Expanded(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 32),
              child: ShellContentHost(
                selectedIndex: selectedIndex,
                pageBuilders: pageBuilders,
                keepAliveIndices: keepAliveIndices,
                showEphemeralSwitchLoading: true,
                loadingLabel: null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
