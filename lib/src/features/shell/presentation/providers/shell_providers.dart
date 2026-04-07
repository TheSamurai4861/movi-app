// lib/src/features/shell/presentation/providers/shell_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
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

class ShellTabFocusBinding {
  const ShellTabFocusBinding({
    required this.initialFocusNode,
    this.fallbackFocusNode,
  });

  final FocusNode initialFocusNode;
  final FocusNode? fallbackFocusNode;
}

class ShellFocusCoordinator {
  final Map<ShellTab, ShellTabFocusBinding> _tabBindings =
      <ShellTab, ShellTabFocusBinding>{};
  final Map<ShellTab, FocusNode> _lastContentNodes = <ShellTab, FocusNode>{};
  FocusNode? _sidebarNode;

  void attachSidebar(FocusNode node) {
    _sidebarNode = node;
  }

  void detachSidebar(FocusNode node) {
    if (identical(_sidebarNode, node)) {
      _sidebarNode = null;
    }
  }

  bool get isSidebarFocused => _sidebarNode?.hasFocus ?? false;

  void registerTabFocusBinding(ShellTab tab, ShellTabFocusBinding binding) {
    _tabBindings[tab] = binding;
  }

  void unregisterTabFocusBinding(ShellTab tab, FocusNode node) {
    final binding = _tabBindings[tab];
    if (binding == null) return;
    if (identical(binding.initialFocusNode, node) ||
        identical(binding.fallbackFocusNode, node)) {
      _tabBindings.remove(tab);
    }
    final rememberedNode = _lastContentNodes[tab];
    if (identical(rememberedNode, node)) {
      _lastContentNodes.remove(tab);
    }
  }

  void registerPreferredNode(ShellTab tab, FocusNode node) {
    registerTabFocusBinding(
      tab,
      ShellTabFocusBinding(
        initialFocusNode: node,
        fallbackFocusNode: node,
      ),
    );
  }

  void unregisterPreferredNode(ShellTab tab, FocusNode node) {
    unregisterTabFocusBinding(tab, node);
  }

  void rememberContentFocus(ShellTab tab, FocusNode node) {
    if (!_canRequestFocus(node)) return;
    _lastContentNodes[tab] = node;
  }

  bool focusSidebar() {
    final node = _sidebarNode;
    if (!_canRequestFocus(node)) return false;
    node!.requestFocus();
    return true;
  }

  bool focusTabEntry(ShellTab tab) {
    final rememberedNode = _lastContentNodes[tab];
    if (_canRequestFocus(rememberedNode)) {
      rememberedNode!.requestFocus();
      return true;
    }

    final binding = _tabBindings[tab];
    if (binding == null) return false;

    if (_canRequestFocus(binding.initialFocusNode)) {
      binding.initialFocusNode.requestFocus();
      return true;
    }

    if (_canRequestFocus(binding.fallbackFocusNode)) {
      binding.fallbackFocusNode!.requestFocus();
      return true;
    }

    return false;
  }

  bool _canRequestFocus(FocusNode? node) {
    return node != null && node.context != null && node.canRequestFocus;
  }
}

final shellFocusCoordinatorProvider = Provider<ShellFocusCoordinator>((ref) {
  return ShellFocusCoordinator();
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
