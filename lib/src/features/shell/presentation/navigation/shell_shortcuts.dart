// lib/src/features/shell/presentation/navigation/shell_shortcuts.dart

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';

/// Intent: sélectionner un onglet précis.
class ShellSelectTabIntent extends Intent {
  const ShellSelectTabIntent(this.tab);
  final ShellTab tab;
}

/// Intent: monter/descendre d’un item de navigation (sidebar verticale).
class ShellStepNavItemIntent extends Intent {
  const ShellStepNavItemIntent(this.delta);
  final int delta; // -1 = up, +1 = down
}

/// Wrap Shortcuts + Actions pour le Shell.
///
/// Choix validés par toi :
/// - PC: oui
/// - Raccourcis: Ctrl + 1/2/3/4 uniquement
/// - Pas de chiffres seuls
/// - Désactivés quand l’utilisateur est en train d’écrire
/// - TV/Clavier: flèches haut/bas pour passer d’un item de nav à l’autre
/// - API: utilise ShellTab plutôt que index
/// - Escape => Home
///
/// IMPORTANT :
/// Les flèches haut/bas ne doivent pas casser le contenu (listes, scroll, etc.).
/// Donc elles ne s’activent que si [navScopeFocusNode] (si fourni) est focus/hasFocus.
class ShellShortcuts extends StatelessWidget {
  const ShellShortcuts({
    super.key,
    required this.selectedTab,
    required this.onSelectTab,
    required this.child,
    this.navScopeFocusNode,
  });

  /// Onglet actuellement sélectionné.
  final ShellTab selectedTab;

  /// Callback quand on sélectionne un onglet.
  final ValueChanged<ShellTab> onSelectTab;

  /// UI à wrapper.
  final Widget child;

  /// Focus node du “scope sidebar” (recommandé).
  ///
  /// Si tu passes le FocusNode qui entoure la sidebar, alors :
  /// - ArrowUp/ArrowDown ne marchent que quand le focus est sur la sidebar,
  ///   ce qui évite les conflits avec le contenu.
  final FocusNode? navScopeFocusNode;

  @override
  Widget build(BuildContext context) {
    final shortcuts = <ShortcutActivator, Intent>{
      // Ctrl + 1..4 (digits)
      const SingleActivator(LogicalKeyboardKey.digit1, control: true):
          const ShellSelectTabIntent(ShellTab.home),
      const SingleActivator(LogicalKeyboardKey.digit2, control: true):
          const ShellSelectTabIntent(ShellTab.search),
      const SingleActivator(LogicalKeyboardKey.digit3, control: true):
          const ShellSelectTabIntent(ShellTab.library),
      const SingleActivator(LogicalKeyboardKey.digit4, control: true):
          const ShellSelectTabIntent(ShellTab.settings),

      // Ctrl + numpad 1..4
      const SingleActivator(LogicalKeyboardKey.numpad1, control: true):
          const ShellSelectTabIntent(ShellTab.home),
      const SingleActivator(LogicalKeyboardKey.numpad2, control: true):
          const ShellSelectTabIntent(ShellTab.search),
      const SingleActivator(LogicalKeyboardKey.numpad3, control: true):
          const ShellSelectTabIntent(ShellTab.library),
      const SingleActivator(LogicalKeyboardKey.numpad4, control: true):
          const ShellSelectTabIntent(ShellTab.settings),

      // Escape => Home
      const SingleActivator(LogicalKeyboardKey.escape):
          const ShellSelectTabIntent(ShellTab.home),

      // TV/Clavier : flèches haut/bas => item précédent/suivant (sidebar)
      const SingleActivator(LogicalKeyboardKey.arrowUp):
          const ShellStepNavItemIntent(-1),
      const SingleActivator(LogicalKeyboardKey.arrowDown):
          const ShellStepNavItemIntent(1),
    };

    final actions = <Type, Action<Intent>>{
      ShellSelectTabIntent: CallbackAction<ShellSelectTabIntent>(
        onInvoke: (intent) {
          if (_isTextInputFocused()) return null;
          onSelectTab(intent.tab);
          return null;
        },
      ),
      ShellStepNavItemIntent: CallbackAction<ShellStepNavItemIntent>(
        onInvoke: (intent) {
          if (_isTextInputFocused()) return null;

          // Les flèches servent à naviguer dans la sidebar,
          // donc on n’active l’action que si le focus est sur la sidebar (si fourni).
          if (!_isNavScopeFocused(navScopeFocusNode)) return null;

          final next = _stepTab(selectedTab, intent.delta);
          onSelectTab(next);
          return null;
        },
      ),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: child,
      ),
    );
  }

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) return false;

    // Compatible avec plus de versions Flutter :
    // Si le focus actuel est dans un EditableText (TextField, etc.), on coupe les shortcuts.
    return ctx.findAncestorStateOfType<EditableTextState>() != null;
  }

  bool _isNavScopeFocused(FocusNode? navScopeFocusNode) {
    if (navScopeFocusNode == null) {
      // Si aucun scope n’est fourni, on considère que c’est “toujours ok”.
      return true;
    }
    return navScopeFocusNode.hasFocus;
  }

  ShellTab _stepTab(ShellTab current, int delta) {
    final tabs = ShellTab.values;
    final len = tabs.length;

    final currentIndex = tabs.indexOf(current);
    if (currentIndex < 0) return ShellTab.home;

    var nextIndex = currentIndex + delta;
    nextIndex %= len;
    if (nextIndex < 0) nextIndex += len;

    return tabs[nextIndex];
  }
}
