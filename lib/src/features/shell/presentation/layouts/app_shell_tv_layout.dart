// lib/src/features/shell/presentation/layouts/app_shell_tv_layout.dart

import 'package:flutter/material.dart';
import 'package:movi/src/features/shell/presentation/widgets/navigation/sidebar_nav.dart';
import 'package:movi/src/features/shell/presentation/widgets/regions/shell_content_host.dart';

/// Layout "TV" : très proche du desktop, mais :
/// - sidebar autofocus (télécommande / clavier direct)
/// - padding contenu un peu plus grand (48)
/// - hover désactivé (pas utile sur TV)
/// - SafeArea activé
class AppShellTvLayout extends StatelessWidget {
  const AppShellTvLayout({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
    required this.destinations,
    required this.pageBuilders,
    required this.keepAliveIndices,
    required this.sidebarFocusNode,
    this.scrollControllerForIndex,
    this.sidebarLogo,
  });

  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  final List<SidebarDestination> destinations;
  final List<WidgetBuilder> pageBuilders;
  final Set<int> keepAliveIndices;

  /// Optionnel : ScrollController primaire par onglet (pour scroll-to-top).
  final ScrollController Function(int index)? scrollControllerForIndex;

  final FocusNode sidebarFocusNode;
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
            destinations: destinations,
            logo: sidebarLogo,
            focusNode: sidebarFocusNode,
            autofocus: true,
            enableHover: false,
          ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 48),
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
          ),
        ],
      ),
    );
  }
}
