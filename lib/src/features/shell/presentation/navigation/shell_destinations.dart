// lib/src/features/shell/presentation/navigation/shell_destinations.dart

import 'package:flutter/widgets.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/features/shell/presentation/widgets/navigation/sidebar_nav.dart';

/// Onglets du shell.
/// (Choix 1B) : on utilise un enum clair plutôt que des indices magiques.
enum ShellTab { home, search, library, settings }

/// Décrit une destination du shell.
/// (Choix 4A) : label/tooltip via fonction utilisant AppLocalizations.
class ShellDestination {
  const ShellDestination({
    required this.tab,
    required this.svgAssetPath,
    required this.tooltipBuilder,
  });

  final ShellTab tab;

  /// Chemin SVG (Choix 2B) : provient d'AppAssets.
  final String svgAssetPath;

  /// Tooltip localisé.
  final String Function(AppLocalizations l10n) tooltipBuilder;

  /// Convertit en modèle consommé par la sidebar.
  SidebarDestination toSidebarDestination(AppLocalizations l10n) {
    return SidebarDestination(
      assetPath: svgAssetPath,
      tooltip: tooltipBuilder(l10n),
    );
  }
}

/// Source de vérité des destinations (ordre = ordre affiché).
///
/// (Choix 5B) : config unique, mais extensible avec champs optionnels plus tard
/// (ex: icône mobile différente, badge, etc.) sans dupliquer la liste.
const List<ShellDestination> shellDestinations = [
  ShellDestination(
    tab: ShellTab.home,
    svgAssetPath: AppAssets.navHome,
    tooltipBuilder: _homeTooltip,
  ),
  ShellDestination(
    tab: ShellTab.search,
    svgAssetPath: AppAssets.navSearch,
    tooltipBuilder: _searchTooltip,
  ),
  ShellDestination(
    tab: ShellTab.library,
    svgAssetPath: AppAssets.navLibrary,
    tooltipBuilder: _libraryTooltip,
  ),
  ShellDestination(
    tab: ShellTab.settings,
    svgAssetPath: AppAssets.navSettings,
    tooltipBuilder: _settingsTooltip,
  ),
];

/// Helper : index <-> tab (pratique pour controller et retention policy).
int shellTabIndex(ShellTab tab) => ShellTab.values.indexOf(tab);

ShellTab shellTabFromIndex(int index) {
  if (index < 0 || index >= ShellTab.values.length) return ShellTab.home;
  return ShellTab.values[index];
}

/// Helper : build les destinations sidebar (tooltips déjà localisés).
List<SidebarDestination> buildSidebarDestinations(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return shellDestinations
      .map((d) => d.toSidebarDestination(l10n))
      .toList(growable: false);
}

/// Helpers tooltip (évite les closures const qui ne compilent pas toujours
/// selon les versions / lints).
String _homeTooltip(AppLocalizations l10n) => l10n.navHome;
String _searchTooltip(AppLocalizations l10n) => l10n.navSearch;
String _libraryTooltip(AppLocalizations l10n) => l10n.navLibrary;
String _settingsTooltip(AppLocalizations l10n) => l10n.navSettings;
