// lib/src/features/shell/presentation/navigation/shell_retention_policy.dart

import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';

/// Politique de rétention des onglets du Shell.
///
/// Choix validés :
/// 1) Policy basée sur ShellTab (pas indices)
/// 2) KeepAlive = Home + Search
/// 3) Library/Settings = reset complet (widget + providers)
/// 4) Home/Search construits dès le démarrage (pas lazy)
/// 5) Policy identique sur tous les devices
///
/// Note : Le reset "providers" est appliqué côté implémentation (ShellContentHost)
/// via un ProviderContainer dédié pour les onglets non keepAlive.
class ShellRetentionPolicy {
  const ShellRetentionPolicy._();

  /// Onglets qui doivent rester montés (conservent l'état widget).
  static const Set<ShellTab> keepAliveTabs = {
    ShellTab.home,
    ShellTab.search,
  };

  /// Onglets qui doivent être reconstruits à chaque entrée (reset complet).
  static const Set<ShellTab> ephemeralTabs = {
    ShellTab.library,
    ShellTab.settings,
  };

  /// Si true : build Home/Search dès le démarrage (au lieu de lazy-build).
  static const bool eagerBuildKeepAliveTabs = true;

  /// Helper: l'onglet doit-il rester monté ?
  static bool isKeepAlive(ShellTab tab) => keepAliveTabs.contains(tab);

  /// Helper: l'onglet est-il éphémère ?
  static bool isEphemeral(ShellTab tab) => ephemeralTabs.contains(tab);

  /// Helper: convertit keepAliveTabs en indices (utile pour ShellContentHost).
  static Set<int> keepAliveIndices() => keepAliveTabs
      .map((t) => ShellTab.values.indexOf(t))
      .toSet();
}