// lib/src/features/shell/presentation/providers/shell_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_retention_policy.dart';
import 'package:movi/src/features/shell/presentation/providers/shell_controller.dart';

/// Provider principal : expose le [ShellState].
///
/// Usage:
/// - final state = ref.watch(shellControllerProvider);
/// - final controller = ref.read(shellControllerProvider.notifier);
final shellControllerProvider =
    NotifierProvider<ShellController, ShellState>(ShellController.new);

/// Provider dérivé : onglet sélectionné.
///
/// Reco : utiliser ref.watch(...select(...)) dans les widgets lourds pour limiter
/// les rebuilds, mais ce provider peut être pratique dans des endroits simples.
final selectedTabProvider = Provider<ShellTab>((ref) {
  return ref.watch(shellControllerProvider.select((s) => s.selectedTab));
});

/// Provider dérivé : index sélectionné (utile pour SidebarNav et IndexedStack).
final selectedIndexProvider = Provider<int>((ref) {
  return ref.watch(shellControllerProvider.select((s) => s.selectedIndex));
});

/// Provider dérivé : indices keepAlive (Home + Search) selon la policy.
///
/// Utile pour [ShellContentHost.keepAliveIndices].
final keepAliveIndicesProvider = Provider<Set<int>>((ref) {
  return ShellRetentionPolicy.keepAliveIndices();
});

/// Actions "façade" (optionnelles) : évite de répéter `.notifier` partout.
///
/// Usage:
/// - shellSelectTab(ref, ShellTab.search);
/// - shellSelectIndex(ref, 2);
void shellSelectTab(WidgetRef ref, ShellTab tab) {
  ref.read(shellControllerProvider.notifier).selectTab(tab);
}

void shellSelectIndex(WidgetRef ref, int index) {
  ref.read(shellControllerProvider.notifier).selectIndex(index);
}

void shellNextTab(WidgetRef ref) {
  ref.read(shellControllerProvider.notifier).nextTab();
}

void shellPreviousTab(WidgetRef ref) {
  ref.read(shellControllerProvider.notifier).previousTab();
}
