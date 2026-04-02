import 'package:flutter/material.dart';

/// Contrôleur partagé par le Shell pour gérer un "scroll-to-top" par onglet.
///
/// Le Shell associe un [ScrollController] à chaque index de destination.
/// Les pages sont enveloppées dans un [PrimaryScrollController] correspondant,
/// ce qui permet d'utiliser le même mécanisme sans modifier chaque page.
class ShellScrollToTopController {
  final Map<int, ScrollController> _controllers = <int, ScrollController>{};

  ScrollController controllerForIndex(int index) {
    return _controllers.putIfAbsent(index, () => ScrollController());
  }

  Future<void> scrollToTop(int index) async {
    final c = _controllers[index];
    if (c == null || !c.hasClients) return;
    if (c.offset <= 0) return;
    try {
      // Defensive behavior: avoid long-lived scroll activities that may keep
      // dispatching notifications while the target subtree is being disposed.
      c.jumpTo(0);
    } catch (_) {
      // Best-effort: the controller can become invalid during route/layout
      // transitions. In that case we silently ignore.
    }
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }
}
