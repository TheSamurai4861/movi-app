// lib/src/features/shell/presentation/providers/shell_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';

/// État minimal du Shell.
/// - Par défaut : Home (pas de persistance au redémarrage)
/// - Extensible si tu veux ajouter d'autres infos plus tard (ex: isTvMode, etc.)
class ShellState {
  const ShellState({
    required this.selectedTab,
  });

  final ShellTab selectedTab;

  int get selectedIndex => shellTabIndex(selectedTab);

  ShellState copyWith({
    ShellTab? selectedTab,
  }) {
    return ShellState(
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

/// Controller Riverpod (Notifier) pour piloter la navigation du Shell.
///
/// Bonnes pratiques appliquées selon tes choix :
/// - Notifier (Riverpod "moderne")
/// - Démarre toujours sur Home (pas de persistance)
/// - Ignore une demande invalide
/// - Ne rebuild pas si on re-sélectionne le même onglet
/// - Expose des méthodes utiles (selectTab, selectIndex, next/previous)
class ShellController extends Notifier<ShellState> {
  @override
  ShellState build() {
    return const ShellState(selectedTab: ShellTab.home);
  }

  /// Sélectionne un onglet (no-op si déjà sélectionné).
  void selectTab(ShellTab tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab);
  }

  /// Sélectionne un onglet via son index (no-op si index invalide ou inchangé).
  ///
  /// Index invalide => on ignore.
  void selectIndex(int index) {
    final isValid = index >= 0 && index < ShellTab.values.length;
    if (!isValid) return;

    final tab = shellTabFromIndex(index);
    selectTab(tab);
  }

  /// Va à l’onglet suivant (wrap).
  void nextTab() => _step(1);

  /// Va à l’onglet précédent (wrap).
  void previousTab() => _step(-1);

  void _step(int delta) {
    final tabs = ShellTab.values;
    final len = tabs.length;

    final currentIndex = tabs.indexOf(state.selectedTab);
    if (currentIndex < 0) return;

    var nextIndex = currentIndex + delta;
    nextIndex %= len;
    if (nextIndex < 0) nextIndex += len;

    selectTab(tabs[nextIndex]);
  }
}
