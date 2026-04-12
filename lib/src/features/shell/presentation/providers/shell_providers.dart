// lib/src/features/shell/presentation/providers/shell_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:movi/src/core/focus/application/focus_orchestrator.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_restore_strategy.dart';
import 'package:movi/src/core/focus/presentation/focus_orchestrator_provider.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_retention_policy.dart';
import 'package:movi/src/features/shell/presentation/providers/shell_controller.dart';

/// Provider principal : expose le [ShellState].
///
/// Usage:
/// - final state = ref.watch(shellControllerProvider);
/// - final controller = ref.read(shellControllerProvider.notifier);
final shellControllerProvider = NotifierProvider<ShellController, ShellState>(
  ShellController.new,
);

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

class ShellFocusCoordinator {
  ShellFocusCoordinator({required FocusOrchestrator focusOrchestrator})
    : _focusOrchestrator = focusOrchestrator;

  final FocusOrchestrator _focusOrchestrator;
  FocusNode? _sidebarNode;
  int? _sidebarFocusedIndex;

  void attachSidebar(FocusNode node) {
    _sidebarNode = node;
    _focusOrchestrator.registerRegion(
      AppFocusRegionId.shellSidebar,
      FocusRegionBinding(
        resolvePrimaryEntryNode: () => node,
        resolveFallbackEntryNode: () => node,
        restoreStrategy: FocusRestoreStrategy.primaryOnly,
      ),
    );
  }

  void detachSidebar(FocusNode node) {
    if (identical(_sidebarNode, node)) {
      _sidebarNode = null;
      _sidebarFocusedIndex = null;
      _focusOrchestrator.unregisterRegion(AppFocusRegionId.shellSidebar);
    }
  }

  bool get isSidebarFocused => _sidebarNode?.hasFocus ?? false;
  int? get sidebarFocusedIndex => _sidebarFocusedIndex;

  void setSidebarFocusedIndex(int index) {
    _sidebarFocusedIndex = index;
  }

  bool focusSidebar() {
    return _focusOrchestrator.enterRegion(
      AppFocusRegionId.shellSidebar,
      restoreLastFocused: false,
    );
  }

  bool focusTabEntry(ShellTab tab) {
    return _focusOrchestrator.enterRegion(_regionForTab(tab));
  }

  bool focusTabPrimaryEntry(ShellTab tab) {
    return _focusOrchestrator.enterRegion(
      _regionForTab(tab),
      restoreLastFocused: false,
    );
  }

  bool resolveTabExit(ShellTab tab, DirectionalEdge edge) {
    return _focusOrchestrator.resolveExit(_regionForTab(tab), edge);
  }

  AppFocusRegionId _regionForTab(ShellTab tab) {
    return switch (tab) {
      ShellTab.home => AppFocusRegionId.homePrimary,
      ShellTab.search => AppFocusRegionId.searchInput,
      ShellTab.library => AppFocusRegionId.libraryPrimary,
      ShellTab.settings => AppFocusRegionId.settingsPrimary,
    };
  }
}

final shellFocusCoordinatorProvider = Provider<ShellFocusCoordinator>((ref) {
  return ShellFocusCoordinator(
    focusOrchestrator: ref.watch(focusOrchestratorProvider),
  );
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
